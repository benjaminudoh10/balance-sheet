import 'package:balance_sheet/database/db.dart';
import 'package:balance_sheet/database/operations.dart' as db_ops;
import 'package:balance_sheet/enums.dart';
import 'package:balance_sheet/models/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/database_test_setup.dart';

void main() {
  setUpAll(() {
    initializeSqfliteFfiForTests();
  });

  setUp(() async {
    await resetAppDatabaseFile();
  });

  group('trash operations', () {
    test('moveTransactionToTrash sets deletedAt and filters from active list',
        () async {
      final int id = await db_ops.addTransaction(Transaction(
        description: 'Trash me',
        type: TransactionType.expenditure,
        amount: 100,
        date: DateTime.now(),
        category: 'misc',
        contactId: 0,
      ));

      final int start = DateTime.now()
          .subtract(const Duration(days: 1))
          .millisecondsSinceEpoch;
      final int end =
          DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch;

      List<Transaction> active = await db_ops.getAllTransactions(start, end);
      expect(active.any((t) => t.id == id), isTrue);

      await db_ops.moveTransactionToTrash(id);

      active = await db_ops.getAllTransactions(start, end);
      expect(active.any((t) => t.id == id), isFalse);

      List<Transaction> trashed = await db_ops.getTrashedTransactions();
      expect(trashed.any((t) => t.id == id), isTrue);
      expect(trashed.firstWhere((t) => t.id == id).deletedAt, isNotNull);
    });

    test('restoreTransactionFromTrash clears deletedAt', () async {
      final int id = await db_ops.addTransaction(Transaction(
        description: 'Restore me',
        type: TransactionType.income,
        amount: 500,
        date: DateTime.now(),
        category: 'savings',
        contactId: 0,
      ));

      await db_ops.moveTransactionToTrash(id);
      expect((await db_ops.getTrashedTransactions()).length, 1);

      await db_ops.restoreTransactionFromTrash(id);
      expect((await db_ops.getTrashedTransactions()), isEmpty);

      final int start = DateTime.now()
          .subtract(const Duration(days: 1))
          .millisecondsSinceEpoch;
      final int end =
          DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch;
      List<Transaction> active = await db_ops.getAllTransactions(start, end);
      expect(active.any((t) => t.id == id), isTrue);
    });

    test('permanentlyDeleteTransaction removes row entirely', () async {
      final int id = await db_ops.addTransaction(Transaction(
        description: 'Gone forever',
        type: TransactionType.expenditure,
        amount: 1,
        date: DateTime.now(),
        category: 'misc',
        contactId: 0,
      ));

      await db_ops.moveTransactionToTrash(id);
      expect((await db_ops.getTrashedTransactions()).length, 1);

      await db_ops.permanentlyDeleteTransaction(id);
      expect((await db_ops.getTrashedTransactions()), isEmpty);

      final int start = DateTime.now()
          .subtract(const Duration(days: 1))
          .millisecondsSinceEpoch;
      final int end =
          DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch;
      expect((await db_ops.getAllTransactions(start, end)), isEmpty);
    });

    test('cleanupTrash removes items older than threshold', () async {
      final DateTime now = DateTime.now();

      // Item 1: Deleted 40 days ago
      final int id1 = await db_ops.addTransaction(Transaction(
        description: 'old',
        type: TransactionType.expenditure,
        amount: 10,
        date: now.subtract(const Duration(days: 45)),
        category: 'misc',
        contactId: 0,
      ));
      // Manually set deletedAt for testing cleanup
      final dbClient = await AppDb().db;
      await dbClient.update(
          'transactions',
          {
            'deletedAt':
                now.subtract(const Duration(days: 40)).millisecondsSinceEpoch
          },
          where: 'id = ?',
          whereArgs: [id1]);

      // Item 2: Deleted 5 days ago
      final int id2 = await db_ops.addTransaction(Transaction(
        description: 'recent',
        type: TransactionType.expenditure,
        amount: 20,
        date: now.subtract(const Duration(days: 10)),
        category: 'misc',
        contactId: 0,
      ));
      await dbClient.update(
          'transactions',
          {
            'deletedAt':
                now.subtract(const Duration(days: 5)).millisecondsSinceEpoch
          },
          where: 'id = ?',
          whereArgs: [id2]);

      // Cleanup items older than 30 days
      final int threshold =
          now.subtract(const Duration(days: 30)).millisecondsSinceEpoch;
      await db_ops.cleanupTrash(threshold);

      List<Transaction> trashed = await db_ops.getTrashedTransactions();
      expect(trashed.length, 1);
      expect(trashed.first.id, id2);
    });

    test('emptyTrash clears all trashed items', () async {
      await db_ops.addTransaction(Transaction(
        description: 'a',
        type: TransactionType.income,
        amount: 1,
        date: DateTime.now(),
        category: 'misc',
        contactId: 0,
      ));
      await db_ops.addTransaction(Transaction(
        description: 'b',
        type: TransactionType.income,
        amount: 1,
        date: DateTime.now(),
        category: 'misc',
        contactId: 0,
      ));

      final List<Transaction> all = await db_ops.getAllTransactions(
          0, DateTime.now().millisecondsSinceEpoch + 1000);
      for (var t in all) {
        await db_ops.moveTransactionToTrash(t.id);
      }

      expect((await db_ops.getTrashedTransactions()).length, 2);
      await db_ops.emptyTrash();
      expect((await db_ops.getTrashedTransactions()), isEmpty);
    });
  });

  group('balances with trash', () {
    test('getBalances and getTodayBalances exclude trashed items', () async {
      await db_ops.addTransaction(Transaction(
        description: 'active',
        type: TransactionType.income,
        amount: 1000,
        date: DateTime.now(),
        category: 'misc',
        contactId: 0,
      ));
      final int tid = await db_ops.addTransaction(Transaction(
        description: 'trashed',
        type: TransactionType.income,
        amount: 500,
        date: DateTime.now(),
        category: 'misc',
        contactId: 0,
      ));

      expect(await db_ops.getBalances(), 1500);

      await db_ops.moveTransactionToTrash(tid);

      expect(await db_ops.getBalances(), 1000);
      final Map<String, int> today = await db_ops.getTodayBalances();
      expect(today['income'], 1000);
    });
  });
}
