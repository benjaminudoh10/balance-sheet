import 'package:balance_sheet/constants/category.dart';
import 'package:balance_sheet/constants/colors.dart';
import 'package:balance_sheet/controllers/app_controller.dart';
import 'package:balance_sheet/database/operations.dart' as db;
import 'package:balance_sheet/enums.dart';
import 'package:balance_sheet/models/contact.dart';
import 'package:balance_sheet/models/transaction.dart';
import 'package:balance_sheet/widgets/date_range_picker_sheet.dart';
import 'package:balance_sheet/utils/app_snack.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ReportController extends GetxController {
  /// Rows fetched per scroll-to-load-more page.
  ///
  /// Wide ranges (e.g. 2021-2026) used to inflate thousands of widgets in one
  /// frame and freeze the UI; paging keeps that work bounded per fetch.
  static const int pageSize = 100;

  Rx<ReportType> type = ReportType.today.obs;
  RxString label = "Today".obs;

  RxInt income = 0.obs;
  RxInt expense = 0.obs;

  RxList<Transaction> transactions = <Transaction>[].obs;
  RxMap<int, List<Transaction>> splitTransactions =
      <int, List<Transaction>>{}.obs;

  /// True while the first page for the current filter set is being fetched.
  RxBool isLoadingInitial = false.obs;

  /// True while a subsequent page is being appended.
  RxBool isLoadingMore = false.obs;

  /// False once the last page has been appended for the current filter set.
  RxBool hasMore = true.obs;

  DateTime singleDate = DateTime.now();
  DateTimeRange dateTimeRange =
      DateTimeRange(start: DateTime.now(), end: DateTime.now());

  RxString category = 'Category'.obs;
  RxString categoryLabel = 'Category'.obs;
  final Rx<Contact> contact = Contact(name: 'Contact').obs;
  RxList<int> filterTagIds = <int>[].obs;

  List<int> timeFrames = [0, 0];

  /// Avoids duplicate DB work when [applySavedViewState] sets category/contact together.
  bool _suppressFilterReload = false;

  RxSet<int> selectedTransactionIds = <int>{}.obs;

  bool get isMultiSelectMode => selectedTransactionIds.isNotEmpty;

  void toggleTransactionSelection(int transactionId) {
    if (selectedTransactionIds.contains(transactionId)) {
      selectedTransactionIds.remove(transactionId);
    } else {
      selectedTransactionIds.add(transactionId);
    }
  }

  void clearSelection() {
    selectedTransactionIds.clear();
  }

  Future<void> deleteSelectedTransactions() async {
    final bool useTrash = Get.find<AppController>().useTrash.value;
    for (final int id in selectedTransactionIds) {
      if (useTrash) {
        await db.moveTransactionToTrash(id);
      } else {
        await db.permanentlyDeleteTransaction(id);
      }
    }
    final int count = selectedTransactionIds.length;
    clearSelection();
    await getTransactions();
    await getTransactionTotal();

    AppSnack.show(
      "Successful",
      '$count ${count == 1 ? 'transaction' : 'transactions'} ${useTrash ? 'moved to trash' : 'deleted successfully'}',
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.GREEN,
    );
  }

  /// Monotonic token so paginated fetches that started before a filter change
  /// don't leak stale rows into the list after a reset.
  int _loadGeneration = 0;

  @override
  void onReady() async {
    super.onReady();

    // TransactionController mutates `transactions` directly on
    // delete/update; this listener keeps the grouped-by-day map in sync
    // without every call site having to rebuild it.
    transactions.listen((List<Transaction> txns) {
      splitTransactions.value = splitTransactionsIntoDays(txns);
    });

    category.listen((_) {
      if (!_suppressFilterReload) {
        getTransactions();
        getTransactionTotal();
      }

      final matches = Categories.CATEGORIES
          .where((c) => c["key"] == category.value)
          .toList();
      categoryLabel.value =
          matches.isNotEmpty ? matches[0]["label"] as String : 'Category';
    });

    contact.listen((_) {
      if (!_suppressFilterReload) {
        getTransactions();
        getTransactionTotal();
      }
    });

    filterTagIds.listen((_) {
      if (!_suppressFilterReload) {
        getTransactions();
        getTransactionTotal();
      }
    });

    if (Get.arguments is Map<String, dynamic>) {
      final Map<String, dynamic> args = Get.arguments as Map<String, dynamic>;
      _suppressFilterReload = true;
      try {
        if (args.containsKey('filter_report_type')) {
          final ReportType rt = args['filter_report_type'] as ReportType;
          type.value = rt;
          if (rt == ReportType.dateRange &&
              args.containsKey('filter_start_date') &&
              args.containsKey('filter_end_date')) {
            dateTimeRange = DateTimeRange(
              start: args['filter_start_date'] as DateTime,
              end: args['filter_end_date'] as DateTime,
            );
          }
          _syncLabelFromPeriodState();
        }

        if (args.containsKey('filter_category') &&
            (args['filter_category'] as String).isNotEmpty) {
          category.value = args['filter_category'] as String;
        }

        if (args.containsKey('filter_contact_id') &&
            (args['filter_contact_id'] as int) > 0) {
          final int cid = args['filter_contact_id'] as int;
          final Contact? row = await db.getContactById(cid);
          contact.value = row ?? Contact(id: cid, name: 'Contact');
        }

        if (args.containsKey('filter_tag_id') &&
            (args['filter_tag_id'] as int) > 0) {
          filterTagIds.assignAll(<int>[args['filter_tag_id'] as int]);
        }
      } finally {
        _suppressFilterReload = false;
      }
    }

    timeFrames = getTimeFrame();

    await getTransactions();
    await getTransactionTotal();
  }

  /// Serializable snapshot for [SavedViewsStorage] (All transactions).
  Map<String, dynamic> captureSavedViewState() {
    final Map<String, dynamic> m = <String, dynamic>{
      'type': type.value.name,
      'categoryKey': category.value,
      'contactId': contact.value.id,
      'tagIds': filterTagIds.toList(),
    };
    if (type.value == ReportType.singleDay) {
      m['singleDateIso'] = DateFormat('yyyy-MM-dd').format(singleDate);
    }
    if (type.value == ReportType.dateRange) {
      m['rangeStartIso'] = DateFormat('yyyy-MM-dd').format(dateTimeRange.start);
      m['rangeEndIso'] = DateFormat('yyyy-MM-dd').format(dateTimeRange.end);
    }
    return m;
  }

  DateTime _parseLocalDay(String? iso) {
    if (iso == null || iso.isEmpty) {
      return DateTime.now();
    }
    final DateTime? d = DateTime.tryParse(iso);
    if (d == null) {
      return DateTime.now();
    }
    return DateTime(d.year, d.month, d.day);
  }

  void _syncLabelFromPeriodState() {
    switch (type.value) {
      case ReportType.today:
        label.value = 'Today';
        break;
      case ReportType.month:
        label.value = 'This month';
        break;
      case ReportType.thisWeek:
        label.value = 'This week';
        break;
      case ReportType.lastMonth:
        label.value = 'Last month';
        break;
      case ReportType.singleDay:
        label.value = DateFormat.yMMMMd().format(singleDate);
        break;
      case ReportType.dateRange:
        label.value =
            '${DateFormat.yMMMMd().format(dateTimeRange.start)} - ${DateFormat.yMMMMd().format(dateTimeRange.end)}';
        break;
      case ReportType.allTime:
        label.value = 'All time';
        break;
    }
  }

  Future<void> applySavedViewState(Map<String, dynamic> p) async {
    final String? typeName = p['type'] as String?;
    ReportType rt = ReportType.today;
    if (typeName != null) {
      for (final ReportType t in ReportType.values) {
        if (t.name == typeName) {
          rt = t;
          break;
        }
      }
    }

    if (rt == ReportType.singleDay) {
      singleDate = _parseLocalDay(p['singleDateIso'] as String?);
    }
    if (rt == ReportType.dateRange) {
      final DateTime start = _parseLocalDay(p['rangeStartIso'] as String?);
      final DateTime end = _parseLocalDay(p['rangeEndIso'] as String?);
      dateTimeRange = DateTimeRange(start: start, end: end);
    }

    _suppressFilterReload = true;
    try {
      type.value = rt;
      _syncLabelFromPeriodState();

      category.value = p['categoryKey'] as String? ?? 'Category';

      final int cid = (p['contactId'] as num?)?.toInt() ?? 0;
      if (cid > 0) {
        final Contact? row = await db.getContactById(cid);
        contact.value = row ?? Contact(id: cid, name: 'Contact');
      } else {
        contact.value = Contact(name: 'Contact');
      }

      final List<dynamic>? tags = p['tagIds'] as List<dynamic>?;
      if (tags != null) {
        filterTagIds
            .assignAll(tags.whereType<num>().map((e) => e.toInt()).toList());
      } else {
        filterTagIds.clear();
      }
    } finally {
      _suppressFilterReload = false;
    }

    timeFrames = getTimeFrame();
    await getTransactions();
    await getTransactionTotal();
  }

  /// Updates period from UI (e.g. report screen dropdown).
  Future<void> applyPeriodType(ReportType reportType) async {
    if (reportType == ReportType.today) {
      label.value = 'Today';
    } else if (reportType == ReportType.month) {
      label.value = 'This month';
    } else if (reportType == ReportType.thisWeek) {
      label.value = 'This week';
    } else if (reportType == ReportType.lastMonth) {
      label.value = 'Last month';
    } else if (reportType == ReportType.allTime) {
      label.value = 'All time';
    } else if (reportType == ReportType.singleDay) {
      final DateTime? picked = await selectDate();
      if (picked == null) {
        return;
      }
      singleDate = picked;
      label.value = DateFormat.yMMMMd().format(singleDate);
    } else if (reportType == ReportType.dateRange) {
      final DateTimeRange? range = await selectDateRange();
      if (range == null) {
        return;
      }
      dateTimeRange = range;
      label.value =
          '${DateFormat.yMMMMd().format(dateTimeRange.start)} - ${DateFormat.yMMMMd().format(dateTimeRange.end)}';
    }
    type.value = reportType;
    timeFrames = getTimeFrame();
    await getTransactions();
    await getTransactionTotal();
  }

  List<int> getTimeFrame() {
    DateTime now = DateTime.now();

    if (type.value == ReportType.today) {
      DateTime startOfToday = DateTime(now.year, now.month, now.day);
      DateTime endOfToday =
          DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

      return [
        startOfToday.millisecondsSinceEpoch,
        endOfToday.millisecondsSinceEpoch
      ];
    } else if (type.value == ReportType.month) {
      DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
      DateTime lastDayOfMonth =
          DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);

      return [
        firstDayOfMonth.millisecondsSinceEpoch,
        lastDayOfMonth.millisecondsSinceEpoch
      ];
    } else if (type.value == ReportType.thisWeek) {
      DateTime weekStart = now.subtract(Duration(days: now.weekday % 7));
      weekStart = DateTime(weekStart.year, weekStart.month, weekStart.day);
      DateTime weekEnd =
          now.add(Duration(days: DateTime.daysPerWeek - now.weekday % 7 - 1));
      weekEnd =
          DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59, 999);

      return [weekStart.millisecondsSinceEpoch, weekEnd.millisecondsSinceEpoch];
    } else if (type.value == ReportType.lastMonth) {
      DateTime firstDayOfMonth = DateTime(now.year, now.month - 1, 1);
      DateTime lastDayOfMonth =
          DateTime(now.year, now.month, 0, 23, 59, 59, 999);

      return [
        firstDayOfMonth.millisecondsSinceEpoch,
        lastDayOfMonth.millisecondsSinceEpoch
      ];
    } else if (type.value == ReportType.singleDay) {
      DateTime beginningOfDate =
          DateTime(singleDate.year, singleDate.month, singleDate.day);
      DateTime endOfDate = DateTime(
          singleDate.year, singleDate.month, singleDate.day, 23, 59, 59, 999);

      return [
        beginningOfDate.millisecondsSinceEpoch,
        endOfDate.millisecondsSinceEpoch
      ];
    } else if (type.value == ReportType.dateRange) {
      DateTime beginningOfDate = DateTime(dateTimeRange.start.year,
          dateTimeRange.start.month, dateTimeRange.start.day);
      DateTime endOfDate = DateTime(dateTimeRange.end.year,
          dateTimeRange.end.month, dateTimeRange.end.day, 23, 59, 59, 999);

      return [
        beginningOfDate.millisecondsSinceEpoch,
        endOfDate.millisecondsSinceEpoch
      ];
    } else if (type.value == ReportType.allTime) {
      return [0, 0];
    }

    return [0, 0];
  }

  /// Loads the first page for the current filter set. Subsequent pages come
  /// from [loadNextPage] as the user scrolls.
  Future<void> getTransactions() async {
    final int gen = ++_loadGeneration;
    isLoadingInitial.value = true;
    isLoadingMore.value = false;
    hasMore.value = true;

    final List<Transaction> page = await db.getAllTransactions(
      timeFrames[0],
      timeFrames[1],
      category: category.value,
      contactId: contact.value.id,
      tagIds: filterTagIds,
      limit: pageSize,
      offset: 0,
    );

    if (gen != _loadGeneration) {
      return;
    }

    transactions.assignAll(page);
    splitTransactions.value = splitTransactionsIntoDays(transactions);
    hasMore.value = page.length == pageSize;
    isLoadingInitial.value = false;
  }

  /// Appends the next page of transactions to [transactions]. Safe to call
  /// repeatedly: re-entrancy is guarded by [isLoadingMore] and [hasMore], and
  /// stale responses from a prior filter set are dropped via [_loadGeneration].
  Future<void> loadNextPage() async {
    if (!hasMore.value) return;
    if (isLoadingInitial.value || isLoadingMore.value) return;

    final int gen = _loadGeneration;
    isLoadingMore.value = true;

    final List<Transaction> page = await db.getAllTransactions(
      timeFrames[0],
      timeFrames[1],
      category: category.value,
      contactId: contact.value.id,
      tagIds: filterTagIds,
      limit: pageSize,
      offset: transactions.length,
    );

    if (gen != _loadGeneration) {
      return;
    }

    if (page.isNotEmpty) {
      transactions.addAll(page);
      splitTransactions.value = splitTransactionsIntoDays(transactions);
    }
    hasMore.value = page.length == pageSize;
    isLoadingMore.value = false;
  }

  /// Full unpaginated snapshot for the current filter set — used by consumers
  /// (e.g. PDF export) that need every row regardless of scroll position.
  Future<List<Transaction>> fetchAllTransactionsForCurrentRange() async {
    return db.getAllTransactions(
      timeFrames[0],
      timeFrames[1],
      category: category.value,
      contactId: contact.value.id,
      tagIds: filterTagIds,
    );
  }

  /// Groups [transactions] by local calendar day (ms-since-epoch of midnight).
  ///
  /// O(n) over the input list — the previous implementation walked every day
  /// in the time frame, which for multi-year ranges dominated the render cost.
  Map<int, List<Transaction>> splitTransactionsIntoDays(
      List<Transaction> transactions) {
    final Map<int, List<Transaction>> splitData = <int, List<Transaction>>{};
    for (final Transaction t in transactions) {
      final DateTime d = t.date;
      final int dayKey =
          DateTime(d.year, d.month, d.day).millisecondsSinceEpoch;
      (splitData[dayKey] ??= <Transaction>[]).add(t);
    }
    return splitData;
  }

  getTransactionTotal() async {
    Map<String, dynamic> transactionData = await db.getExpenseForTimePeriod(
      timeFrames[0],
      timeFrames[1],
      category: category.value,
      contactId: contact.value.id,
      tagIds: filterTagIds,
    );
    expense.value = transactionData['expenses'] ?? 0;
    income.value = transactionData['income'] ?? 0;
  }

  Future<DateTime?> selectDate() async {
    return showAppDatePicker(
      Get.context!,
      initialDate: singleDate,
      firstDate: DateTime(2021),
      lastDate: DateTime.now(),
    );
  }

  Future<DateTimeRange?> selectDateRange() async {
    return showAppDateRangePicker(
      Get.context!,
      firstDate: DateTime(2021),
      lastDate: DateTime.now(),
      // Only seed the picker when the user already has a real range picked;
      // for the default today/today seed we'd rather open with nothing
      // selected so the first tap starts a fresh range.
      initialRange: type.value == ReportType.dateRange ? dateTimeRange : null,
    );
  }
}
