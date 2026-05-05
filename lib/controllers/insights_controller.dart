import 'package:balance_sheet/constants/category.dart';
import 'package:balance_sheet/database/operations.dart' as db;
import 'package:balance_sheet/enums.dart';
import 'package:balance_sheet/models/contact.dart';
import 'package:balance_sheet/models/transaction.dart';
import 'package:balance_sheet/utils.dart';
import 'package:get/get.dart';

enum InsightsPeriod {
  today,
  thisWeek,
  thisMonth,
  lastMonth,
  thisYear,
  lastYear,
}

/// One bucket in the insights range with net cashflow (income − expense), minor units.
/// [bucketStart] is the first calendar day of the bucket (a day for daily granularity,
/// or the first of the month for monthly granularity).
class DailyNetPoint {
  const DailyNetPoint(this.bucketStart, this.netMinor);

  final DateTime bucketStart;
  final int netMinor;
}

/// Row for horizontal “expenses by category” bars (amounts minor units, sorted desc).
class CategoryBarRow {
  const CategoryBarRow({
    required this.key,
    required this.label,
    required this.amountMinor,
  });

  final String key;
  final String label;
  final int amountMinor;
}

/// One bucket within the insights range: income vs expense totals (minor units).
/// [bucketStart] is the first calendar day of the bucket — Monday for weekly granularity,
/// the first of the month for monthly granularity.
class WeeklyCashRow {
  const WeeklyCashRow({
    required this.bucketStart,
    required this.incomeMinor,
    required this.expenseMinor,
  });

  final DateTime bucketStart;
  final int incomeMinor;
  final int expenseMinor;
}

class _IncomeExpense {
  int income = 0;
  int expense = 0;
}

class InsightsController extends GetxController {
  final Rx<InsightsPeriod> period = InsightsPeriod.thisMonth.obs;

  final RxInt rangeStartMs = 0.obs;
  final RxInt rangeEndMs = 0.obs;

  final RxInt incomeTotal = 0.obs;
  final RxInt expenseTotal = 0.obs;
  final RxInt expensePreviousPeriod = 0.obs;

  final RxMap<String, int> categoryExpenses = <String, int>{}.obs;
  final RxList<CategoryBarRow> categoryBarRows = <CategoryBarRow>[].obs;
  final RxList<WeeklyCashRow> weeklyCashRows = <WeeklyCashRow>[].obs;
  final RxList<DailyNetPoint> dailyNet = <DailyNetPoint>[].obs;
  final RxList<Transaction> topExpenses = <Transaction>[].obs;
  final RxList<String> insightLines = <String>[].obs;

  final RxBool loading = true.obs;

  /// Filled during [load] for [_rebuildInsightLines] only.
  int _incomePreviousPeriod = 0;
  int _expenseTransactionCount = 0;
  int _incomeTransactionCount = 0;
  int _expenseFreeDaysInRange = 0;
  int _calendarDaysInRange = 1;
  Transaction? _largestIncomeInRange;
  MapEntry<int, int>? _topContactExpense;
  Map<int, String> _contactNamesById = {};

  static String periodLabel(InsightsPeriod p) {
    switch (p) {
      case InsightsPeriod.today:
        return 'Today';
      case InsightsPeriod.thisWeek:
        return 'This week';
      case InsightsPeriod.thisMonth:
        return 'This month';
      case InsightsPeriod.lastMonth:
        return 'Last month';
      case InsightsPeriod.thisYear:
        return 'This year';
      case InsightsPeriod.lastYear:
        return 'Last year';
    }
  }

  /// Baseline for comparisons (hero + takeaways): "yesterday" for [InsightsPeriod.today], else "the prior period".
  String get comparisonVsShort {
    switch (period.value) {
      case InsightsPeriod.today:
        return 'yesterday';
      case InsightsPeriod.thisWeek:
      case InsightsPeriod.thisMonth:
      case InsightsPeriod.lastMonth:
      case InsightsPeriod.thisYear:
      case InsightsPeriod.lastYear:
        return 'the prior period';
    }
  }

