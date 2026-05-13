import 'dart:ui' show ImageFilter;

import 'package:balance_sheet/constants/app.dart';
import 'package:balance_sheet/constants/category.dart';
import 'package:balance_sheet/database/operations.dart' as db_ops;
import 'package:balance_sheet/theme/app_palette.dart';
import 'package:balance_sheet/dialogs/transaction_actions.dart';
import 'package:balance_sheet/models/transaction.dart';
import 'package:balance_sheet/enums.dart';
import 'package:balance_sheet/screens/transaction_detail_screen.dart';
import 'package:balance_sheet/utils.dart';
import 'package:balance_sheet/utils/app_haptics.dart';
import 'package:balance_sheet/widgets/category_pill_label.dart';
import 'package:balance_sheet/widgets/slidable_peek_hint.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

String _categoryLabelForTransaction(Transaction transaction) {
  final matches = Categories.CATEGORIES
      .where(
        (c) => c['key'] == transaction.category,
      )
      .toList();
  if (matches.isEmpty) return '';
  return matches[0]['label']!;
}

void _openEditModalFor(Transaction transaction) {
  showEditModal(
    transaction,
    getContactNameForTransaction(transaction),
  );
}

class TransactionRow extends StatelessWidget {
  const TransactionRow({
    super.key,
    required this.transaction,
    this.applySlidablePeek = false,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  });

  final Transaction transaction;
  final bool applySlidablePeek;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppPalette p = AppPalette.of(context);
    final bool isIncome = transaction.type == TransactionType.income;
    final Color accent = isIncome ? p.mint : p.coral;
    final String categoryLabel = _categoryLabelForTransaction(transaction);

    return Padding(
      padding: const EdgeInsets.only(top: 2.0),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? p.mint.withValues(alpha: 0.2) : p.surface,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected ? p.mint : p.border,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Slidable(
          key: ValueKey<int>(transaction.id),
          groupTag: 'transaction_rows',
          closeOnScroll: true,
          enabled: !isSelected,
          startActionPane: isSelected
              ? null
              : ActionPane(
                  motion: const DrawerMotion(),
                  extentRatio: 0.28,
                  children: [
                    SlidableAction(
                      onPressed: AppHaptics.wrapSlidable(
                          (_) => _openEditModalFor(transaction)),
                      backgroundColor: p.mint,
                      foregroundColor: Colors.black87,
                      icon: Icons.edit_rounded,
                      label: 'Edit',
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ],
                ),
          endActionPane: isSelected
              ? null
              : ActionPane(
                  motion: const DrawerMotion(),
                  extentRatio: 0.28,
                  children: [
                    SlidableAction(
                      onPressed: AppHaptics.wrapSlidable(
                          (_) => showDeleteModal(transaction)),
                      backgroundColor: p.coral,
                      foregroundColor: Colors.white,
                      icon: Icons.delete_outline_rounded,
                      label: 'Delete',
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ],
                ),
          child: SlidablePeekHint(
            storageKey: AppConstants.SLIDABLE_PEEK_TRANSACTIONS,
            enabled: applySlidablePeek,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12.0),
                onTap: onTap ??
                    () async {
                      AppHaptics.light();
                      final fullTx =
                          await db_ops.getTransactionById(transaction.id);
                      Get.to(() => TransactionDetailScreen(
                          transaction: fullTx ?? transaction));
                    },
                onLongPress: onLongPress,
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 4,
                          color: isSelected ? p.mint : accent,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 12.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.0),
                                    border: Border.all(
                                        color: accent.withValues(alpha: 0.55)),
                                    color: accent.withValues(alpha: 0.12),
                                  ),
                                  child: isSelected
                                      ? Icon(Icons.check_rounded,
                                          color: p.mint, size: 24.0)
                                      : Icon(
                                          Categories.iconForKey(
                                              transaction.category),
                                          color: accent,
                                          size: 22.0,
                                        ),
                                ),
                                const SizedBox(width: 12.0),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        transaction.description,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: textTheme.titleSmall!.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: p.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 6.0),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          if (categoryLabel.isNotEmpty) ...[
                                            Flexible(
                                              child: CategoryPillLabel(
                                                categoryKey:
                                                    transaction.category,
                                                label: categoryLabel,
                                              ),
                                            ),
                                            const SizedBox(width: 8.0),
                                          ],
                                          Text(
                                            DateFormat.jm()
                                                .format(transaction.date),
                                            style:
                                                textTheme.bodySmall!.copyWith(
                                              color: p.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  formatTransactionDisplayAmount(transaction),
                                  style: textTheme.titleSmall!.copyWith(
                                    color: p.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Frosted icon shell with mint glow — used for all empty-state icons.
class EmptyStateIconFrame extends StatelessWidget {
  const EmptyStateIconFrame({
    super.key,
    required this.child,
    this.circular = false,
    this.padding = const EdgeInsets.all(25),
  });

  final Widget child;
  final bool circular;
  final EdgeInsets padding;

  static const double _radius = 18;

  static List<BoxShadow> _mintGlow(AppPalette p) => [
        BoxShadow(
          color: p.mint.withValues(alpha: 0.38),
          blurRadius: 26,
          spreadRadius: 0,
          offset: Offset.zero,
        ),
        BoxShadow(
          color: p.mint.withValues(alpha: 0.22),
          blurRadius: 44,
          spreadRadius: -4,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: p.mint.withValues(alpha: 0.12),
          blurRadius: 56,
          spreadRadius: 2,
          offset: Offset.zero,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final Color rim = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.14)
        : p.border.withValues(alpha: 0.45);

    final BoxDecoration innerDeco = circular
        ? BoxDecoration(
            shape: BoxShape.circle,
            color: p.surfaceElevated.withValues(alpha: 0.42),
            border: Border.all(
              color: rim,
              width: 1,
            ),
          )
        : BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            color: p.surfaceElevated.withValues(alpha: 0.42),
            border: Border.all(
              color: rim,
              width: 1,
            ),
          );

    final Widget frosted = BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Container(
        padding: padding,
        decoration: innerDeco,
        child: child,
      ),
    );

    if (circular) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: _mintGlow(p),
        ),
        child: ClipOval(
          child: frosted,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: _mintGlow(p),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: frosted,
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final Icon icon;
  final Text primaryText;
  final Text secondaryText;

  const EmptyState(
      {super.key,
      required this.icon,
      required this.primaryText,
      required this.secondaryText});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EmptyStateIconFrame(
            child: icon,
          ),
          const SizedBox(height: 15.0),
          primaryText,
          const SizedBox(height: 15.0),
          secondaryText,
        ],
      ),
    );
  }
}
