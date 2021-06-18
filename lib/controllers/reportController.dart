import 'package:balance_sheet/database/operations.dart' as db;
import 'package:balance_sheet/enums.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ReportController extends GetxController {
  RxBool fetchingTransaction = false.obs;
  var type = ReportType.today.obs;
  RxString label = "Today's entries".obs;
  RxDouble amount = 0.0.obs;

  RxInt income = 0.obs;
  RxInt expense = 0.obs;

  var transactions = [];
  var splitTransactions = {}.obs;
  DateTime singleDate = DateTime.now();
  DateTimeRange dateTimeRange = DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now()
  );

  List<int> timeFrames = [0, 0];

  @override
  void onReady() {
    super.onReady();

    timeFrames = getTimeFrame();

    getTransactions();
    getTransactionTotal();
  }

  changeType(ReportType reportType) async {
    if (reportType == ReportType.today) {
      label.value = "Today's entries";
    } else if (reportType == ReportType.month) {
      label.value = "This month";
    } else if (reportType == ReportType.lastWeek) {
      label.value = "Last week";
    } else if (reportType == ReportType.lastMonth) {
      label.value = "Last month";
    } else if (reportType == ReportType.singleDay) {
      singleDate = await selectDate();
      if (singleDate == null) {
        singleDate = DateTime.now();
        Get.back();
        return;
      }
      label.value = DateFormat.yMMMMd().format(singleDate);
    } else if (reportType == ReportType.dateRange) {
      dateTimeRange = await selectDateRange();
      if (dateTimeRange == null) {
        dateTimeRange = DateTimeRange(
          start: DateTime.now(),
          end: DateTime.now()
        );
        Get.back();
        return;
      }
      label.value = '${DateFormat.yMMMMd().format(dateTimeRange.start)} - ${DateFormat.yMMMMd().format(dateTimeRange.end)}';
    }
    type.value = reportType;
  
    Get.back();
    timeFrames = getTimeFrame();
    getTransactions();
    getTransactionTotal();
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
    } else if (type.value == ReportType.lastWeek) {
      DateTime lastWeekStart = now.subtract(Duration(days: now.weekday));
      lastWeekStart = DateTime(lastWeekStart.year, lastWeekStart.month, lastWeekStart.day);
      DateTime lastWeekEnd = now.add(Duration(days: DateTime.daysPerWeek - now.weekday - 1));
      lastWeekEnd = DateTime(
        lastWeekEnd.year,
        lastWeekEnd.month,
        lastWeekEnd.day,
        23,
        59,
        59,
        999
      );
      // fix: this represents the current week

      return [lastWeekStart.millisecondsSinceEpoch, lastWeekEnd.millisecondsSinceEpoch];
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
    transactions = await db.getAllTransactions(
      timeFrames[0],
      timeFrames[1],
    );
    splitTransactions.value = splitTransactionsIntoDays(transactions);
  }

  splitTransactionsIntoDays(List transactions) {
    int startTime = timeFrames[0];
    int oneDay = 86400000;
    Map<int, List> splitData = {};
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
    );
    expense.value = transactionData['expenses'] ?? 0;
    income.value = transactionData['income'] ?? 0;
  }

  Future<DateTime> selectDate() async {
    return await showDatePicker(
      context: Get.context,
      initialDate: singleDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2045),
      selectableDayPredicate: (day) => day.isBefore(DateTime.now())
    );
  }

  Future<DateTimeRange> selectDateRange() async {
    return await showDateRangePicker(
      context: Get.context,
      initialDateRange: dateTimeRange,
      firstDate: DateTime(2021, 6),
      lastDate: DateTime.now(),
    );
  }
}
