import 'package:balance_sheet/constants/midnight_theme.dart';
import 'package:balance_sheet/controllers/transactionController.dart';
import 'package:balance_sheet/models/contact.dart';
import 'package:balance_sheet/models/transaction.dart';
import 'package:balance_sheet/screens/new_income_form.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Future<void> showEditModal(Transaction transaction, String contactName) async {
  final TransactionController transactionController = Get.find();
  transactionController.description.value = transaction.description;
  transactionController.descController.value.text = transaction.description;
  transactionController.amount.value = transaction.amount;
  transactionController.category.value = transaction.category;
  transactionController.contact.value =
      contactName.isEmpty ? null : Contact(name: contactName);
  transactionController.amountController.value.text =
      (transaction.amount / 100).toStringAsFixed(2);

  final BuildContext context = Get.context!;
  await showModalBottomSheet<void>(
    backgroundColor: Colors.transparent,
    barrierColor: MidnightTheme.overlay,
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
  ).whenComplete(transactionController.resetFieldValues);
}

void showDeleteModal(Transaction transaction) {
  final BuildContext context = Get.context!;
  final TransactionController transactionController = Get.find();

  showModalBottomSheet<void>(
    backgroundColor: Colors.transparent,
    barrierColor: MidnightTheme.overlay,
    context: context,
    builder: (context) => Container(
      height: 300.0,
      padding: const EdgeInsets.all(45.0),
      decoration: BoxDecoration(
        color: MidnightTheme.surfaceElevated,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25.0),
          topRight: Radius.circular(25.0),
        ),
        border: Border.all(color: MidnightTheme.border),
      ),
      child: Column(
        children: [
          const Text(
            'Are you sure you want to delete this transaction?',
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: MidnightTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: MidnightTheme.coral,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () =>
                  transactionController.deleteTransaction(transaction),
              child: const Text(
                'YES',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: MidnightTheme.mint,
                backgroundColor: MidnightTheme.surface,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: MidnightTheme.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () => Get.back(),
              child: const Text(
                'NO',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
