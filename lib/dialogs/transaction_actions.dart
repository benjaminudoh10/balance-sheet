import 'package:balance_sheet/controllers/contact_controller.dart';
import 'package:balance_sheet/controllers/transaction_controller.dart';
import 'package:balance_sheet/models/contact.dart';
import 'package:balance_sheet/models/transaction.dart';
import 'package:balance_sheet/screens/new_income_form.dart';
import 'package:balance_sheet/theme/app_palette.dart';
import 'package:balance_sheet/utils/app_haptics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Future<void> showEditModal(Transaction transaction, String contactName) async {
  final TransactionController transactionController = Get.find();
  transactionController.description.value = transaction.description;
  transactionController.descController.value.text = transaction.description;
  transactionController.amount.value = transaction.amount;
  transactionController.amountEntryIsFcy.value = transaction.entryIsFcy;
  transactionController.entryAmountMinor.value = transaction.entryAmountMinor;
  transactionController.category.value = transaction.category;

  // Must preserve contact id so save keeps contactId; name-only Contact() had id 0 and cleared DB.
  if (transaction.contactId > 0) {
    final ContactController contactController = Get.find();
    Contact? match;
    for (final Contact c in contactController.contacts) {
      if (c.id == transaction.contactId) {
        match = c;
        break;
      }
    }
    transactionController.contact.value = match ??
        Contact(
          id: transaction.contactId,
          name: contactName.isNotEmpty ? contactName : 'Contact',
        );
  } else {
    transactionController.contact.value = null;
  }
  if (transaction.entryIsFcy) {
    transactionController.amountController.value.text =
        (transaction.entryAmountMinor / 100).toStringAsFixed(2);
  } else {
    transactionController.amountController.value.text =
        (transaction.amount / 100).toStringAsFixed(2);
  }
  transactionController.entryDateTime.value = transaction.date;
  transactionController
      .applyAmountFieldText(transactionController.amountController.value.text);

  final BuildContext context = Get.context!;
  final AppPalette p = AppPalette.of(context);
  await showModalBottomSheet<void>(
    backgroundColor: Colors.transparent,
    barrierColor: p.overlay,
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
    barrierColor: AppPalette.of(context).overlay,
    isScrollControlled: true,
    context: context,
    builder: (context) {
      final AppPalette p = AppPalette.of(context);
      final double inset = MediaQuery.viewInsetsOf(context).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: inset),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: BoxDecoration(
            color: p.surfaceElevated,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: p.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to delete this transaction?',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: p.textPrimary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: p.coral,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    AppHaptics.medium();
                    transactionController.deleteTransaction(transaction);
                  },
                  child: Text(
                    'YES',
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: p.mint,
                    backgroundColor: p.surface,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: p.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    AppHaptics.light();
                    Get.back();
                  },
                  child: Text(
                    'NO',
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: p.mint,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void showMultiDeleteModal(VoidCallback onDelete) {
  final BuildContext context = Get.context!;

  showModalBottomSheet<void>(
    backgroundColor: Colors.transparent,
    barrierColor: AppPalette.of(context).overlay,
    isScrollControlled: true,
    context: context,
    builder: (context) {
      final AppPalette p = AppPalette.of(context);
      final double inset = MediaQuery.viewInsetsOf(context).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: inset),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: BoxDecoration(
            color: p.surfaceElevated,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: p.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to delete these transactions?',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: p.textPrimary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: p.coral,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    AppHaptics.medium();
                    onDelete();
                    Get.back();
                  },
                  child: Text(
                    'YES',
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: p.mint,
                    backgroundColor: p.surface,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: p.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    AppHaptics.light();
                    Get.back();
                  },
                  child: Text(
                    'NO',
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: p.mint,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
