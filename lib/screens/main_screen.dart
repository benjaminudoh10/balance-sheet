import 'dart:ui';

import 'package:balance_sheet/controllers/appController.dart';
import 'package:balance_sheet/theme/app_palette.dart';
import 'package:balance_sheet/controllers/transactionController.dart';
import 'package:balance_sheet/enums.dart';
import 'package:balance_sheet/screens/new_income_form.dart';
import 'package:balance_sheet/screens/report.dart';
import 'package:balance_sheet/utils.dart';
import 'package:balance_sheet/widgets/dual_currency_total.dart';
import 'package:balance_sheet/widgets/midnight_grid_painter.dart';
import 'package:balance_sheet/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const double _horizontalPad = 20.0;

class MainView extends StatelessWidget {
  final TransactionController _transactionController = Get.find();

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Material(
      color: p.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: MidnightGridPainter(heightFraction: 1.0, gridLineColor: p.gridLine),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(_horizontalPad, 12, _horizontalPad, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Balanced',
                        style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                          color: p.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Get.find<AppController>().setIndex(4),
                        icon: const Icon(Icons.settings_outlined),
                        color: p.textPrimary,
                        style: IconButton.styleFrom(
                          backgroundColor: p.surface.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Obx(() {
                  final list = _transactionController.transactions;
                  return CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: _horizontalPad),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _GlassBalanceCard(
                                total: _transactionController.total.value,
                                todayIncome: _transactionController.todaysIncome.value,
                                todayExpense: _transactionController.todaysExpense.value,
                              ),
                              const SizedBox(height: 18),
                              _IncomeExpenseRow(),
                              const SizedBox(height: 28),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Recent Transactions',
                                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                    color: p.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                      if (list.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyState(
                            icon: Icon(
                              Icons.receipt_long_outlined,
                              size: 48,
                              color: p.mint.withValues(alpha: 0.7),
                            ),
                            primaryText: Text(
                              'Add your first transaction today',
                              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                fontWeight: FontWeight.bold,
                                color: p.textPrimary,
                              ),
                            ),
                            secondaryText: Text(
                              'Tap Income or Expense above.',
                              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                color: p.textSecondary,
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(_horizontalPad, 0, _horizontalPad, 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return Padding(
                                  padding: EdgeInsets.only(bottom: index == list.length - 1 ? 0 : 10),
                                  child: singleTransactionContainer(context, list[index]),
                                );
                              },
                              childCount: list.length,
                            ),
                          ),
                        ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class _GlassBalanceCard extends StatelessWidget {
  const _GlassBalanceCard({
    required this.total,
    required this.todayIncome,
    required this.todayExpense,
  });

  final int total;
  final int todayIncome;
  final int todayExpense;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final int todayNet = todayIncome - todayExpense;
    final bool isTotalLoss = total < 0;
    final bool isDailyLoss = todayNet < 0;
    final Color netColor = isDailyLoss ? p.coral : p.mint;
    final Color cardAccent = isTotalLoss ? p.coral : p.mint;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cardAccent.withValues(alpha: 0.35)),
            gradient: p.balanceCardGradient(isTotalLoss),
            boxShadow: [
              BoxShadow(
                color: cardAccent.withValues(alpha: 0.28),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              DualCurrencyTotal(
                lcyMinor: total,
                textAlign: TextAlign.center,
                primaryStyle: Theme.of(context).textTheme.displaySmall!.copyWith(
                  color: p.textPrimary,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    formatSignedNet(todayNet),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: netColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Today',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: p.textSecondary,
                      letterSpacing: 0.8,
                      height: 1.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Get.to(() => const ReportView()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cardAccent,
                    side: BorderSide(color: cardAccent.withValues(alpha: 0.45)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'All transactions',
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right_rounded, size: 22),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IncomeExpenseRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Row(
      children: [
        Expanded(
          child: _ActionPill(
            label: 'Income',
            icon: Icons.add_circle_rounded,
            accent: p.mint,
            glow: p.mint.withValues(alpha: 0.35),
            onTap: () => showNewTransactionModal(TransactionType.income),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionPill(
            label: 'Expense',
            icon: Icons.remove_circle_rounded,
            accent: p.coral,
            glow: p.coral.withValues(alpha: 0.35),
            onTap: () => showNewTransactionModal(TransactionType.expenditure),
          ),
        ),
      ],
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.label,
    required this.icon,
    required this.accent,
    required this.glow,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final Color glow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const double radius = 32;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        splashColor: accent.withValues(alpha: 0.12),
        highlightColor: accent.withValues(alpha: 0.06),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: accent.withValues(alpha: 0.55)),
            color: accent.withValues(alpha: 0.08),
            boxShadow: [
              BoxShadow(
                color: glow,
                blurRadius: 20,
                spreadRadius: 0,
                offset: Offset.zero,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: accent, size: 24),
              const SizedBox(width: 10),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showNewTransactionModal(TransactionType type) async {
  final TransactionController transactionController = Get.find();

  final BuildContext context = Get.context!;
  final AppPalette p = AppPalette.of(context);
  await showModalBottomSheet<void>(
    backgroundColor: Colors.transparent,
    barrierColor: p.overlay,
    isScrollControlled: true,
    context: context,
    builder: (context) => Wrap(
      children: [
        IncomeForm(type: type),
      ],
    ),
  ).whenComplete(transactionController.resetFieldValues);
}
