import 'package:balance_sheet/enums.dart';
import 'package:balance_sheet/models/budget_line.dart';
import 'package:balance_sheet/models/transaction.dart';

/// Whether [t] is counted toward [line]'s filtered expenditure sum for the month
/// (same rules as [getExpenditureTotalFiltered] in operations.dart).
bool expenditureMatchesBudgetLine(
  Transaction t,
  BudgetLine line,
  int startMs,
  int endMs,
) {
  if (t.type != TransactionType.expenditure) {
    return false;
  }
  final int d = t.date.millisecondsSinceEpoch;
  if (d < startMs || d > endMs) {
    return false;
  }
  if (!line.hasSpendTracker) {
    return false;
  }
  final String cat = line.categoryKey.trim();
  final bool useCat = cat.isNotEmpty;
  final bool useContact = line.contactId > 0;
  if (!useCat && !useContact) {
    return false;
  }
  if (useCat && useContact) {
    return t.category == cat || t.contactId == line.contactId;
  }
  if (useCat) {
    return t.category == cat;
  }
  return t.contactId == line.contactId;
}

int lineContributionForMonth(
  Transaction t,
  BudgetLine line,
  int startMs,
  int endMs,
) {
  return expenditureMatchesBudgetLine(t, line, startMs, endMs) ? t.amount : 0;
}