  /// Hint when there was no spending in the baseline window but there is in the current window.
  String get comparisonEmptyBaselineHint {
    switch (period.value) {
      case InsightsPeriod.today:
        return 'No expenses yesterday to compare.';
      case InsightsPeriod.thisWeek:
      case InsightsPeriod.thisMonth:
      case InsightsPeriod.lastMonth:
      case InsightsPeriod.thisYear:
      case InsightsPeriod.lastYear:
        return 'No expenses in the comparison window yet.';
    }
  }

  /// True when the current period is large enough that per-day / per-week buckets
  /// would be too dense; charts and tables should aggregate by calendar month instead.
  bool get useMonthlyBuckets {
    switch (period.value) {
      case InsightsPeriod.thisYear:
      case InsightsPeriod.lastYear:
        return true;
      case InsightsPeriod.today:
      case InsightsPeriod.thisWeek:
      case InsightsPeriod.thisMonth:
      case InsightsPeriod.lastMonth:
        return false;
    }
  }

  String get cashflowSeriesTitle => useMonthlyBuckets
      ? 'Income vs expenses by month'
      : 'Income vs expenses by week';

  String get cashflowSeriesSubtitle => useMonthlyBuckets
      ? 'Aggregated by calendar month · bars side-by-side per month'
      : 'Weeks start on Monday · bars side-by-side per week';

  /// Header used for the leading column of the cashflow table in PDF exports.
  String get cashflowBucketHeader =>
      useMonthlyBuckets ? 'Month' : 'Week starting';

  /// PDF section title for the cashflow table.
  String get cashflowPdfSectionTitle => cashflowSeriesTitle;

  String get netTrendSeriesTitle =>
      useMonthlyBuckets ? 'Net per month' : 'Net per day';

  String get netTrendSeriesSubtitle => useMonthlyBuckets
      ? 'Income minus expenses, by calendar month'
      : 'Income minus expenses, by calendar day';

  /// Header used for the leading column of the net-trend table in PDF exports.
  String get netTrendBucketHeader => useMonthlyBuckets ? 'Month' : 'Date';

  /// PDF section title for the net-trend table.
  String get netTrendPdfSectionTitle =>
      useMonthlyBuckets ? 'Monthly net' : 'Daily net';

