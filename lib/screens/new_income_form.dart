import 'package:balance_sheet/constants/colors.dart';
import 'package:balance_sheet/controllers/organizationController.dart';
import 'package:balance_sheet/controllers/transactionController.dart';
import 'package:balance_sheet/dialogs/category.dart';
import 'package:balance_sheet/dialogs/contact.dart';
import 'package:balance_sheet/models/transaction.dart';
import 'package:balance_sheet/enums.dart';
import 'package:balance_sheet/widgets/inputs.dart';
import 'package:balance_sheet/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';

class IncomeForm extends StatelessWidget {
  IncomeForm({this.type, this.transaction});

  final TransactionType type;
  final Transaction transaction;
  final TransactionController _transactionController = Get.find();
  final OrganizationController _organizationController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
      padding: EdgeInsets.all(20.0),
      decoration: new BoxDecoration(
        color: AppColors.PRIMARY,
        borderRadius: new BorderRadius.only(
          topLeft: const Radius.circular(25.0),
          topRight: const Radius.circular(25.0),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 10.0,
              horizontal: 30.0,
            ),
            margin: EdgeInsets.only(bottom: 7.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
              color: AppColors.LIGHT_3_GREY,
            ),
            child: Text(
              "${this.transaction != null ? 'Update' : 'Add'} ${this.type == TransactionType.income ? 'Income' : 'Expenditure'}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
                color: Colors.white,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Item description",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              DescriptionInput(),
              Text(
                "Amount (???)",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              AmountInput(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Category",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 15.0),
                  if (_transactionController.contact.value?.name != "" && _transactionController.contact.value?.name != null) Flexible(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.contacts,
                          color: Colors.white,
                          size: 12.0,
                        ),
                        SizedBox(width: 5.0),
                        Flexible(
                          child: Text(
                            _transactionController.contact.value?.name ?? '',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 5.0),
                        GestureDetector(
                          onTap: () => _transactionController.resetContact(),
                          child: roundedWidget(
                            widget: Icon(
                              Icons.close,
                              size: 14.0,
                              color: Colors.white,
                            ),
                            containerColor: Color(0x44ffffff),
                            padding: EdgeInsets.all(3.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Get.dialog(
                        CategoryDialog(
                          controller: _transactionController,
                        ),
                      ),
                      child: CategoryInput(),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 15.0),
                    child: GestureDetector(
                      onTap: () => Get.dialog(
                        ContactDialog(
                          controller: _transactionController,
                        ),
                      ),
                      child: Icon(
                        Icons.contacts,
                        color: Colors.white,
                      ),
                    ),
                  )
                ],
              ),
              GestureDetector(
                onTap: () async {
                  if (!validInput()) {
                    Get.snackbar(
                      "Error",
                      "All fields are required",
                      colorText: Colors.white,
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: AppColors.SNACKBAR_RED,
                    );
                    return;
                  }

                  Transaction transaction = Transaction(
                    description: _transactionController.description.value,
                    type: this.type,
                    amount: _transactionController.amount.value,
                    category: _transactionController.category.value,
                    contactId: _transactionController.contact.value.id,
                    organizationId: _organizationController.organization.value.id,
                    date: DateTime.now(),
                  );
                  if (this.transaction != null) {
                    await _transactionController.updateTransaction(
                      transaction,
                      this.transaction,
                    );
                  } else {
                    await _transactionController.addTransaction(transaction);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: validInput() ? AppColors.GREEN : Color(0xAAAF47FF),
                    boxShadow: [BoxShadow()]
                  ),
                  margin: EdgeInsets.symmetric(vertical: 10.0),
                  padding: EdgeInsets.symmetric(
                    vertical: 15.0,
                    horizontal: 20.0
                  ),
                  child: Center(
                    child: _transactionController.addingTransaction.value
                      ? const SpinKitThreeBounce(
                          color: Colors.white,
                          size: 20.0,
                        )
                      : Text(
                          "${this.transaction != null ? 'Update' : 'Add'} ${this.type == TransactionType.income ? 'Income' : 'Expenditure'}",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.0,
                          ),
                        ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SizedBox(),
          ),
        ],
      ),
    ));
  }

  bool validInput() {
    return _transactionController.description.value != null &&
        _transactionController.description.value != "" &&
        _transactionController.amount.value != null &&
        _transactionController.amount.value > 0;
  }
}
