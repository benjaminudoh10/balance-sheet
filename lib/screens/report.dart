import 'package:balance_sheet/controllers/reportController.dart';
import 'package:balance_sheet/enums.dart';
import 'package:balance_sheet/models/transaction.dart';
import 'package:balance_sheet/utils.dart';
import 'package:balance_sheet/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

const double APP_WIDTH = 20.0;

class ReportView extends StatelessWidget {
  final ReportController _reportController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text("Report"),
            SizedBox(width: 20.0),
            Icon(Icons.bar_chart)
          ],
        ),
      ),
      body: Obx(() => Container(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                vertical: 20.0,
                horizontal: APP_WIDTH,
              ),
              decoration: BoxDecoration(
                color: Color(0xFFAF47FF),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            "INCOME",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.0,
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 15.0),
                          Text(
                            formatAmount(_reportController.income.value),
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            "EXPENSES",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.0,
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 15.0),
                          Text(
                            formatAmount(_reportController.expense.value),
                            style: TextStyle(
                              color: Color(0xff000000),
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Get.dialog(
                      Dialog(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            color: Colors.white,
                          ),
                          padding: EdgeInsets.all(10.0),
                          height: 250.0,
                          child: Column(
                            children: [
                              _buildDialogItem(
                                "Today's entries",
                                () => _reportController.changeType(ReportType.today),
                                _reportController.type.value == ReportType.today,
                              ),
                              _buildDialogItem(
                                "This month",
                                () => _reportController.changeType(ReportType.month),
                                _reportController.type.value == ReportType.month,
                              ),
                              _buildDialogItem(
                                "Last week",
                                () => _reportController.changeType(ReportType.lastWeek),
                                _reportController.type.value == ReportType.lastWeek,
                              ),
                              _buildDialogItem(
                                "Last month",
                                () => _reportController.changeType(ReportType.lastMonth),
                                _reportController.type.value == ReportType.lastMonth,
                              ),
                              _buildDialogItem(
                                "Single day",
                                () => _reportController.changeType(ReportType.singleDay),
                                _reportController.type.value == ReportType.singleDay,
                              ),
                              _buildDialogItem(
                                "Date range...",
                                () => _reportController.changeType(ReportType.dateRange),
                                _reportController.type.value == ReportType.dateRange,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    child: Container(
                      padding: EdgeInsets.all(10.0),
                      margin: EdgeInsets.symmetric(vertical: 20.0),
                      decoration: BoxDecoration(
                        color: Color(0x22ffffff),
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                      width: Get.width * 0.8,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _reportController.label.value,
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 5.0),
                          Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: 30.0,
                  horizontal: 20.0,
                ),
                decoration: BoxDecoration(
                  color: Color(0x22AF47FF),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Transactions",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 10.0,
                          horizontal: 15.0,
                        ),
                        margin: EdgeInsets.only(
                          bottom: 25.0,
                          top: 10.0,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0x11000000),
                          borderRadius: BorderRadius.circular(7.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "DATE",
                              style: TextStyle(
                                fontSize: 10.0,
                              ),
                            ),
                            Text(
                              "(₦) OUT",
                              style: TextStyle(
                                fontSize: 10.0,
                              ),
                            ),
                            Text(
                              "(₦) IN",
                              style: TextStyle(
                                fontSize: 10.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ..._buildTransactionContainer(_reportController.splitTransactions.value),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      )),
    );
  }

  Widget _buildDialogItem(String text, Function action, bool highlight) {
    return GestureDetector(
      onTap: action,
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              color: highlight ? Color(0x33000000) : null,
              borderRadius: BorderRadius.circular(15.0),
            ),
            padding: EdgeInsets.symmetric(
              vertical: 5.0,
              horizontal: 20.0,
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTransactionContainer(Map<int, List> splitData) {
    return splitData.keys.toList().map((date) {
      String formattedDate = DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(date));
      List<Transaction> transactions = splitData[date];

      List<Transaction> expenseTxns = transactions.where(
        (transaction) => transaction.type == TransactionType.expenditure
      ).toList();
      List<Transaction> incomeTxns = transactions.where(
        (transaction) => transaction.type == TransactionType.income
      ).toList();

      int expense = expenseTxns.fold(0, (value, element) => value + element.amount);
      int income = incomeTxns.fold(0, (value, element) => value + element.amount);

      return GestureDetector(
        onTap: () => _showTransactions(formattedDate, transactions, income, expense),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7.0),
            border: Border.all(color: Color(0x11000000)),
          ),
          padding: EdgeInsets.all(12.0),
          margin: EdgeInsets.only(bottom: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formattedDate,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.0,
                ),
              ),
              Text(
                formatAmount(expense),
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12.0,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatAmount(income),
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12.0,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    "View",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFAF47FF),
                      fontSize: 12.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

void _showTransactions(String date, List<Transaction> transactions, int income, int expense) {
  BuildContext context = Get.context;
  showCupertinoModalBottomSheet(
    context: context,
    expand: true,
    builder: (context) => Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            color: Colors.white,
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      date,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                      ),
                    ),
                    GestureDetector(
                      onTap: Get.back,
                      child: roundedIcon(
                        icon: Icons.close,
                        iconColor: Color(0xbbAF47FF),
                        iconSize: 24.0,
                        containerColor: Color(0x22AF47FF),
                        padding: EdgeInsets.all(3.0)
                      ),
                    ),
                  ],
                ),
                totalDayTransaction(date, income, expense),
                ...transactions.map((transaction) => singleTransactionContainer(transaction)),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
