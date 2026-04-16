import 'package:balance_sheet/database/operations.dart' as db_ops;
import 'package:balance_sheet/enums.dart';
import 'package:balance_sheet/models/contact.dart';
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

  group('transactions', () {
    test('addTransaction assigns id and getAllTransactions returns row', () async {
      final Transaction t = Transaction(
        description: 'Lunch',
        type: TransactionType.expenditure,
        amount: 2500,
        date: DateTime(2025, 3, 10, 14, 30),
        category: 'food',
        contactId: 0,
      );
      final int id = await db_ops.addTransaction(t);
      expect(id, greaterThan(0));

      final int start = DateTime(2025, 3, 1).millisecondsSinceEpoch;
      final int end = DateTime(2025, 3, 31, 23, 59, 59, 999).millisecondsSinceEpoch;
      final List<Transaction> list = await db_ops.getAllTransactions(start, end);
      expect(list.length, 1);
      expect(list.first.id, id);
      expect(list.first.category, 'food');
      expect(list.first.type, TransactionType.expenditure);
    });

    test('getBalances is income minus expenses', () async {
      await db_ops.addTransaction(Transaction(
        description: 'in',
        type: TransactionType.income,
        amount: 10000,
        date: DateTime(2025, 1, 1),
        category: 'salary',
        contactId: 0,
      ));
      await db_ops.addTransaction(Transaction(
        description: 'out',
        type: TransactionType.expenditure,
        amount: 3500,
        date: DateTime(2025, 1, 2),
        category: 'food',
        contactId: 0,
      ));
      expect(await db_ops.getBalances(), 6500);
    });

    test('getTodayBalances only counts current local day', () async {
      final DateTime now = DateTime.now();
      final DateTime todayNoon = DateTime(now.year, now.month, now.day, 12);
      final DateTime y = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
      final DateTime yesterday = DateTime(y.year, y.month, y.day, 12);

      await db_ops.addTransaction(Transaction(
        description: 'today exp',
        type: TransactionType.expenditure,
        amount: 100,
        date: todayNoon,
        category: 'misc',
        contactId: 0,
      ));
      await db_ops.addTransaction(Transaction(
        description: 'old',
        type: TransactionType.expenditure,
        amount: 9999,
        date: yesterday,
        category: 'misc',
        contactId: 0,
      ));

      final Map<String, int> m = await db_ops.getTodayBalances();
      expect(m['expenses'], 100);
    });

    test('getAllTransactions filters by category when not Category', () async {
      final DateTime ts = DateTime(2025, 7, 1);
      await db_ops.addTransaction(Transaction(
        description: 'a',
        type: TransactionType.expenditure,
        amount: 1,
        date: ts,
        category: 'food',
        contactId: 0,
      ));
      await db_ops.addTransaction(Transaction(
        description: 'b',
        type: TransactionType.expenditure,
        amount: 2,
        date: ts,
        category: 'rent',
        contactId: 0,
      ));
      final int start = DateTime(2025, 7, 1).millisecondsSinceEpoch;
      final int end = DateTime(2025, 7, 31).millisecondsSinceEpoch;
      final List<Transaction> food = await db_ops.getAllTransactions(start, end, category: 'food');
      expect(food.length, 1);
      expect(food.first.category, 'food');
    });

    test('getAllTransactions filters by contactId when positive', () async {
      final int cid = await db_ops.addContact(Contact(name: 'Vendor'));
      final DateTime ts = DateTime(2025, 8, 1);
      await db_ops.addTransaction(Transaction(
        description: 'with contact',
        type: TransactionType.income,
        amount: 50,
        date: ts,
        category: 'salary',
        contactId: cid,
      ));
      await db_ops.addTransaction(Transaction(
        description: 'no contact',
        type: TransactionType.income,
        amount: 60,
        date: ts,
        category: 'salary',
        contactId: 0,
      ));
      final int start = DateTime(2025, 8, 1).millisecondsSinceEpoch;
      final int end = DateTime(2025, 8, 31).millisecondsSinceEpoch;
      final List<Transaction> filtered =
          await db_ops.getAllTransactions(start, end, contactId: cid);
      expect(filtered.length, 1);
      expect(filtered.first.contactId, cid);
    });

    test('updateTransaction mutates row', () async {
      final int id = await db_ops.addTransaction(Transaction(
        description: 'orig',
        type: TransactionType.expenditure,
        amount: 100,
        date: DateTime(2025, 9, 1),
        category: 'misc',
        contactId: 0,
      ));
      final Transaction updated = Transaction(
        id: id,
        description: 'new desc',
        type: TransactionType.expenditure,
        amount: 200,
        date: DateTime(2025, 9, 1),
        category: 'food',
        contactId: 0,
      );
      expect(await db_ops.updateTransaction(updated), 1);
      final int start = DateTime(2025, 9, 1).millisecondsSinceEpoch;
      final int end = DateTime(2025, 9, 30).millisecondsSinceEpoch;
      final List<Transaction> rows = await db_ops.getAllTransactions(start, end);
      expect(rows.first.description, 'new desc');
      expect(rows.first.amount, 200);
    });

    test('deleteTransaction removes row', () async {
      final int id = await db_ops.addTransaction(Transaction(
        description: 'del',
        type: TransactionType.income,
        amount: 1,
        date: DateTime(2025, 10, 1),
        category: 'savings',
        contactId: 0,
      ));
      expect(
        await db_ops.deleteTransaction(Transaction(
          id: id,
          description: 'del',
          type: TransactionType.income,
          amount: 1,
          date: DateTime(2025, 10, 1),
          category: 'savings',
          contactId: 0,
        )),
        1,
      );
      final int start = DateTime(2025, 10, 1).millisecondsSinceEpoch;
      final int end = DateTime(2025, 10, 31).millisecondsSinceEpoch;
      expect(await db_ops.getAllTransactions(start, end), isEmpty);
    });

    test('getExpenseForTimePeriod respects filters', () async {
      final int cid = await db_ops.addContact(Contact(name: 'P'));
      final DateTime ts = DateTime(2025, 11, 15);
      await db_ops.addTransaction(Transaction(
        description: 'e1',
        type: TransactionType.expenditure,
        amount: 40,
        date: ts,
        category: 'utilities',
        contactId: cid,
      ));
      await db_ops.addTransaction(Transaction(
        description: 'e2',
        type: TransactionType.expenditure,
        amount: 10,
        date: ts,
        category: 'food',
        contactId: cid,
      ));
      final int start = DateTime(2025, 11, 1).millisecondsSinceEpoch;
      final int end = DateTime(2025, 11, 30).millisecondsSinceEpoch;
      final Map<String, int> totals =
          await db_ops.getExpenseForTimePeriod(start, end, category: 'utilities', contactId: cid);
      expect(totals['expenses'], 40);
      expect(totals['income'], 0);
    });

    test('getExpenseTotalsByCategory sums only expenditures in range', () async {
      final DateTime ts = DateTime(2025, 12, 5);
      final int start = DateTime(2025, 12, 1).millisecondsSinceEpoch;
      final int end = DateTime(2025, 12, 31, 23, 59, 59, 999).millisecondsSinceEpoch;
      await db_ops.addTransaction(Transaction(
        description: 'food',
        type: TransactionType.expenditure,
        amount: 3000,
        date: ts,
        category: 'food',
        contactId: 0,
      ));
      await db_ops.addTransaction(Transaction(
        description: 'food2',
        type: TransactionType.expenditure,
        amount: 1000,
        date: ts,
        category: 'food',
        contactId: 0,
      ));
      await db_ops.addTransaction(Transaction(
        description: 'sal',
        type: TransactionType.income,
        amount: 50000,
        date: ts,
        category: 'salary',
        contactId: 0,
      ));
      final Map<String, int> byCat = await db_ops.getExpenseTotalsByCategory(start, end);
      expect(byCat['food'], 4000);
      expect(byCat.containsKey('salary'), isFalse);
    });

    test('getContactById returns contact by primary key', () async {
      final int id = await db_ops.addContact(Contact(name: 'Ada'));
      expect(id, greaterThan(0));
      final Contact? found = await db_ops.getContactById(id);
      expect(found, isNotNull);
      expect(found!.name, 'Ada');
      expect(await db_ops.getContactById(999999), isNull);
    });

    test('getTopExpenditures returns largest expense rows first', () async {
      final DateTime ts = DateTime(2025, 12, 8);
      final int start = DateTime(2025, 12, 1).millisecondsSinceEpoch;
      final int end = DateTime(2025, 12, 31, 23, 59, 59, 999).millisecondsSinceEpoch;
      await db_ops.addTransaction(Transaction(
        description: 'small',
        type: TransactionType.expenditure,
        amount: 100,
        date: ts,
        category: 'misc',
        contactId: 0,
      ));
      await db_ops.addTransaction(Transaction(
        description: 'big',
        type: TransactionType.expenditure,
        amount: 9999,
        date: ts,
        category: 'rent',
        contactId: 0,
      ));
      final List<Transaction> top = await db_ops.getTopExpenditures(start, end, 2);
      expect(top.length, 2);
      expect(top.first.amount, 9999);
      expect(top.first.description, 'big');
    });
  });

  group('contacts', () {
    test('addContact and getContacts ordered by name', () async {
      await db_ops.addContact(Contact(name: 'Zed'));
      await db_ops.addContact(Contact(name: 'Amy'));
      final List<Contact> list = await db_ops.getContacts();
      expect(list.map((c) => c.name).toList(), ['Amy', 'Zed']);
    });

    test('getContactWithName is case-insensitive', () async {
      await db_ops.addContact(Contact(name: 'Bob'));
      final List<Map<String, dynamic>> found = await db_ops.getContactWithName('bob');
      expect(found.length, 1);
    });

    test('deleteContact removes contact', () async {
      final int id = await db_ops.addContact(Contact(name: 'Temp'));
      await db_ops.deleteContact(Contact(id: id, name: 'Temp'));
      expect(await db_ops.getContacts(), isEmpty);
    });
  });
}
