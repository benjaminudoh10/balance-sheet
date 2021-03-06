import 'package:balance_sheet/constants/category.dart';
import 'package:balance_sheet/constants/colors.dart';
import 'package:balance_sheet/controllers/contactController.dart';
import 'package:balance_sheet/controllers/transactionController.dart';
import 'package:balance_sheet/models/contact.dart';
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
  final ContactController _contactController = Get.find();

  TransactionDetails({@required this.transaction});

  @override
  Widget build(BuildContext context) {
    List<Map<String, Object>> category = Categories.CATEGORIES.where(
      (category) => category["key"] == transaction.category
    ).toList();
    String categoryLabel = category[0]['label'];
    _contactController.getContact(this.transaction.contactId);
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
                color: AppColors.PRIMARY,
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
                      child: roundedWidget(
                        widget: Icon(
                          Icons.close,
                          size: 22.0,
                          color: Colors.white,
                        ),
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
                        Row(
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
                            SizedBox(width: 5.0),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.CATEGORY,
                                borderRadius: BorderRadius.circular(20.0),
                                border: Border.all(color: Colors.white)
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: 5.0,
                                horizontal: 10.0,
                              ),
                              child: Text(
                                categoryLabel,
                                style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
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
                        SizedBox(width: 15.0),
                        Flexible(
                          child: Obx(() => Text(
                            '${_contactController.contact.value?.name ?? ''}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.PRIMARY,
                              fontSize: 16.0
                            ),
                            overflow: TextOverflow.ellipsis,
                          )),
                        ),
                      ],
                    ),
                    roundedButton(
                      text: "Edit",
                      color: AppColors.PRIMARY,
                      action: () => showEditModal(
                        this.transaction,
                        _contactController.contact.value?.name
                      ),
                    ),
                    roundedButton(
                      text: "Delete",
                      color: AppColors.RED,
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

void showEditModal(Transaction transaction, String contactName) async {
  TransactionController _transactionController = Get.find();
  _transactionController.description.value = transaction.description;
  _transactionController.descController.value.text = transaction.description;
  _transactionController.amount.value = transaction.amount;
  _transactionController.category.value = transaction.category;
  _transactionController.contact.value = (contactName == null || contactName == '') ? null : Contact(name: contactName);
  _transactionController.amountController.value.text = (transaction.amount / 100).toStringAsFixed(2);

  BuildContext context = Get.context;
  await showModalBottomSheet<void>(
    backgroundColor: Colors.transparent,
    barrierColor: Color(0x22AF47FF),
    isScrollControlled: true,
    context: context,
    builder: (context) => Wrap(
      children: [
        IncomeForm(
          type: transaction.type,
          transaction: transaction,
        ),
      ],
    ),
  ).whenComplete(() => _transactionController.resetFieldValues());
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
            color: AppColors.PRIMARY,
            action: () => _transactionController.deleteTransaction(transaction),
          ),
          roundedButton(
            text: "NO",
            textColor: AppColors.PRIMARY,
            color: AppColors.SECONDARY,
            action: () => Get.back(),
          ),
        ],
      ),
    ),
  );
}
