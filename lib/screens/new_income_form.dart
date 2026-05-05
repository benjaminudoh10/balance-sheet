import 'package:balance_sheet/theme/app_palette.dart';
import 'package:balance_sheet/utils/app_haptics.dart';
import 'package:balance_sheet/controllers/currency_controller.dart';
import 'package:balance_sheet/controllers/transaction_controller.dart';
import 'package:balance_sheet/dialogs/contact.dart';
import 'package:balance_sheet/models/transaction.dart';
import 'package:balance_sheet/enums.dart';
import 'package:balance_sheet/widgets/date_range_picker_sheet.dart';
import 'package:balance_sheet/widgets/inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Field labels in the income/expense sheet — caps, uses theme scale.
TextStyle _fieldLabelStyle(TextTheme textTheme, AppPalette p) =>
    textTheme.labelMedium!.copyWith(
      letterSpacing: 1.15,
      height: 1.2,
      color: p.textPrimary.withValues(alpha: 0.88),
    );

Future<void> _pickEntryDateTime(
  BuildContext context,
  TransactionController controller,
) async {
  final DateTime initial = controller.entryDateTime.value;
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime? date = await showAppDatePicker(
    context,
    initialDate: initial.isAfter(today) ? today : initial,
    firstDate: DateTime(2000),
    lastDate: today,
  );
  if (date == null || !context.mounted) return;
  final TimeOfDay? time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
    // The stock input-entry mode can assert on compact heights because Flutter
    // hard-codes a 216px min height even when the route allows less.
    initialEntryMode: TimePickerEntryMode.dialOnly,
  );
  if (!context.mounted) return;
  final TimeOfDay effective = time ?? TimeOfDay.fromDateTime(initial);
  controller.entryDateTime.value = DateTime(
    date.year,
    date.month,
    date.day,
    effective.hour,
    effective.minute,
  );
}

class _EntryDateTimeField extends StatelessWidget {
  const _EntryDateTimeField({
    required this.accent,
    required this.controller,
    required this.onPick,
  });

