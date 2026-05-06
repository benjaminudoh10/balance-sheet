import 'package:balance_sheet/budget/budget_completion_logic.dart';
import 'package:balance_sheet/enums.dart';
import 'package:balance_sheet/models/budget_line.dart';
import 'package:balance_sheet/models/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final int startMs = DateTime(2026, 4, 1).millisecondsSinceEpoch;
  final int endMs =
      DateTime(2026, 4, 30, 23, 59, 59, 999).millisecondsSinceEpoch;
  final DateTime midMonth = DateTime(2026, 4, 15);

  group('expenditureMatchesBudgetLine', () {
    test('union: category OR contact', () {
      final BudgetLine line = BudgetLine(
        budgetMonthId: 1,
        description: 'x',
        plannedAmount: 10000,
        categoryKey: 'food',
        contactId: 5,
      );
      final Transaction byCat = Transaction(
        description: 'a',
        type: TransactionType.expenditure,
        amount: 100,
        date: midMonth,
        category: 'food',
        contactId: 0,
      );
      final Transaction byContact = Transaction(
        description: 'b',
        type: TransactionType.expenditure,
        amount: 100,
        date: midMonth,
        category: 'other',
        contactId: 5,
      );
      expect(expenditureMatchesBudgetLine(byCat, line, startMs, endMs), isTrue);
      expect(expenditureMatchesBudgetLine(byContact, line, startMs, endMs),
          isTrue);
    });

    test('income does not match', () {
      final BudgetLine line = BudgetLine(
        budgetMonthId: 1,
        description: 'x',
        plannedAmount: 10000,
        categoryKey: 'food',
      );
      final Transaction t = Transaction(
        description: 'a',
        type: TransactionType.income,
        amount: 100,
        date: midMonth,
        category: 'food',
        contactId: 0,
      );
      expect(expenditureMatchesBudgetLine(t, line, startMs, endMs), isFalse);
    });

    test('outside month range', () {
      final BudgetLine line = BudgetLine(
        budgetMonthId: 1,
        description: 'x',
        plannedAmount: 10000,
        categoryKey: 'food',
      );
      final Transaction t = Transaction(
        description: 'a',
        type: TransactionType.expenditure,
        amount: 100,
        date: DateTime(2026, 3, 15),
        category: 'food',
        contactId: 0,
      );
      expect(expenditureMatchesBudgetLine(t, line, startMs, endMs), isFalse);
    });
  });
}
