import 'package:balance_sheet/constants/colors.dart';
import 'package:balance_sheet/controllers/organizationController.dart';
import 'package:balance_sheet/controllers/reportController.dart';
import 'package:balance_sheet/dialogs/category.dart';
import 'package:balance_sheet/dialogs/contact.dart';
import 'package:balance_sheet/dialogs/reportType.dart';
import 'package:balance_sheet/enums.dart';
import 'package:balance_sheet/models/contact.dart';
import 'package:balance_sheet/models/transaction.dart';
import 'package:balance_sheet/utils.dart';
import 'package:balance_sheet/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

const double APP_WIDTH = 20.0;

class ReportView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ReportController _reportController = Get.put(ReportController());
    OrganizationController _organizationController = Get.find();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Report - ${_organizationController.organization.value.name}",
          overflow: TextOverflow.ellipsis,
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
                color: AppColors.PRIMARY,
              ),
              child: Column(
                children: [
                  Obx(() => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            "INCOME",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.0,
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
                              fontSize: 14.0,
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 15.0),
                          Text(
                            formatAmount(_reportController.expense.value),
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )),
                  GestureDetector(
                    onTap: () => Get.dialog(
                      ReportTypeDialog()
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        'Add Filter:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                        ),
                      ),
                      Flexible(
                        child: GestureDetector(
                          onTap: () => Get.dialog(
                            CategoryDialog(
                              controller: _reportController,
                            ),
                          ),
                          child: Chip(
                            label: Obx(() => Text(
                              _reportController.categoryLabel.value,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.0,
                              ),
                              overflow: TextOverflow.ellipsis,
                            )),
                            backgroundColor: Color(0xdd000000),
                            deleteIcon: Icon(
                              Icons.clear,
                              size: 14.0,
                              color: Colors.white,
                            ),
                            onDeleted: () {
                              _reportController.category.value = 'Category';
                            },
                          ),
                        ),
                      ),
                      Flexible(
                        child: GestureDetector(
                          onTap: () => Get.dialog(
                            ContactDialog(
                              controller: _reportController,
                            ),
                          ),
                          child: Chip(
                            label: Obx(() => Text(
                              _reportController.contact.value.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.0,
                              ),
                              overflow: TextOverflow.ellipsis,
                            )),
                            backgroundColor: Color(0xdd000000),
                            deleteIcon: Icon(
                              Icons.clear,
                              size: 14.0,
                              color: Colors.white,
                            ),
                            onDeleted: () {
                              _reportController.contact.value = Contact(name: 'Contact');
                            },
                          ),
                        ),
                      ),
                    ],
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
                child: Obx(() => SingleChildScrollView(
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
                                fontSize: 12.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "(???) OUT",
                              style: TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "(???) IN",
                              style: TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_reportController.transactions.length != 0)
                        ..._buildTransactionContainer(_reportController.splitTransactions),
                      if (_reportController.transactions.length == 0) EmptyState(
                        icon: Icon(
                          Icons.money,
                          size: 48.0,
                          color: AppColors.PRIMARY,
                        ),
                        primaryText: Text(
                          'No transaction was recorded in this time period',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        secondaryText: Text(
                          'Select a different time period',
                        ),
                      ),
                    ],
                  ),
                )),
              ),
            ),
          ],
        ),
      )),
    );
  }

  List<Widget> _buildTransactionContainer(Map<int, List<Transaction>> splitData) {
    return splitData.keys.toList().map((date) {
      String formattedDate = DateFormat.yMMMd().format(
        DateTime.fromMillisecondsSinceEpoch(date)
      );
      List<Transaction> transactions = splitData[date];
      if (transactions.length == 0) {
        return SizedBox();
      }

      int expense = 0, income = 0;
      transactions.forEach((transaction) {
        if (transaction.type == TransactionType.income) income += transaction.amount;
        else expense += transaction.amount;
      });

      return GestureDetector(
        onTap: () => _showTransactions(formattedDate, transactions, income, expense),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7.0),
            border: Border.all(color: AppColors.LIGHT_1_GREY),
            color: Colors.white,
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
                  fontSize: 14.0,
                ),
              ),
              Text(
                formatAmount(expense),
                style: TextStyle(
                  color: AppColors.RED,
                  fontSize: 14.0,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatAmount(income),
                    style: TextStyle(
                      color: AppColors.GREEN,
                      fontSize: 14.0,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    "View",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.PRIMARY,
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
  showCupertinoModalBottomSheet(
    context: Get.context,
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
                      child: roundedWidget(
                        widget: Icon(
                          Icons.close,
                          color: AppColors.PRIMARY,
                          size: 24.0,
                        ),
                        containerColor: AppColors.SECONDARY,
                        padding: EdgeInsets.all(3.0)
                      ),
                    ),
                  ],
                ),
                totalDayTransaction(date, income, expense),
                if (transactions.length != 0)
                  ...transactions.map((transaction) => singleTransactionContainer(transaction)),
                if (transactions.length == 0)
                  EmptyState(
                    icon: Icon(
                      Icons.money,
                      size: 48.0,
                      color: AppColors.PRIMARY,
                    ),
                    primaryText: Text(
                      'No transaction was recorded in this time period',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    secondaryText: Text(
                      'Select a different day',
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

// void _showCharts(int income, int expense) {
//   BuildContext context = Get.context;
//   showCupertinoModalBottomSheet(
//     context: context,
//     expand: true,
//     builder: (context) => Scaffold(
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Container(
//             color: Colors.white,
//             padding: EdgeInsets.all(20.0),
//           ),
//         ),
//       ),
//     ),
//   );
// }
