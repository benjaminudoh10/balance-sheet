import 'package:balance_sheet/constants/category.dart';
import 'package:balance_sheet/database/operations.dart' as db;
import 'package:balance_sheet/enums.dart';
import 'package:balance_sheet/models/contact.dart';
import 'package:balance_sheet/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ReportController extends GetxController {
  Rx<ReportType> type = ReportType.today.obs;
  RxString label = "Today".obs;

  RxInt income = 0.obs;
  RxInt expense = 0.obs;

  RxList<Transaction> transactions = <Transaction>[].obs;
  RxMap<int, List<Transaction>> splitTransactions = <int, List<Transaction>>{}.obs;

  DateTime singleDate = DateTime.now();
  DateTimeRange dateTimeRange = DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now()
  );

  RxString category = 'Category'.obs;
  RxString categoryLabel = 'Category'.obs;
  final Rx<Contact> contact = Contact(name: 'Contact').obs;

  List<int> timeFrames = [0, 0];

  /// Avoids duplicate DB work when [applySavedViewState] sets category/contact together.
  bool _suppressFilterReload = false;

  @override
  void onReady() {
    super.onReady();

    timeFrames = getTimeFrame();

    getTransactions();
    getTransactionTotal();

    transactions.listen((txns) {
      splitTransactions.value = splitTransactionsIntoDays(txns);
    });

    category.listen((_) {
      if (!_suppressFilterReload) {
        getTransactions();
        getTransactionTotal();
      }

      final matches = Categories.CATEGORIES.where(
        (c) => c["key"] == this.category.value
      ).toList();
      categoryLabel.value = matches.isNotEmpty ? matches[0]["label"] as String : 'Category';
    });

    contact.listen((_) {
      if (!_suppressFilterReload) {
        getTransactions();
        getTransactionTotal();
      }
    });
  }

  /// Serializable snapshot for [SavedViewsStorage] (All transactions).
  Map<String, dynamic> captureSavedViewState() {
    final Map<String, dynamic> m = <String, dynamic>{
      'type': type.value.name,
      'categoryKey': category.value,
      'contactId': contact.value.id,
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
      DateTime endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

      return [startOfToday.millisecondsSinceEpoch, endOfToday.millisecondsSinceEpoch];
    } else if (type.value == ReportType.month) {
      DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
      DateTime lastDayOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);

      return [firstDayOfMonth.millisecondsSinceEpoch, lastDayOfMonth.millisecondsSinceEpoch];
    } else if (type.value == ReportType.thisWeek) {
      DateTime weekStart = now.subtract(Duration(days: now.weekday % 7));
      weekStart = DateTime(weekStart.year, weekStart.month, weekStart.day);
      DateTime weekEnd = now.add(Duration(days: DateTime.daysPerWeek - now.weekday % 7 - 1));
      weekEnd = DateTime(
        weekEnd.year,
        weekEnd.month,
        weekEnd.day,
        23,
        59,
        59,
        999
      );

      return [weekStart.millisecondsSinceEpoch, weekEnd.millisecondsSinceEpoch];
    } else if (type.value == ReportType.lastMonth) {
      DateTime firstDayOfMonth = DateTime(now.year, now.month - 1, 1);
      DateTime lastDayOfMonth = DateTime(now.year, now.month, 0, 23, 59, 59, 999);

      return [firstDayOfMonth.millisecondsSinceEpoch, lastDayOfMonth.millisecondsSinceEpoch];
    } else if (type.value == ReportType.singleDay) {
      DateTime beginningOfDate = DateTime(singleDate.year, singleDate.month, singleDate.day);
      DateTime endOfDate = DateTime(
        singleDate.year,
        singleDate.month,
        singleDate.day,
        23,
        59,
        59,
        999
      );

      return [beginningOfDate.millisecondsSinceEpoch, endOfDate.millisecondsSinceEpoch];
    } else if (type.value == ReportType.dateRange) {
      DateTime beginningOfDate = DateTime(
        dateTimeRange.start.year,
        dateTimeRange.start.month,
        dateTimeRange.start.day
      );
      DateTime endOfDate = DateTime(
        dateTimeRange.end.year,
        dateTimeRange.end.month,
        dateTimeRange.end.day,
        23,
        59,
        59,
        999
      );

      return [beginningOfDate.millisecondsSinceEpoch, endOfDate.millisecondsSinceEpoch];
    }

    return [0, 0];
  }

  getTransactions() async {
    transactions.value = await db.getAllTransactions(
      timeFrames[0],
      timeFrames[1],
      category: category.value,
      contactId: contact.value.id,
    );
    splitTransactions.value = splitTransactionsIntoDays(transactions);
  }

  Map<int, List<Transaction>> splitTransactionsIntoDays(List<Transaction> transactions) {
    int startTime = timeFrames[0];
    int oneDay = 86400000;
    Map<int, List<Transaction>> splitData = {};
    while (startTime < timeFrames[1]) {
      splitData[startTime] = transactions.where(
        (transaction) {
          return transaction.date.millisecondsSinceEpoch >= startTime
            && transaction.date.millisecondsSinceEpoch < startTime + oneDay;
        }
      ).toList();
      startTime += oneDay;
    }

    return splitData;
  }

  getTransactionTotal() async {
    Map<String, dynamic> transactionData = await db.getExpenseForTimePeriod(
      timeFrames[0],
      timeFrames[1],
      category: category.value,
      contactId: contact.value.id,
    );
    expense.value = transactionData['expenses'] ?? 0;
    income.value = transactionData['income'] ?? 0;
  }

  Future<DateTime?> selectDate() async {
    return showDatePicker(
      context: Get.context!,
      initialDate: singleDate,
      firstDate: DateTime(2021, 6),
      lastDate: DateTime.now(),
      selectableDayPredicate: (day) => day.isBefore(DateTime.now())
    );
  }

  Future<DateTimeRange?> selectDateRange() async {
    return showDateRangePicker(
      context: Get.context!,
      initialDateRange: dateTimeRange,
      firstDate: DateTime(2021, 6),
      lastDate: DateTime.now(),
    );
  }
}
