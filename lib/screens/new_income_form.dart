import 'package:balance_sheet/theme/app_palette.dart';
import 'package:balance_sheet/controllers/transactionController.dart';
import 'package:balance_sheet/dialogs/contact.dart';
import 'package:balance_sheet/models/transaction.dart';
import 'package:balance_sheet/enums.dart';
import 'package:balance_sheet/widgets/inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Field labels in the income/expense sheet — caps, uses theme scale.
TextStyle _fieldLabelStyle(TextTheme textTheme, AppPalette p) => textTheme.labelMedium!.copyWith(
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
  final DateTime? date = await showDatePicker(
    context: context,
    initialDate: initial.isAfter(today) ? today : initial,
    firstDate: DateTime(2000),
    lastDate: today,
  );
  if (date == null || !context.mounted) return;
  final TimeOfDay? time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
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
          onTap: onPick,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
  IncomeForm({required this.type, this.transaction});

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
    final double keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;
    final double maxSheetHeight = MediaQuery.sizeOf(context).height * 0.92;

    return Obx(() => ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxSheetHeight),
          child: Container(
            decoration: BoxDecoration(
              color: p.background,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: p.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + keyboardBottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: accent.withValues(alpha: 0.12),
                            border: Border.all(color: accent.withValues(alpha: 0.28)),
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
                                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                                  color: p.textPrimary,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                transaction != null
                                    ? 'Edit the details below.'
                                    : 'Add amount, category, and when it occurred.',
                                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  height: 1.35,
                                  color: p.textSecondary.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Get.back(),
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
                    const SizedBox(height: 24),
                    _FormSection(
                      label: 'Description',
                      child: DescriptionInput(compact: true),
                    ),
                    _FormSection(
                      label: 'Amount (₦)',
                      child: AmountInput(compact: true),
                    ),
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
                      contactName: _transactionController.contact.value?.name,
                      onClearContact: () => _transactionController.resetContact(),
                      contactTap: () => showContactPickerSheet(
                        context,
                        controller: _transactionController,
                        popUnderlyingSheetWhenAddingContact: true,
                      ),
                      categoryChild: CategoryInput(compact: true),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: Material(
                        color: validInput()
                            ? accent
                            : p.surfaceElevated,
                        borderRadius: BorderRadius.circular(26),
                        child: InkWell(
                          onTap: () async {
                            if (!validInput()) {
                              Get.snackbar(
                                'Error',
                                'All fields are required',
                                colorText: p.textPrimary,
                                snackPosition: SnackPosition.TOP,
                                backgroundColor:
                                    p.coral.withValues(alpha: 0.9),
                              );
                              return;
                            }

                            final Transaction tx = Transaction(
                              description: _transactionController.description.value,
                              type: type,
                              amount: _transactionController.amount.value,
                              category: _transactionController.category.value,
                              contactId:
                                  _transactionController.contact.value?.id ?? 0,
                              date: _transactionController.entryDateTime.value,
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
                            child: _transactionController.addingTransaction.value
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
                                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
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
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label.toUpperCase(),
            style: _fieldLabelStyle(Theme.of(context).textTheme, p),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class _CategoryAndContactBlock extends StatelessWidget {
  const _CategoryAndContactBlock({
    required this.contactName,
    required this.onClearContact,
    required this.contactTap,
    required this.categoryChild,
  });

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
      padding: const EdgeInsets.only(bottom: 18),
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
                      name: contactName!,
                      onClear: onClearContact,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
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
                        color: p.mint,
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
  const _ContactChip({required this.name, required this.onClear});

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
          color: p.mint.withValues(alpha: 0.9),
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
          onTap: onClear,
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
