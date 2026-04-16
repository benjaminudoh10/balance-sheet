import 'package:balance_sheet/constants/colors.dart';
import 'package:balance_sheet/controllers/currency_controller.dart';
import 'package:balance_sheet/controllers/budgetController.dart';
import 'package:balance_sheet/controllers/insights_controller.dart';
import 'package:balance_sheet/controllers/reportController.dart';
import 'package:balance_sheet/database/operations.dart' as db;
import 'package:balance_sheet/models/contact.dart';
import 'package:balance_sheet/models/transaction.dart';
import 'package:balance_sheet/enums.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TransactionController extends GetxController {
  RxBool addingTransaction = false.obs;
  RxString category = "savings".obs;
  RxString description = "".obs;
  var descController = TextEditingController().obs;

  RxInt amount = 0.obs;
  var amountController = TextEditingController(text: "0.00").obs;

  /// When true, the amount field is in FCY; [amount] stays LCY minor (canonical).
  final RxBool amountEntryIsFcy = false.obs;
  final RxInt entryAmountMinor = 0.obs;

  RxInt total = 0.obs;
  RxInt todaysExpense = 0.obs;
  RxInt todaysIncome = 0.obs;

  var transactions = <Transaction>[].obs;
  final Rxn<Contact> contact = Rxn<Contact>();

  /// When the income/expense sheet saves, this becomes [Transaction.date].
  final Rx<DateTime> entryDateTime = DateTime.now().obs;

  @override
  void onInit() {
    contact.value = Contact(name: '');
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
    loadHomeScreenData();
  }

  /// Balance card + "Recent transactions" read from SQLite (not only txs added this session).
  Future<void> loadHomeScreenData() async {
    await Future.wait<void>([
      getTotalBalance(),
      getTodaysBalance(),
    ]);
    final DateTime now = DateTime.now();
    final int start =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final int end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999)
        .millisecondsSinceEpoch;
    await getTransactions(start, end);
    if (Get.isRegistered<InsightsController>()) {
      Get.find<InsightsController>().load();
    }
    if (Get.isRegistered<BudgetController>()) {
      Get.find<BudgetController>().reloadFocusMonth();
    }
  }

  resetContact() {
    contact.value = Contact(name: "");
  }

  addTransaction(Transaction transaction) async {
    addingTransaction.value = true;
    int id;
    try {
      id = await db.addTransaction(transaction);
      addingTransaction.value = false;
    } catch (error) {
      print(error);
      addingTransaction.value = false;
      Get.snackbar(
        "Error",
        "Error occured while adding transaction",
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.SNACKBAR_RED,
      );
      return;
    }
    transaction.id = id;
    Get.back();

    await loadHomeScreenData();
    resetFieldValues();
  }

  updateTransaction(Transaction transaction, Transaction previousTransaction) async {
    final Transaction update = Transaction(
      id: previousTransaction.id,
      description: transaction.description,
      type: transaction.type,
      amount: transaction.amount,
      date: transaction.date,
      category: transaction.category,
      contactId: transaction.contactId,
      entryIsFcy: transaction.entryIsFcy,
      entryAmountMinor: transaction.entryAmountMinor,
    );

    await db.updateTransaction(update);
    await loadHomeScreenData();
    updateControllerDataAfterUpdate(update, previousTransaction);
    Get.back();
    Get.back();
    Get.snackbar(
      "Successful",
      "Transaction updated successfully",
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.GREEN,
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
      if (Get.isRegistered<InsightsController>()) {
        Get.find<InsightsController>().load();
      }
      if (Get.isRegistered<BudgetController>()) {
        Get.find<BudgetController>().reloadFocusMonth();
      }

      Get.snackbar(
        "Successful",
        "Transaction deleted successfully",
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.GREEN,
      );
    } else {
      Get.snackbar(
        "Not deleted",
        "This transaction has already been deleted. Close modal and reopen to get rid of it.",
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.SNACKBAR_RED,
      );
    }
  }

  getTransactions(int startMillisecond, int endMillisecond) async {
    transactions.value = await db.getAllTransactions(
      startMillisecond,
      endMillisecond,
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

  /// Updates in-memory totals after an add without reloading from SQLite (e.g. tests).
  void updateControllerData(Transaction transaction) {
    resetFieldValues();
    final DateTime now = DateTime.now();
    final DateTime beginningOfDay = DateTime(now.year, now.month, now.day);
    final bool onToday = transaction.date.year == beginningOfDay.year &&
        transaction.date.month == beginningOfDay.month &&
        transaction.date.day == beginningOfDay.day;
    if (transaction.type == TransactionType.expenditure) {
      if (onToday) todaysExpense.value += transaction.amount;
      total.value -= transaction.amount;
    } else {
      if (onToday) todaysIncome.value += transaction.amount;
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
    resetFieldValues();

    try {
      final ReportController _reportController = Get.find();

      final int index = _reportController.transactions.indexWhere(
        (txn) => txn.id == transaction.id,
      );
      if (index != -1) {
        _reportController.transactions[index] = transaction;
        if (transaction.type == TransactionType.expenditure) {
          _reportController.expense.value +=
              (transaction.amount - previousTransaction.amount);
        } else {
          _reportController.income.value +=
              (transaction.amount - previousTransaction.amount);
        }
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
    amountEntryIsFcy.value = false;
    entryAmountMinor.value = 0;
    entryDateTime.value = DateTime.now();
    resetContact();
  }

  /// Parses the amount field into minor units of the selected entry currency and updates [amount] (LCY).
  void applyAmountFieldText(String raw) {
    final String t = raw.trim();
    if (t.isEmpty || t == '.') {
      amount.value = 0;
      entryAmountMinor.value = 0;
      return;
    }
    final double? d = double.tryParse(t);
    if (d == null) {
      amount.value = 0;
      entryAmountMinor.value = 0;
      return;
    }
    final int minor = (d * 1000).floor() ~/ 10;
    entryAmountMinor.value = minor;
    final CurrencyController c = Get.find<CurrencyController>();
    if (amountEntryIsFcy.value) {
      amount.value = c.lcyMinorFromFcyMinor(minor);
    } else {
      amount.value = minor;
    }
  }

  void toggleAmountEntryCurrency() {
    final CurrencyController c = Get.find<CurrencyController>();
    final int curMinor = entryAmountMinor.value;
    if (amountEntryIsFcy.value) {
      final int lcy = c.lcyMinorFromFcyMinor(curMinor);
      amountEntryIsFcy.value = false;
      amount.value = lcy;
      entryAmountMinor.value = lcy;
      amountController.value.text = (lcy / 100).toStringAsFixed(2);
    } else {
      final int fcy = c.fcyMinorFromLcyMinor(curMinor);
      amountEntryIsFcy.value = true;
      amount.value = curMinor;
      entryAmountMinor.value = fcy;
      amountController.value.text = (fcy / 100).toStringAsFixed(2);
    }
  }
}
