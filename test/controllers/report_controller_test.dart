import 'package:balance_sheet/controllers/reportController.dart';
import 'package:balance_sheet/enums.dart';
import 'package:balance_sheet/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
