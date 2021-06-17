import 'package:balance_sheet/controllers/transactionController.dart';
import 'package:balance_sheet/models/transaction.dart';
import 'package:balance_sheet/screens/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';

class IncomeForm extends StatelessWidget {
  IncomeForm({this.type, this.transaction});

  final TransactionType type;
  final Transaction transaction;
  final TransactionController _transactionController = Get.find();

  @override
  Widget build(BuildContext context) {
    _transactionController.description.value = this.transaction?.description;
    _transactionController.amount.value = this.transaction != null ? this.transaction.amount / 100 : null;

    return Obx(() => Container(
      padding: EdgeInsets.all(20.0),
      height: Get.height * 0.4,
      decoration: new BoxDecoration(
        color: Color(0xFFAF47FF),
        borderRadius: new BorderRadius.only(
          topLeft: const Radius.circular(25.0),
          topRight: const Radius.circular(25.0),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 15.0),
            child: Text(
              "${this.transaction != null ? 'Update' : 'Add'} ${this.type == TransactionType.income ? 'Income' : 'Expenditure'}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
                color: Colors.white,
              ),
            ),
          ),
          Form(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Item description",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                _buildTextField(
                  placeholder: "e.g. Tomatoes",
                  defaultValue: _transactionController.description.value,
                  type: "description",
                ),
                Text(
                  "Amount (₦)",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                _buildTextField(
                  placeholder: "0.00",
                  defaultValue: "${_transactionController.amount.value ?? ''}",
                  // keyboardType: TextInputType.numberWithOptions(decimal: true),
                  formatters: [FilteringTextInputFormatter.allow(RegExp("[0-9.]"))],
                  type: "amount",
                ),
                GestureDetector(
                  onTap: () async {
                    if (!validInput()) {
                      Get.snackbar(
                        "Error",
                        "All fields are required",
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.white,
                      );
                      return;
                    }

                    Transaction transaction = Transaction(
                      description: _transactionController.description.value,
                      type: this.type,
                      amount: (_transactionController.amount.value * 100).toInt(),
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
                      color: validInput() ? Color(0xaa5DAC7F) : Color(0xaaAF47FF),
                      boxShadow: [
                        BoxShadow()
                      ]
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

  Widget _buildTextField({String placeholder, String defaultValue, TextInputType keyboardType, var formatters, String type}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(10.0),
        color: Color(0x33ffffff),
      ),
      margin: EdgeInsets.symmetric(
        vertical: 10.0,
      ),
      child: TextFormField(
        decoration: InputDecoration(
          contentPadding: EdgeInsets.all(10.0),
          hintText: placeholder,
          hintStyle: TextStyle(
            fontSize: 14.0,
            color: Color(0x88ffffff),
          ),
          border: InputBorder.none,
        ),
        textCapitalization: TextCapitalization.sentences,
        style: TextStyle(
          color: Colors.white,
        ),
        cursorColor: Colors.white,
        // autofocus: autofocus,
        enableSuggestions: true,
        initialValue: defaultValue,
        keyboardType: TextInputType.text,
        inputFormatters: formatters,
        onChanged: (value) {
          if (type == 'description') {
            _transactionController.description.value = value;
          } else {
            if (value != "") {
              _transactionController.amount.value = double.parse(value);
            } else {
              _transactionController.amount.value = 0.00;
            }
          }
        },
      ),
    );
  }
}
