import 'package:balance_sheet/constants/category.dart';
import 'package:balance_sheet/controllers/currency_controller.dart';
import 'package:balance_sheet/database/operations.dart' as db_ops;
import 'package:balance_sheet/dialogs/transaction_actions.dart';
import 'package:balance_sheet/enums.dart';
import 'package:balance_sheet/models/transaction.dart';
import 'package:balance_sheet/theme/app_palette.dart';
import 'package:balance_sheet/utils.dart';
import 'package:balance_sheet/utils/app_haptics.dart';
import 'package:balance_sheet/widgets/category_pill_label.dart';
import 'package:balance_sheet/widgets/midnight_grid_painter.dart';
import 'package:balance_sheet/widgets/tag_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class TransactionDetailScreen extends StatefulWidget {
  final Transaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late final Rx<Transaction> _transaction;

  @override
  void initState() {
    super.initState();
    _transaction = widget.transaction.obs;
  }

  Future<void> _reloadTransaction() async {
    final updated = await db_ops.getTransactionById(_transaction.value.id);
    if (updated != null) {
      _transaction.value = updated;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Obx(() {
      final tx = _transaction.value;
      final bool isIncome = tx.type == TransactionType.income;
      final Color accent = isIncome ? p.mint : p.coral;

      return Scaffold(
        backgroundColor: p.background,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: p.textPrimary,
            onPressed: () {
              AppHaptics.light();
              Get.back();
            },
          ),
          title: Text(
            'Transaction Details',
            style: textTheme.headlineSmall!.copyWith(
              color: p.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.edit_rounded, color: p.textPrimary),
              onPressed: () {
                AppHaptics.light();
                showEditModal(
                  tx,
                  getContactNameForTransaction(tx),
                ).then((_) {
                  // Re-fetch or pass updated transaction back?
                  // Since showEditModal calls loadHomeScreenData, but doesn't return the new transaction,
                  // we might need to rely on the controller or re-fetching.
                  // Actually, let's update the _transaction state if possible.
                  // A simpler approach: reload the transaction from DB.
                  _reloadTransaction();
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: p.coral),
              onPressed: () {
                AppHaptics.heavy();
                showDeleteModal(tx, onDeleted: () => Get.back());
              },
            ),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: MidnightGridPainter(
                    heightFraction: 1.0, gridLineColor: p.gridLine),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AmountHeader(transaction: tx, accent: accent),
                    const SizedBox(height: 32),
                    _DetailRow(
                      label: 'Description',
                      value: tx.description,
                      icon: Icons.description_outlined,
                    ),
                    const SizedBox(height: 20),
                    _DetailRow(
                      label: 'Category',
                      value: _categoryLabel(tx.category),
                      icon: Categories.iconForKey(tx.category),
                      trailing: CategoryPillLabel(
                        categoryKey: tx.category,
                        label: _categoryLabel(tx.category),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _DetailRow(
                      label: 'Contact',
                      value: getContactNameForTransaction(tx),
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 20),
                    _DetailRow(
                      label: 'Date',
                      value: DateFormat('EEEE, MMM d, yyyy').format(tx.date),
                      icon: Icons.calendar_today_outlined,
                    ),
                    const SizedBox(height: 20),
                    _DetailRow(
                      label: 'Time',
                      value: DateFormat.jm().format(tx.date),
                      icon: Icons.access_time_rounded,
                    ),
                    const SizedBox(height: 32),
                    _TagsSection(
                      transaction: tx,
                      onManageTags: () => _showTagSelector(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _showTagSelector(BuildContext context) {
    showModalBottomSheet<void>(
      backgroundColor: Colors.transparent,
      barrierColor: AppPalette.of(context).overlay,
      isScrollControlled: true,
      context: context,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: TagSelector(
          transaction: _transaction,
        ),
      ),
    );
  }

  String _categoryLabel(String key) {
    final matches =
        Categories.CATEGORIES.where((c) => c['key'] == key).toList();
    if (matches.isEmpty) return 'Misc';
    return matches[0]['label']!;
  }
}

class _AmountHeader extends StatelessWidget {
  final Transaction transaction;
  final Color accent;

  const _AmountHeader({required this.transaction, required this.accent});

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final CurrencyController c = Get.find();
    final bool showDual = c.showDualTotals;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            transaction.type == TransactionType.income ? 'INCOME' : 'EXPENSE',
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: p.textSecondary,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            formatMinorUnits(transaction.amount, c.lcyCode.value),
            style: Theme.of(context).textTheme.displayMedium!.copyWith(
                  color: p.textPrimary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1.0,
                ),
          ),
          if (showDual || transaction.entryIsFcy) ...[
            const SizedBox(height: 8),
            Text(
              transaction.entryIsFcy
                  ? formatMinorUnits(
                      transaction.entryAmountMinor, c.fcyCode.value)
                  : '≈ ${formatMinorUnits(c.fcyMinorFromLcyMinor(transaction.amount), c.fcyCode.value)}',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: p.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Widget? trailing;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: p.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: p.border),
          ),
          child: Icon(icon, color: p.mint, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: p.textSecondary,
                      letterSpacing: 0.5,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value.isEmpty ? 'None' : value,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: p.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _TagsSection extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onManageTags;

  const _TagsSection({required this.transaction, required this.onManageTags});

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TAGS',
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: p.textSecondary,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton.icon(
              onPressed: onManageTags,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Manage'),
              style: TextButton.styleFrom(
                foregroundColor: p.mint,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (transaction.tags.isEmpty)
          Text(
            'No tags added yet.',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: p.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                transaction.tags.map((tag) => _TagChip(tag: tag)).toList(),
          ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final dynamic tag; // Temporarily dynamic until model is fully integrated

  const _TagChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: p.mint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.mint.withValues(alpha: 0.3)),
      ),
      child: Text(
        tag.name,
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: p.mint,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
