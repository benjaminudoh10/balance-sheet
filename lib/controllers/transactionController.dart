import 'package:balance_sheet/database/operations.dart' as db;
import 'package:balance_sheet/models/transaction.dart';
import 'package:balance_sheet/screens/enums.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TransactionController extends GetxController {
  RxBool addingTransaction = false.obs;
  RxString description = "".obs;
  RxDouble amount = 0.0.obs;

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
      backgroundColor: Color(0x22AF47FF),
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
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0x22AF47FF),
      );
    } else {
      Get.snackbar(
        "Not deleted",
        "Error occured while deleting transaction",
        snackPosition: SnackPosition.BOTTOM,
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
    if (transaction.type == TransactionType.expenditure) {
      todaysExpense.value += transaction.amount;
      total.value -= transaction.amount;
    } else {
      todaysIncome.value += transaction.amount;
      total.value += transaction.amount;
    }
  }

  updateControllerDataAfterDeletion(Transaction transaction) {
    if (transaction.type == TransactionType.expenditure) {
      todaysExpense.value -= transaction.amount;
      total.value += transaction.amount;
    } else {
      todaysIncome.value -= transaction.amount;
      total.value -= transaction.amount;
    }
  }

  updateControllerDataAfterUpdate(Transaction transaction, Transaction previousTransaction) {
    int index = transactions.indexWhere((txn) => txn.id == previousTransaction.id);
    transactions[index] = transaction;
    if (transaction.type == TransactionType.expenditure) {
      // delete previous data and add new transaction data
      todaysExpense.value -= previousTransaction.amount;
      todaysExpense.value += transaction.amount;

      total.value += previousTransaction.amount;
      total.value -= transaction.amount;
    } else {
      todaysIncome.value -= previousTransaction.amount;
      todaysIncome.value += transaction.amount;

      total.value -= previousTransaction.amount;
      total.value += transaction.amount;
    }
  }
}
