import 'package:balance_sheet/controllers/reportController.dart';
import 'package:balance_sheet/database/operations.dart' as db;
import 'package:balance_sheet/models/transaction.dart';
import 'package:balance_sheet/enums.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TransactionController extends GetxController {
  RxBool addingTransaction = false.obs;
  RxString description = "".obs;
  var descController = TextEditingController().obs;

  RxInt amount = 0.obs;
  var amountController = TextEditingController(text: "0.00").obs;

  RxInt total = 0.obs;
  RxInt todaysExpense = 0.obs;
  RxInt todaysIncome = 0.obs;

  var transactions = [].obs;

  @override
  void onReady() {
    super.onReady();

    DateTime currentDate = DateTime.now();
    DateTime startOfToday = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );
    DateTime endOfToday = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
      23,
      59,
      59,
      999,
    );

    getTransactions(
      startOfToday.millisecondsSinceEpoch,
      endOfToday.millisecondsSinceEpoch,
    );
    getTotalBalance();
    getTodaysBalance();
  }

  addTransaction(Transaction transaction) async {
    addingTransaction.value = true;
    int id = await db.addTransaction(transaction);
    transaction.id = id;
    addingTransaction.value = false;
    Get.back();

    // update data in controller
    transactions.add(transaction);
    updateControllerData(transaction);
  }

  updateTransaction(Transaction transaction, Transaction previousTransaction) async {
    Transaction update = Transaction.fromJson({
      "id": previousTransaction.id,
      "type": previousTransaction.type == TransactionType.expenditure ? 'expenditure' : 'income',
      "amount": transaction.amount,
      "date": previousTransaction.date.millisecondsSinceEpoch,
      "description": transaction.description,
    });

    await db.updateTransaction(update);
    updateControllerDataAfterUpdate(update, previousTransaction);
    Get.back();
    Get.back();
    Get.snackbar(
      "Successful",
      "Transaction updated successfully",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Color(0xdd5DAC7F),
    );
  }

  deleteTransaction(Transaction transaction) async {
    var res = await db.deleteTransaction(transaction);
    Get.back();
    if (res == 1) {
      Get.back();

      // remove txn from UI
      transactions.value = transactions.where((txn) => transaction.id != txn.id).toList();
      updateControllerDataAfterDeletion(transaction);

      Get.snackbar(
        "Successful",
        "Transaction deleted successfully",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Color(0xdd5DAC7F),
      );
    } else {
      Get.snackbar(
        "Not deleted",
        "This transaction has already been deleted. Close modal and reopen to get rid of it.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Color(0x22FF0000),
      );
    }
  }

  getTransactions(int startMillisecond, int endMillisecond) async {
    transactions.value = await db.getAllTransactions(
      startMillisecond,
      endMillisecond
    );
  }

  getTotalBalance() async {
    total.value = await db.getBalances();
  }

  getTodaysBalance() async {
    Map<String, dynamic> todaysData = await db.getTodayBalances();
    todaysExpense.value = todaysData['expenses'] ?? 0;
    todaysIncome.value = todaysData['income'] ?? 0;
  }

  updateControllerData(Transaction transaction) {
    resetFieldValues();
    if (transaction.type == TransactionType.expenditure) {
      todaysExpense.value += transaction.amount;
      total.value -= transaction.amount;
    } else {
      todaysIncome.value += transaction.amount;
      total.value += transaction.amount;
    }
  }

  updateControllerDataAfterDeletion(Transaction transaction) {
    DateTime now = DateTime.now();
    DateTime beginningOfDay = DateTime(now.year, now.month, now.day);
    if (transaction.type == TransactionType.expenditure) {
      if (transaction.date.year == beginningOfDay.year &&
        transaction.date.month == beginningOfDay.month &&
        transaction.date.day == beginningOfDay.day) {
        todaysExpense.value -= transaction.amount;
      }
      total.value += transaction.amount;
    } else {
      if (transaction.date.year == beginningOfDay.year &&
        transaction.date.month == beginningOfDay.month &&
        transaction.date.day == beginningOfDay.day) {
        todaysIncome.value -= transaction.amount;
      }
      total.value -= transaction.amount;
    }

    try {
      ReportController _reportController = Get.find();

      _reportController.transactions.value = _reportController.transactions.where(
        (txn) => transaction.id != txn.id
      ).toList();
      if (transaction.type == TransactionType.expenditure) {
        _reportController.expense.value -= transaction.amount;
      } else {
        _reportController.income.value -= transaction.amount;
      }
    } catch (error) {
      print('$error');
    }
  }

  updateControllerDataAfterUpdate(Transaction transaction, Transaction previousTransaction) {
    DateTime now = DateTime.now();
    DateTime beginningOfDay = DateTime(now.year, now.month, now.day);
    
    int index = transactions.indexWhere((txn) => txn.id == previousTransaction.id);
    if (index != -1) transactions[index] = transaction;

    resetFieldValues();
    if (transaction.type == TransactionType.expenditure) {
      if (transaction.date.year == beginningOfDay.year &&
        transaction.date.month == beginningOfDay.month &&
        transaction.date.day == beginningOfDay.day) {
        todaysExpense.value -= previousTransaction.amount;
        todaysExpense.value += transaction.amount;
      }

      total.value += previousTransaction.amount;
      total.value -= transaction.amount;
    } else {
      if (transaction.date.year == beginningOfDay.year &&
        transaction.date.month == beginningOfDay.month &&
        transaction.date.day == beginningOfDay.day) {
        todaysIncome.value -= previousTransaction.amount;
        todaysIncome.value += transaction.amount;
      }

      total.value -= previousTransaction.amount;
      total.value += transaction.amount;
    }

    try {
      ReportController _reportController = Get.find();

      int index = _reportController.transactions.indexWhere(
        (txn) => txn.id == transaction.id
      );
      _reportController.transactions[index] = transaction;
      if (transaction.type == TransactionType.expenditure) {
        _reportController.expense.value += (transaction.amount - previousTransaction.amount);
      } else {
        _reportController.income.value += (transaction.amount - previousTransaction.amount);
      }
    } catch (error) {
      print('$error');
    }
  }

  resetFieldValues() {
    description.value = "";
    descController.value.text = "";
    amount.value = 0;
    amountController.value.text = "0.00";
  }
}
