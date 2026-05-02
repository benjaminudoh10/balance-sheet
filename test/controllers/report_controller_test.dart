import 'package:balance_sheet/controllers/reportController.dart';
import 'package:balance_sheet/database/operations.dart' as db_ops;
import 'package:balance_sheet/enums.dart';
import 'package:balance_sheet/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../helpers/database_test_setup.dart';

void main() {
  group('ReportController.splitTransactionsIntoDays', () {
    test('buckets transactions by calendar day', () {
      final ReportController rc = ReportController();
      final int day1 = DateTime(2026, 4, 10).millisecondsSinceEpoch;
      final int day2 = DateTime(2026, 4, 11).millisecondsSinceEpoch;
      rc.timeFrames = [day1, day2 + 86400000 - 1];

      final List<Transaction> txns = [
        Transaction(
          description: 'a',
          type: TransactionType.expenditure,
          amount: 1,
          date: DateTime(2026, 4, 10, 8),
          category: 'misc',
          contactId: 0,
        ),
        Transaction(
          description: 'b',
          type: TransactionType.income,
          amount: 2,
          date: DateTime(2026, 4, 11, 20),
          category: 'salary',
          contactId: 0,
        ),
      ];

      final Map<int, List<Transaction>> split = rc.splitTransactionsIntoDays(txns);
      expect(split[day1]?.length, 1);
      expect(split[day2]?.length, 1);
    });

    test('omits days with no transactions (no empty buckets)', () {
      // Previous implementation walked every day in the range and stored an
      // empty list per day, which dominated render cost for multi-year ranges.
      final ReportController rc = ReportController();
      final int rangeStart = DateTime(2021, 1, 1).millisecondsSinceEpoch;
      final int rangeEnd =
          DateTime(2026, 12, 31, 23, 59, 59, 999).millisecondsSinceEpoch;
      rc.timeFrames = [rangeStart, rangeEnd];

      final List<Transaction> txns = [
        Transaction(
          description: 'lone',
          type: TransactionType.expenditure,
          amount: 1,
          date: DateTime(2024, 6, 15, 12),
          category: 'misc',
          contactId: 0,
        ),
      ];

      final Map<int, List<Transaction>> split =
          rc.splitTransactionsIntoDays(txns);
      expect(split.length, 1);
      expect(split.keys.first,
          DateTime(2024, 6, 15).millisecondsSinceEpoch);
    });

    test('groups several transactions on the same day together', () {
      final ReportController rc = ReportController();
      final List<Transaction> txns = [
        Transaction(
          description: 'morning',
          type: TransactionType.expenditure,
          amount: 1,
          date: DateTime(2025, 7, 3, 8),
          category: 'food',
          contactId: 0,
        ),
        Transaction(
          description: 'evening',
          type: TransactionType.expenditure,
          amount: 2,
          date: DateTime(2025, 7, 3, 20),
          category: 'food',
          contactId: 0,
        ),
      ];
      final Map<int, List<Transaction>> split =
          rc.splitTransactionsIntoDays(txns);
      final int dayKey = DateTime(2025, 7, 3).millisecondsSinceEpoch;
      expect(split[dayKey]?.length, 2);
    });
  });

  group('ReportController pagination', () {
    setUpAll(() {
      initializeSqfliteFfiForTests();
    });

    setUp(() async {
      await resetAppDatabaseFile();
      Get.testMode = true;
      Get.reset();
    });

    tearDown(() {
      Get.reset();
    });

    test('getTransactions loads only one page; loadNextPage appends the rest',
        () async {
      final int rangeStart = DateTime(2025, 1, 1).millisecondsSinceEpoch;
      final int rangeEnd =
          DateTime(2025, 12, 31, 23, 59, 59, 999).millisecondsSinceEpoch;

      // Insert a full page + a partial second page.
      final int total = ReportController.pageSize + 7;
      for (int i = 0; i < total; i++) {
        await db_ops.addTransaction(Transaction(
          description: 'row $i',
          type: TransactionType.expenditure,
          amount: 10 + i,
          date: DateTime(2025, 1, 1).add(Duration(days: i)),
          category: 'misc',
          contactId: 0,
        ));
      }

      final ReportController rc = ReportController();
      rc.type.value = ReportType.dateRange;
      rc.dateTimeRange = DateTimeRange(
        start: DateTime.fromMillisecondsSinceEpoch(rangeStart),
        end: DateTime.fromMillisecondsSinceEpoch(rangeEnd),
      );
      rc.timeFrames = rc.getTimeFrame();

      await rc.getTransactions();
      expect(rc.transactions.length, ReportController.pageSize);
      expect(rc.hasMore.value, isTrue);
      expect(rc.isLoadingInitial.value, isFalse);

      await rc.loadNextPage();
      expect(rc.transactions.length, total);
      expect(rc.hasMore.value, isFalse);
      expect(rc.isLoadingMore.value, isFalse);

      // Calling load again past the end is a no-op.
      await rc.loadNextPage();
      expect(rc.transactions.length, total);
    });

    test('hasMore stays false when the range has fewer than one page of rows',
        () async {
      final int rangeStart = DateTime(2025, 1, 1).millisecondsSinceEpoch;
      final int rangeEnd =
          DateTime(2025, 12, 31, 23, 59, 59, 999).millisecondsSinceEpoch;

      for (int i = 0; i < 3; i++) {
        await db_ops.addTransaction(Transaction(
          description: 'row $i',
          type: TransactionType.income,
          amount: 1,
          date: DateTime(2025, 2, 1 + i),
          category: 'salary',
          contactId: 0,
        ));
      }

      final ReportController rc = ReportController();
      rc.type.value = ReportType.dateRange;
      rc.dateTimeRange = DateTimeRange(
        start: DateTime.fromMillisecondsSinceEpoch(rangeStart),
        end: DateTime.fromMillisecondsSinceEpoch(rangeEnd),
      );
      rc.timeFrames = rc.getTimeFrame();

      await rc.getTransactions();
      expect(rc.transactions.length, 3);
      expect(rc.hasMore.value, isFalse);
    });

    test('fetchAllTransactionsForCurrentRange ignores pagination state',
        () async {
      final int rangeStart = DateTime(2025, 1, 1).millisecondsSinceEpoch;
      final int rangeEnd =
          DateTime(2025, 12, 31, 23, 59, 59, 999).millisecondsSinceEpoch;

      final int total = ReportController.pageSize + 10;
      for (int i = 0; i < total; i++) {
        await db_ops.addTransaction(Transaction(
          description: 'row $i',
          type: TransactionType.expenditure,
          amount: 1,
          date: DateTime(2025, 3, 1).add(Duration(days: i)),
          category: 'misc',
          contactId: 0,
        ));
      }

      final ReportController rc = ReportController();
      rc.type.value = ReportType.dateRange;
      rc.dateTimeRange = DateTimeRange(
        start: DateTime.fromMillisecondsSinceEpoch(rangeStart),
        end: DateTime.fromMillisecondsSinceEpoch(rangeEnd),
      );
      rc.timeFrames = rc.getTimeFrame();

      await rc.getTransactions();
      expect(rc.transactions.length, ReportController.pageSize);

      final List<Transaction> all =
          await rc.fetchAllTransactionsForCurrentRange();
      expect(all.length, total);
    });
  });

  group('ReportController.getTimeFrame', () {
    test('today has start before end same calendar day', () {
      final ReportController rc = ReportController();
      rc.type.value = ReportType.today;
      final List<int> tf = rc.getTimeFrame();
      expect(tf.length, 2);
      expect(tf[0], lessThan(tf[1]));
      final DateTime start = DateTime.fromMillisecondsSinceEpoch(tf[0]);
      final DateTime end = DateTime.fromMillisecondsSinceEpoch(tf[1]);
      expect(start.day, end.day);
    });

    test('month spans full month', () {
      final ReportController rc = ReportController();
      rc.type.value = ReportType.month;
      final List<int> tf = rc.getTimeFrame();
      expect(tf[0], lessThan(tf[1]));
    });

    test('this week has valid range', () {
      final ReportController rc = ReportController();
      rc.type.value = ReportType.thisWeek;
      final List<int> tf = rc.getTimeFrame();
      expect(tf.length, 2);
      expect(tf[0], lessThanOrEqualTo(tf[1]));
    });

    test('singleDay uses singleDate boundaries', () {
      final ReportController rc = ReportController();
      rc.type.value = ReportType.singleDay;
      rc.singleDate = DateTime(2026, 2, 14);
      final List<int> tf = rc.getTimeFrame();
      final DateTime start = DateTime.fromMillisecondsSinceEpoch(tf[0]);
      final DateTime end = DateTime.fromMillisecondsSinceEpoch(tf[1]);
      expect(start.month, 2);
      expect(start.day, 14);
      expect(end.day, 14);
      expect(end.hour, 23);
    });

    test('dateRange uses range boundaries', () {
      final ReportController rc = ReportController();
      rc.type.value = ReportType.dateRange;
      rc.dateTimeRange = DateTimeRange(
        start: DateTime(2026, 1, 5),
        end: DateTime(2026, 1, 7),
      );
      final List<int> tf = rc.getTimeFrame();
      final DateTime start = DateTime.fromMillisecondsSinceEpoch(tf[0]);
      final DateTime end = DateTime.fromMillisecondsSinceEpoch(tf[1]);
      expect(start.day, 5);
      expect(end.day, 7);
      expect(end.hour, 23);
    });

    test('lastMonth spans previous month', () {
      final ReportController rc = ReportController();
      rc.type.value = ReportType.lastMonth;
      final List<int> tf = rc.getTimeFrame();
      expect(tf[0], lessThan(tf[1]));
      final DateTime start = DateTime.fromMillisecondsSinceEpoch(tf[0]);
      final DateTime end = DateTime.fromMillisecondsSinceEpoch(tf[1]);
      expect(end.month, start.month);
    });
  });
}
