import 'package:balance_sheet/database/operations.dart' as db;
import 'package:balance_sheet/models/budget_line.dart';
import 'package:balance_sheet/models/budget_month.dart';
import 'package:get/get.dart';

/// Monthly planned spending. Lines may link a **category** (transaction tag) and/or a **contact**
/// to compare planned amounts with recorded expenditure for the focused month.
class BudgetController extends GetxController {
  final Rx<DateTime> focusMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1).obs;

  final Rxn<BudgetMonth> activeBudgetMonth = Rxn<BudgetMonth>();
  final RxList<BudgetLine> lines = <BudgetLine>[].obs;
  /// Actual spend (minor units) for each line id, when [BudgetLine.hasSpendTracker].
  final RxMap<int, int> spentMinorByLineId = <int, int>{}.obs;
  final RxBool loading = false.obs;

  int get plannedTotalMinor =>
      lines.fold<int>(0, (int sum, BudgetLine l) => sum + l.plannedAmount);

  /// Sum of per-line tracked spend (same transaction can be counted on multiple lines).
  int get trackedSpentTotalMinor => lines.fold<int>(
        0,
        (int sum, BudgetLine l) => sum + (spentMinorByLineId[l.id] ?? 0),
      );

  Future<void> reloadFocusMonth() async {
    loading.value = true;
    try {
      final DateTime m = focusMonth.value;
      final BudgetMonth month = await db.ensureBudgetMonth(m.year, m.month);
      activeBudgetMonth.value = month;
      final List<BudgetLine> list = await db.getBudgetLinesForMonth(month.id);
      lines.assignAll(list);
      final ({int startMs, int endMs}) range = db.calendarMonthEpochRange(m.year, m.month);
      final Map<int, int> byLine = <int, int>{};
      for (final BudgetLine line in list) {
        if (!line.hasSpendTracker) {
          continue;
        }
        final int total = await db.getExpenditureTotalFiltered(
          range.startMs,
          range.endMs,
          categoryKey: line.categoryKey.isEmpty ? null : line.categoryKey,
          contactId: line.contactId > 0 ? line.contactId : null,
        );
        byLine[line.id] = total;
      }
      spentMinorByLineId.assignAll(byLine);
    } finally {
      loading.value = false;
    }
  }

  void shiftMonth(int deltaMonths) {
    final DateTime m = focusMonth.value;
    focusMonth.value = DateTime(m.year, m.month + deltaMonths, 1);
    reloadFocusMonth();
  }

  Future<void> addLine({
    required String description,
    required int plannedAmountMinor,
    int contactId = 0,
    String categoryKey = '',
  }) async {
    final BudgetMonth? bm = activeBudgetMonth.value;
    if (bm == null) return;
    await db.insertBudgetLine(
      budgetMonthId: bm.id,
      description: description.trim(),
      plannedAmount: plannedAmountMinor,
      contactId: contactId,
      categoryKey: categoryKey,
    );
    await reloadFocusMonth();
  }

  Future<void> updateLine(BudgetLine line) async {
    await db.updateBudgetLine(line);
    await reloadFocusMonth();
  }

  Future<void> deleteLine(int lineId) async {
    await db.deleteBudgetLine(lineId);
    await reloadFocusMonth();
  }
}
