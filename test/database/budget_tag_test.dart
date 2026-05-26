import 'package:balance_sheet/database/operations.dart' as db;
import 'package:balance_sheet/models/tag.dart';
import 'package:balance_sheet/models/contact.dart';
import 'package:balance_sheet/models/transaction.dart';
import 'package:balance_sheet/enums.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/database_test_setup.dart';

void main() {
  setUpAll(() {
    initializeSqfliteFfiForTests();
  });

  setUp(() async {
    await resetAppDatabaseFile();
  });

  group('Budget Tag Operations', () {
    test('Budget line preserves tagId', () async {
      final int tagId = await db.addTag('test-tag');
      final month = await db.ensureBudgetMonth(2026, 1);

      final int lineId = await db.insertBudgetLine(
        budgetMonthId: month.id,
        description: 'Tagged Item',
        plannedAmount: 1000,
        tagId: tagId,
      );

      final lines = await db.getBudgetLinesForMonth(month.id);
      expect(lines.length, 1);
      expect(lines.first.id, lineId);
      expect(lines.first.tagId, tagId);
      expect(lines.first.hasSpendTracker, isTrue);
    });

    test('getExpenditureTotalFiltered sums transactions with the attached tag',
        () async {
      final int tagId = await db.addTag('test-tag');
      final Tag tag = Tag(id: tagId, name: 'test-tag');

      final int start = DateTime(2026, 1, 1).millisecondsSinceEpoch;
      final int end = DateTime(2026, 1, 31, 23, 59, 59).millisecondsSinceEpoch;

      // Transaction with the tag
      await db.addTransaction(Transaction(
        description: 'Tagged Expense',
        type: TransactionType.expenditure,
        amount: 500,
        date: DateTime(2026, 1, 15),
        category: 'food',
        contactId: 0,
        tags: [tag],
      ));

      // Transaction without the tag
      await db.addTransaction(Transaction(
        description: 'Untagged Expense',
        type: TransactionType.expenditure,
        amount: 300,
        date: DateTime(2026, 1, 16),
        category: 'food',
        contactId: 0,
      ));

      final int total = await db.getExpenditureTotalFiltered(
        start,
        end,
        tagId: tagId,
      );

      expect(total, 500);
    });

    test(
        'getExpenditureTotalFiltered handles union of category, contact, and tag',
        () async {
      final int tagId = await db.addTag('test-tag');
      final Tag tag = Tag(id: tagId, name: 'test-tag');
      final int contactId = await db.addContact(Contact(name: 'Test Contact'));

      final int start = DateTime(2026, 1, 1).millisecondsSinceEpoch;
      final int end = DateTime(2026, 1, 31, 23, 59, 59).millisecondsSinceEpoch;

      // 1. Matching category
      await db.addTransaction(Transaction(
        description: 'Category Match',
        type: TransactionType.expenditure,
        amount: 100,
        date: DateTime(2026, 1, 5),
        category: 'food',
        contactId: 0,
      ));

      // 2. Matching contact
      await db.addTransaction(Transaction(
        description: 'Contact Match',
        type: TransactionType.expenditure,
        amount: 200,
        date: DateTime(2026, 1, 6),
        category: 'misc',
        contactId: contactId,
      ));

      // 3. Matching tag
      await db.addTransaction(Transaction(
        description: 'Tag Match',
        type: TransactionType.expenditure,
        amount: 400,
        date: DateTime(2026, 1, 7),
        category: 'misc',
        contactId: 0,
        tags: [tag],
      ));

      // 4. Multiple matches (should only be counted once)
      await db.addTransaction(Transaction(
        description: 'Multi Match',
        type: TransactionType.expenditure,
        amount: 800,
        date: DateTime(2026, 1, 8),
        category: 'food',
        contactId: contactId,
        tags: [tag],
      ));

      // 5. No match
      await db.addTransaction(Transaction(
        description: 'No Match',
        type: TransactionType.expenditure,
        amount: 1600,
        date: DateTime(2026, 1, 9),
        category: 'transport',
        contactId: 0,
      ));

      final int total = await db.getExpenditureTotalFiltered(
        start,
        end,
        categoryKey: 'food',
        contactId: contactId,
        tagId: tagId,
      );

      // Sum: 100 + 200 + 400 + 800 = 1500
      expect(total, 1500);
    });
  });
}