  final Color accent;
  final TransactionController controller;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(10.0),
        color: p.surface,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: AppHaptics.wrap(onPick),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(Icons.schedule_rounded, color: accent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Obx(
                    () => Text(
                      DateFormat('EEE, MMM d, y • h:mm a')
                          .format(controller.entryDateTime.value),
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: p.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: p.textSecondary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class IncomeForm extends StatelessWidget {
  IncomeForm({super.key, required this.type, this.transaction});

  final TransactionType type;
  final Transaction? transaction;
  final TransactionController _transactionController = Get.find();

  bool get _isIncome => type == TransactionType.income;

  String get _verb => transaction != null ? 'Update' : 'Add';

  String get _typeLabel => _isIncome ? 'Income' : 'Expense';

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final Color accent = _isIncome ? p.mint : p.coral;
    final double insetBottom = MediaQuery.viewInsetsOf(context).bottom;
    final double maxSheetHeight = MediaQuery.sizeOf(context).height * 0.92;

    return Obx(() => Padding(
          padding: EdgeInsets.only(bottom: insetBottom),
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            constraints: BoxConstraints(maxHeight: maxSheetHeight),
            decoration: BoxDecoration(
              color: p.surfaceElevated,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: p.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 6),
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
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: accent.withValues(alpha: 0.12),
                            border: Border.all(
                                color: accent.withValues(alpha: 0.28)),
                          ),
                          child: Icon(
                            _isIncome
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            color: accent,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$_verb $_typeLabel',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall!
                                    .copyWith(
                                      color: p.textPrimary,
                                      letterSpacing: -0.4,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                transaction != null
                                    ? 'Edit the details below.'
                                    : 'Add amount, category, and when it occurred.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      height: 1.35,
                                      color: p.textSecondary
                                          .withValues(alpha: 0.9),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            AppHaptics.light();
                            Get.back();
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: p.surface,
                            foregroundColor: p.textSecondary,
                            padding: const EdgeInsets.all(8),
                            minimumSize: const Size(40, 40),
                          ),
                          icon: const Icon(Icons.close_rounded, size: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _FormSection(
                      label: 'Description',
                      child: DescriptionInput(compact: true),
                    ),
                    Obx(() {
                      final String code =
                          _transactionController.amountEntryIsFcy.value
                              ? Get.find<CurrencyController>().fcyCode.value
                              : Get.find<CurrencyController>().lcyCode.value;
                      return _FormSection(
                        label: 'Amount ($code)',
                        labelTrailing: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: TransactionAmountCurrencySelector(
                              isIncome: _isIncome),
                        ),
                        child: AmountInput(compact: true, isIncome: _isIncome),
                      );
                    }),
                    _FormSection(
                      label: 'Date & time',
                      child: _EntryDateTimeField(
                        accent: accent,
                        controller: _transactionController,
                        onPick: () => _pickEntryDateTime(
                          context,
                          _transactionController,
                        ),
                      ),
                    ),
                    _CategoryAndContactBlock(
                      accent: accent,
                      contactName: _transactionController.contact.value?.name,
                      onClearContact: () =>
                          _transactionController.resetContact(),
                      contactTap: () => showContactPickerSheet(
                        context,
                        controller: _transactionController,
                        popUnderlyingSheetWhenAddingContact: true,
                      ),
                      categoryChild: CategoryInput(compact: true),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: Material(
                        color: validInput() ? accent : p.surfaceElevated,
                        borderRadius: BorderRadius.circular(26),
                        child: InkWell(
                          onTap: () async {
                            AppHaptics.light();
                            if (!validInput()) {
                              Get.snackbar(
                                'Error',
                                'All fields are required',
                                colorText: p.textPrimary,
                                snackPosition: SnackPosition.TOP,
                                backgroundColor: p.coral.withValues(alpha: 0.9),
                              );
                              return;
                            }

                            final bool isFcy =
                                _transactionController.amountEntryIsFcy.value;
                            final int entryMinor = isFcy
                                ? _transactionController.entryAmountMinor.value
                                : _transactionController.amount.value;
                            final Transaction tx = Transaction(
                              description:
                                  _transactionController.description.value,
                              type: type,
                              amount: _transactionController.amount.value,
                              category: _transactionController.category.value,
                              contactId:
                                  _transactionController.contact.value?.id ?? 0,
                              date: _transactionController.entryDateTime.value,
                              entryIsFcy: isFcy,
                              entryAmountMinor: entryMinor,
                            );
                            if (transaction != null) {
                              await _transactionController.updateTransaction(
                                tx,
                                transaction!,
                              );
                            } else {
                              await _transactionController.addTransaction(tx);
                            }
                          },
                          borderRadius: BorderRadius.circular(26),
                          child: Center(
                            child:
                                _transactionController.addingTransaction.value
                                    ? SpinKitThreeBounce(
                                        color: validInput()
                                            ? (_isIncome
                                                ? Colors.black87
                                                : Colors.white)
                                            : p.textSecondary,
                                        size: 20,
                                      )
                                    : Text(
                                        '$_verb $_typeLabel',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge!
                                            .copyWith(
                                              color: validInput()
                                                  ? (_isIncome
                                                      ? Colors.black87
                                                      : Colors.white)
                                                  : p.textSecondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }

  bool validInput() {
    return _transactionController.description.value != '' &&
        _transactionController.amount.value > 0;
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.label,
    required this.child,
    this.labelTrailing,
  });

  final String label;
  final Widget child;
  final Widget? labelTrailing;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _fieldLabelStyle(Theme.of(context).textTheme, p),
                ),
              ),
              if (labelTrailing != null) labelTrailing!,
            ],
          ),
          const SizedBox(height: 3),
          child,
        ],
      ),
    );
  }
}

class _CategoryAndContactBlock extends StatelessWidget {
  const _CategoryAndContactBlock({
    required this.accent,
    required this.contactName,
    required this.onClearContact,
    required this.contactTap,
    required this.categoryChild,
  });

  final Color accent;
  final String? contactName;
  final VoidCallback onClearContact;
  final VoidCallback contactTap;
  final Widget categoryChild;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final bool hasContact =
        contactName != null && contactName!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'CATEGORY',
                style: _fieldLabelStyle(Theme.of(context).textTheme, p),
              ),
              if (hasContact)
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _ContactChip(
                      accent: accent,
                      name: contactName!,
                      onClear: onClearContact,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: categoryChild,
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 50,
                height: 50,
                child: Material(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: contactTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: p.border),
                      ),
                      child: Icon(
                        Icons.contacts_rounded,
                        color: accent,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactChip extends StatelessWidget {
  const _ContactChip({
    required this.accent,
    required this.name,
    required this.onClear,
  });

  final Color accent;
  final String name;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.person_outline_rounded,
          size: 16,
          color: accent.withValues(alpha: 0.9),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            name,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: p.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: AppHaptics.wrap(onClear),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: p.border.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.close_rounded,
              size: 14,
              color: p.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