  /// Current selection’s [start, end] in ms, then the comparison range immediately before it.
  /// [InsightsPeriod.thisWeek] matches [ReportController.getTimeFrame] for [ReportType.thisWeek].
  (int, int, int, int) _rangesFor(InsightsPeriod p, DateTime now) {
    switch (p) {
      case InsightsPeriod.today:
        final DateTime start = DateTime(now.year, now.month, now.day);
        final DateTime end =
            DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        final DateTime yStart = start.subtract(const Duration(days: 1));
        final DateTime yEnd =
            DateTime(yStart.year, yStart.month, yStart.day, 23, 59, 59, 999);
        return (
          start.millisecondsSinceEpoch,
          end.millisecondsSinceEpoch,
          yStart.millisecondsSinceEpoch,
          yEnd.millisecondsSinceEpoch,
        );
      case InsightsPeriod.thisWeek:
        DateTime weekStart = now.subtract(Duration(days: now.weekday % 7));
        weekStart = DateTime(weekStart.year, weekStart.month, weekStart.day);
        DateTime weekEnd =
            now.add(Duration(days: DateTime.daysPerWeek - now.weekday % 7 - 1));
        weekEnd =
            DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59, 999);
        final DateTime prevStart = weekStart.subtract(const Duration(days: 7));
        final DateTime prevEnd = weekEnd.subtract(const Duration(days: 7));
        return (
          weekStart.millisecondsSinceEpoch,
          weekEnd.millisecondsSinceEpoch,
          prevStart.millisecondsSinceEpoch,
          prevEnd.millisecondsSinceEpoch,
        );
      case InsightsPeriod.thisMonth:
        final DateTime first = DateTime(now.year, now.month, 1);
        final DateTime last =
            DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
        final DateTime prevFirst = DateTime(now.year, now.month - 1, 1);
        final DateTime prevLast =
            DateTime(now.year, now.month, 0, 23, 59, 59, 999);
        return (
          first.millisecondsSinceEpoch,
          last.millisecondsSinceEpoch,
          prevFirst.millisecondsSinceEpoch,
          prevLast.millisecondsSinceEpoch,
        );
      case InsightsPeriod.lastMonth:
        final DateTime first = DateTime(now.year, now.month - 1, 1);
        final DateTime last = DateTime(now.year, now.month, 0, 23, 59, 59, 999);
        final DateTime prevFirst = DateTime(now.year, now.month - 2, 1);
        final DateTime prevLast =
            DateTime(now.year, now.month - 1, 0, 23, 59, 59, 999);
        return (
          first.millisecondsSinceEpoch,
          last.millisecondsSinceEpoch,
          prevFirst.millisecondsSinceEpoch,
          prevLast.millisecondsSinceEpoch,
        );
      case InsightsPeriod.thisYear:
        final DateTime first = DateTime(now.year, 1, 1);
        final DateTime last = DateTime(now.year, 12, 31, 23, 59, 59, 999);
        final DateTime prevFirst = DateTime(now.year - 1, 1, 1);
        final DateTime prevLast =
            DateTime(now.year - 1, 12, 31, 23, 59, 59, 999);
        return (
          first.millisecondsSinceEpoch,
          last.millisecondsSinceEpoch,
          prevFirst.millisecondsSinceEpoch,
          prevLast.millisecondsSinceEpoch,
        );
      case InsightsPeriod.lastYear:
        final DateTime first = DateTime(now.year - 1, 1, 1);
        final DateTime last = DateTime(now.year - 1, 12, 31, 23, 59, 59, 999);
        final DateTime prevFirst = DateTime(now.year - 2, 1, 1);
        final DateTime prevLast =
            DateTime(now.year - 2, 12, 31, 23, 59, 59, 999);
        return (
          first.millisecondsSinceEpoch,
          last.millisecondsSinceEpoch,
          prevFirst.millisecondsSinceEpoch,
          prevLast.millisecondsSinceEpoch,
        );
    }
  }

  Future<void> setPeriod(InsightsPeriod p) async {
    period.value = p;
    await load();
  }

  Map<String, dynamic> captureSavedViewState() => <String, dynamic>{
        'period': period.value.name,
      };

  Future<void> applySavedViewState(Map<String, dynamic> p) async {
    final String? name = p['period'] as String?;
    InsightsPeriod next = InsightsPeriod.thisMonth;
    if (name != null) {
      for (final InsightsPeriod e in InsightsPeriod.values) {
        if (e.name == name) {
          next = e;
          break;
        }
      }
    }
    await setPeriod(next);
  }

  Future<void> load() async {
    loading.value = true;
    try {
      final now = DateTime.now();
      final (int s, int e, int ps, int pe) = _rangesFor(period.value, now);
      rangeStartMs.value = s;
      rangeEndMs.value = e;

      final Map<String, int> cur = await db.getExpenseForTimePeriod(s, e);
      incomeTotal.value = cur['income'] ?? 0;
      expenseTotal.value = cur['expenses'] ?? 0;

      final Map<String, int> prevMap = await db.getExpenseForTimePeriod(ps, pe);
      expensePreviousPeriod.value = prevMap['expenses'] ?? 0;
      _incomePreviousPeriod = prevMap['income'] ?? 0;

      categoryExpenses.value = await db.getExpenseTotalsByCategory(s, e);
      _rebuildCategoryBarRows();

      final List<Transaction> txns = await db.getAllTransactions(s, e);
      _rebuildWeeklyCashRows(txns, s, e);
      dailyNet.value = _buildDailyNetSeries(txns, s, e);

      topExpenses.value = await db.getTopExpenditures(s, e, 5);

      final List<Contact> contacts = await db.getContacts();
      _contactNamesById = {for (final Contact c in contacts) c.id: c.name};
      _applyTransactionAggregates(txns, s, e);

      if (_topContactExpense != null && _topContactExpense!.key > 0) {
        final int cid = _topContactExpense!.key;
        final Contact? row = await db.getContactById(cid);
        if (row != null && row.name.isNotEmpty) {
          _contactNamesById[cid] = row.name;
        }
      }

      _rebuildInsightLines();
    } finally {
      loading.value = false;
    }
  }

  static DateTime _startOfWeekMonday(DateTime d) {
    final DateTime day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  static DateTime _startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

  static DateTime _nextMonth(DateTime d) => DateTime(d.year, d.month + 1, 1);

  void _rebuildCategoryBarRows() {
    if (categoryExpenses.isEmpty) {
      categoryBarRows.clear();
      return;
    }
    final List<MapEntry<String, int>> sorted = categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    const int maxRows = 8;
    categoryBarRows.value = [
      for (final MapEntry<String, int> e in sorted.take(maxRows))
        CategoryBarRow(
          key: e.key,
          label: _categoryLabel(e.key),
          amountMinor: e.value,
        ),
    ];
  }

  void _rebuildWeeklyCashRows(List<Transaction> txns, int startMs, int endMs) {
    final DateTime rangeStart = DateTime.fromMillisecondsSinceEpoch(startMs);
    final DateTime rangeEnd = DateTime.fromMillisecondsSinceEpoch(endMs);

    if (useMonthlyBuckets) {
      weeklyCashRows.value =
          _aggregateMonthlyCashRows(txns, rangeStart, rangeEnd);
      return;
    }

    final DateTime firstMonday = _startOfWeekMonday(rangeStart);
    final DateTime lastMonday = _startOfWeekMonday(rangeEnd);

    final Map<DateTime, _IncomeExpense> agg = {};
    for (final Transaction t in txns) {
      final DateTime ws = _startOfWeekMonday(t.date);
      final _IncomeExpense w = agg.putIfAbsent(ws, _IncomeExpense.new);
      if (t.type == TransactionType.income) {
        w.income += t.amount;
      } else {
        w.expense += t.amount;
      }
    }

    final List<WeeklyCashRow> rows = [];
    for (DateTime w = firstMonday;
        !w.isAfter(lastMonday);
        w = w.add(const Duration(days: 7))) {
      final _IncomeExpense? v = agg[w];
      rows.add(
        WeeklyCashRow(
          bucketStart: w,
          incomeMinor: v?.income ?? 0,
          expenseMinor: v?.expense ?? 0,
        ),
      );
    }
    weeklyCashRows.value = rows;
  }

  List<WeeklyCashRow> _aggregateMonthlyCashRows(
      List<Transaction> txns, DateTime rangeStart, DateTime rangeEnd) {
    final Map<DateTime, _IncomeExpense> agg = {};
    for (final Transaction t in txns) {
      final DateTime ms = _startOfMonth(t.date);
      final _IncomeExpense m = agg.putIfAbsent(ms, _IncomeExpense.new);
      if (t.type == TransactionType.income) {
        m.income += t.amount;
      } else {
        m.expense += t.amount;
      }
    }

    final DateTime firstMonth = _startOfMonth(rangeStart);
    final DateTime lastMonth = _startOfMonth(rangeEnd);

    final List<WeeklyCashRow> rows = [];
    for (DateTime m = firstMonth; !m.isAfter(lastMonth); m = _nextMonth(m)) {
      final _IncomeExpense? v = agg[m];
      rows.add(
        WeeklyCashRow(
          bucketStart: m,
          incomeMinor: v?.income ?? 0,
          expenseMinor: v?.expense ?? 0,
        ),
      );
    }
    return rows;
  }

  List<DailyNetPoint> _buildDailyNetSeries(
      List<Transaction> txns, int startMs, int endMs) {
    final DateTime start = DateTime.fromMillisecondsSinceEpoch(startMs);
    final DateTime end = DateTime.fromMillisecondsSinceEpoch(endMs);

    if (useMonthlyBuckets) {
      return _buildMonthlyNetSeries(txns, start, end);
    }

    final DateTime startDay = DateTime(start.year, start.month, start.day);
    final DateTime endDay = DateTime(end.year, end.month, end.day);

    final Map<DateTime, int> byDay = {};
    for (final Transaction t in txns) {
      final DateTime d = DateTime(t.date.year, t.date.month, t.date.day);
      final int delta = t.type == TransactionType.income ? t.amount : -t.amount;
      byDay[d] = (byDay[d] ?? 0) + delta;
    }

    final List<DailyNetPoint> out = [];
    for (DateTime d = startDay;
        !d.isAfter(endDay);
        d = d.add(const Duration(days: 1))) {
      out.add(DailyNetPoint(d, byDay[d] ?? 0));
    }
    return out;
  }

  List<DailyNetPoint> _buildMonthlyNetSeries(
      List<Transaction> txns, DateTime rangeStart, DateTime rangeEnd) {
    final Map<DateTime, int> byMonth = {};
    for (final Transaction t in txns) {
      final DateTime m = _startOfMonth(t.date);
      final int delta = t.type == TransactionType.income ? t.amount : -t.amount;
      byMonth[m] = (byMonth[m] ?? 0) + delta;
    }

    final DateTime firstMonth = _startOfMonth(rangeStart);
    final DateTime lastMonth = _startOfMonth(rangeEnd);

    final List<DailyNetPoint> out = [];
    for (DateTime m = firstMonth; !m.isAfter(lastMonth); m = _nextMonth(m)) {
      out.add(DailyNetPoint(m, byMonth[m] ?? 0));
    }
    return out;
  }

  void _applyTransactionAggregates(
      List<Transaction> txns, int startMs, int endMs) {
    _expenseTransactionCount = 0;
    _incomeTransactionCount = 0;
    _largestIncomeInRange = null;
    _topContactExpense = null;

    final Map<DateTime, int> expenseByDay = {};
    final Map<int, int> expenseByContact = {};

    for (final Transaction t in txns) {
      if (t.type == TransactionType.expenditure) {
        _expenseTransactionCount++;
        final DateTime d = DateTime(t.date.year, t.date.month, t.date.day);
        expenseByDay[d] = (expenseByDay[d] ?? 0) + t.amount;
        if (t.contactId > 0) {
          expenseByContact[t.contactId] =
              (expenseByContact[t.contactId] ?? 0) + t.amount;
        }
      } else if (t.type == TransactionType.income) {
        _incomeTransactionCount++;
        if (_largestIncomeInRange == null ||
            t.amount > _largestIncomeInRange!.amount) {
          _largestIncomeInRange = t;
        }
      }
    }

    if (expenseByContact.isNotEmpty) {
      final List<MapEntry<int, int>> sorted = expenseByContact.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      _topContactExpense = sorted.first;
    }

    final DateTime start = DateTime.fromMillisecondsSinceEpoch(startMs);
    final DateTime end = DateTime.fromMillisecondsSinceEpoch(endMs);
    final DateTime startDay = DateTime(start.year, start.month, start.day);
    final DateTime endDay = DateTime(end.year, end.month, end.day);
    int free = 0;
    int calendarDays = 0;
    for (DateTime d = startDay;
        !d.isAfter(endDay);
        d = d.add(const Duration(days: 1))) {
      calendarDays++;
      if ((expenseByDay[d] ?? 0) == 0) {
        free++;
      }
    }
    _calendarDaysInRange = calendarDays < 1 ? 1 : calendarDays;
    _expenseFreeDaysInRange = free;
  }

  String _contactName(int id) {
    final String? n = _contactNamesById[id];
    return (n != null && n.isNotEmpty) ? n : 'Contact #$id';
  }

  String _categoryLabel(String key) {
    final matches =
        Categories.CATEGORIES.where((c) => c['key'] == key).toList();
    return matches.isNotEmpty ? matches[0]['label'] as String : key;
  }

  void _rebuildInsightLines() {
    final List<String> lines = [];
    final int exp = expenseTotal.value;
    final int prevExp = expensePreviousPeriod.value;
    final int inc = incomeTotal.value;
    final int prevInc = _incomePreviousPeriod;

    final String vs = comparisonVsShort;
    if (prevExp > 0) {
      final int delta = exp - prevExp;
      final int pct = (delta / prevExp * 100).round();
      if (pct.abs() >= 1) {
        lines.add(
          pct > 0
              ? 'Spending is up $pct% vs $vs.'
              : 'Spending is down ${pct.abs()}% vs $vs.',
        );
      } else if (exp != prevExp) {
        lines.add('Spending changed slightly vs $vs.');
      }
    } else if (prevExp == 0 && exp > 0) {
      lines.add('Spending recorded for this period — compare again next time.');
    }

    final int net = inc - exp;
    final int prevNet = prevInc - prevExp;
    final bool hasPriorTotals = prevExp > 0 || prevInc > 0;
    if (hasPriorTotals) {
      lines.add(
          'Net ${formatSignedNet(net)} — was ${formatSignedNet(prevNet)} $vs.');
    }

    if (inc > 0) {
      final int retained = inc - exp;
      if (retained >= 0) {
        final int rate = (retained / inc * 100).round();
        lines.add('About $rate% of income remained after expenses.');
      } else {
        lines.add(
            'Spending exceeded income by ${formatAmount(-retained)} this period.');
      }
    } else if (exp > 0 && inc == 0) {
      lines.add(
          'No income logged this period — all spending draws down balance.');
    }

    if (prevInc > 0 || prevExp > 0) {
      final int incomeDelta = inc - prevInc;
      if (incomeDelta != 0 && prevInc > 0) {
        final int ipct = (incomeDelta / prevInc * 100).round();
        if (ipct.abs() >= 2) {
          lines.add(
            incomeDelta > 0
                ? 'Income is up about $ipct% vs $vs.'
                : 'Income is down about ${ipct.abs()}% vs $vs.',
          );
        }
      }
    }

    if (categoryExpenses.isNotEmpty && exp > 0) {
      final List<MapEntry<String, int>> sorted = categoryExpenses.entries
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final MapEntry<String, int> top = sorted.first;
      final int share = (top.value / exp * 100).round();
      if (share >= 1) {
        lines.add(
            '${_categoryLabel(top.key)} leads at about $share% of expenses.');
      }
      if (sorted.length >= 2) {
        final int topTwo = sorted[0].value + sorted[1].value;
        final int twoShare = (topTwo / exp * 100).round();
        if (twoShare >= 15 && twoShare < 100) {
          lines.add(
            '${_categoryLabel(sorted[0].key)} and ${_categoryLabel(sorted[1].key)} combine for about $twoShare% of spending.',
          );
        }
      }
    }

    if (exp > 0 && _calendarDaysInRange >= 1) {
      final int avg = exp ~/ _calendarDaysInRange;
      if (_calendarDaysInRange == 1) {
        lines.add('About ${formatAmount(avg)} in expenses for the day.');
      } else {
        lines.add(
            'Roughly ${formatAmount(avg)} in expenses per day on average.');
      }
    }

    if (_calendarDaysInRange >= 3 && _expenseFreeDaysInRange > 0) {
      lines.add(
        _expenseFreeDaysInRange == 1
            ? '1 day in this range had no spending.'
            : '$_expenseFreeDaysInRange days in this range had no spending.',
      );
    }

    if (_expenseTransactionCount > 0 || _incomeTransactionCount > 0) {
      final List<String> parts = [];
      if (_expenseTransactionCount > 0) {
        parts.add(
          _expenseTransactionCount == 1
              ? '1 expense entry'
              : '$_expenseTransactionCount expense entries',
        );
      }
      if (_incomeTransactionCount > 0) {
        parts.add(
          _incomeTransactionCount == 1
              ? '1 income entry'
              : '$_incomeTransactionCount income entries',
        );
      }
      lines.add('Activity: ${parts.join(', ')}.');
    }

    if (topExpenses.isNotEmpty) {
      final Transaction t = topExpenses.first;
      lines.add(
          'Largest expense: ${formatTransactionDisplayAmount(t)} · ${t.description}.');
    }

    if (_largestIncomeInRange != null && inc > 0) {
      final Transaction t = _largestIncomeInRange!;
      lines.add(
          'Largest income: ${formatTransactionDisplayAmount(t)} · ${t.description}.');
    }

    if (_topContactExpense != null && _topContactExpense!.value > 0) {
      lines.add(
        'Most spending with ${_contactName(_topContactExpense!.key)}: ${formatAmount(_topContactExpense!.value)}.',
      );
    }

    if (!hasPriorTotals && (inc > 0 || exp > 0)) {
      lines.add('Net for period: ${formatSignedNet(net)}.');
    }

    insightLines.value = _dedupeInsightLines(lines).take(18).toList();
  }

  /// Keeps order; drops consecutive duplicates and empty strings.
  List<String> _dedupeInsightLines(List<String> lines) {
    final List<String> out = [];
    String? prev;
    for (final String s in lines) {
      final String t = s.trim();
      if (t.isEmpty || t == prev) {
        continue;
      }
      out.add(t);
      prev = t;
    }
    return out;
  }
}
