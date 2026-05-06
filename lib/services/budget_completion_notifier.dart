import 'package:balance_sheet/budget/budget_completion_logic.dart';
import 'package:balance_sheet/database/operations.dart' as db;
import 'package:balance_sheet/models/transaction.dart';
import 'package:balance_sheet/services/local_notification_service.dart';
import 'package:balance_sheet/utils.dart';
import 'package:flutter/foundation.dart';

/// When a transaction save causes a budget line to reach its planned amount, show a local notification.
Future<void> notifyBudgetCompletionsAfterTransactionSave(
  Transaction current, {
  Transaction? previous,
}) async {
  try {
    final DateTime d = current.date;
    final month = await db.getBudgetMonth(d.year, d.month);
    if (month == null) {
      return;
    }

    final lines = await db.getBudgetLinesForMonth(month.id);
    if (lines.isEmpty) {
      return;
    }

    final ({int startMs, int endMs}) range =
        db.calendarMonthEpochRange(d.year, d.month);

    for (final line in lines) {
      if (!line.hasSpendTracker || line.plannedAmount <= 0) {
        continue;
      }

      final int spentAfter = await db.getExpenditureTotalFiltered(
        range.startMs,
        range.endMs,
        categoryKey: line.categoryKey.isEmpty ? null : line.categoryKey,
        contactId: line.contactId > 0 ? line.contactId : null,
      );

      int spentBefore = spentAfter;
      spentBefore -=
          lineContributionForMonth(current, line, range.startMs, range.endMs);
      if (previous != null) {
        spentBefore += lineContributionForMonth(
            previous, line, range.startMs, range.endMs);
      }

      if (spentBefore < line.plannedAmount &&
          spentAfter >= line.plannedAmount) {
        final String label = line.description.trim().isEmpty
            ? 'Budget line'
            : line.description.trim();
        final int nid = month.id * 100000 + line.id;
        await LocalNotificationService.instance.showBudgetLineReached(
          id: nid,
          title: 'Budget reached',
          body:
              '$label: planned ${formatAmount(line.plannedAmount)} — spending has reached this amount.',
        );
      }
    }
  } catch (e, st) {
    debugPrint('notifyBudgetCompletionsAfterTransactionSave: $e\n$st');
  }
}
