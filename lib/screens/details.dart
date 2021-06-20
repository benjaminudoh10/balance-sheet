import 'package:balance_sheet/controllers/transactionController.dart';
import 'package:balance_sheet/models/transaction.dart';
import 'package:balance_sheet/enums.dart';
import 'package:balance_sheet/screens/new_income_form.dart';
import 'package:balance_sheet/utils.dart';
import 'package:balance_sheet/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

const double APP_WIDTH = 20.0;

class TransactionDetails extends StatelessWidget {
  final Transaction transaction;

  TransactionDetails({@required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.only(
                top: 60.0,
                left: APP_WIDTH,
                right: APP_WIDTH,
                bottom: 20.0,
              ),
              decoration: BoxDecoration(
                color: Color(0xFFAF47FF),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 9,
                    child: Center(
                      child: Text(
                        transaction.description,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.0),
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      onTap: Get.back,
                      child: roundedIcon(
                        icon: Icons.close,
                        iconSize: 22.0,
                        iconColor: Colors.white,
                        containerColor: Color(0x22ffffff),
                        padding: EdgeInsets.all(8.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: 20.0,
                  horizontal: 20.0,
                ),
                decoration: BoxDecoration(
                  color: Color(0x22AF47FF),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: transaction.type == TransactionType.income ? Color(0x555DAC7F) : Color(0x44ff0000),
                            borderRadius: BorderRadius.circular(20.0),
                            border: Border.all(color: Colors.white)
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: 5.0,
                            horizontal: 10.0,
                          ),
                          child: Text(
                            transaction.type == TransactionType.income ? "Cash inflow" : "Cash outflow",
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Text(
                          "Time",
                          style: TextStyle(
                            fontSize: 14.0,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatAmount(transaction.amount),
                          style: TextStyle(
                            fontSize: 28.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat.jm().format(transaction.date),
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.0),
                    Wrap(
                      children: [
                        Text(
                          transaction.description,
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ]
                    ),
                    roundedButton(
                      text: "Edit",
                      color: Color(0xFFAF47FF),
                      action: () => showEditModal(this.transaction),
                    ),
                    roundedButton(
                      text: "Delete",
                      color: Color(0xaaff0000),
                      action: () => showDeleteModal(transaction),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showEditModal(Transaction transaction) {
  TransactionController _transactionController = Get.find();
  _transactionController.description.value = transaction.description;
  _transactionController.descController.value.text = transaction.description;
  _transactionController.amount.value = transaction.amount;
  _transactionController.amountController.value.text = (transaction.amount / 100).toStringAsFixed(2);

  BuildContext context = Get.context;
  showModalBottomSheet<void>(
    backgroundColor: Colors.transparent,
    barrierColor: Color(0x22AF47FF),
    isScrollControlled: true,
    context: context,
    builder: (context) => IncomeForm(
      type: transaction.type,
      transaction: transaction,
    ),
  );
}

void showDeleteModal(Transaction transaction) {
  BuildContext context = Get.context;
  TransactionController _transactionController = Get.find();

  showModalBottomSheet(
    backgroundColor: Colors.transparent,
    barrierColor: Color(0x22AF47FF),
    context: context,
    builder: (context) => Container(
      height: 300.0,
      padding: EdgeInsets.all(45.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25.0),
          topRight: Radius.circular(25.0),
        ),
      ),
      child: Column(
        children: [
          Text(
            "Are you sure you want to delete this transaction?",
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          roundedButton(
            text: "YES",
            color: Color(0xFFAF47FF),
            action: () => _transactionController.deleteTransaction(transaction),
          ),
          roundedButton(
            text: "NO",
            textColor: Color(0xFFAF47FF),
            color: Color(0x22AF47FF),
            action: () => Get.back(),
          ),
        ],
      ),
    ),
  );
}
