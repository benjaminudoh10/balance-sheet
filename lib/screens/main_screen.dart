import 'dart:ui';

import 'package:balance_sheet/constants/midnight_theme.dart';
import 'package:balance_sheet/controllers/appController.dart';
import 'package:balance_sheet/controllers/transactionController.dart';
import 'package:balance_sheet/enums.dart';
import 'package:balance_sheet/screens/new_income_form.dart';
import 'package:balance_sheet/screens/report.dart';
import 'package:balance_sheet/utils.dart';
import 'package:balance_sheet/widgets/midnight_grid_painter.dart';
import 'package:balance_sheet/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const double _horizontalPad = 20.0;

class MainView extends StatelessWidget {
  final TransactionController _transactionController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MidnightTheme.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: CustomPaint(painter: MidnightGridPainter(heightFraction: 1.0)),
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
                      const Text(
                        'Balanced',
                        style: TextStyle(
                          color: MidnightTheme.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Get.find<AppController>().setIndex(4),
                        icon: const Icon(Icons.settings_outlined),
                        color: MidnightTheme.textPrimary,
                        style: IconButton.styleFrom(
                          backgroundColor: MidnightTheme.surface.withValues(alpha: 0.9),
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
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Recent Transactions',
                                  style: TextStyle(
                                    color: MidnightTheme.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
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
                              color: MidnightTheme.mint.withValues(alpha: 0.7),
                            ),
                            primaryText: const Text(
                              'Add your first transaction today',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: MidnightTheme.textPrimary,
                              ),
                            ),
                            secondaryText: const Text(
                              'Tap Income or Expense above.',
                              style: TextStyle(
                                color: MidnightTheme.textSecondary,
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
                                  child: singleTransactionContainer(list[index]),
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
    final int todayNet = todayIncome - todayExpense;
    final bool isDailyLoss = todayNet < 0;
    final Color netColor = isDailyLoss ? MidnightTheme.coral : MidnightTheme.mint;
    final Color cardAccent = isDailyLoss ? MidnightTheme.coral : MidnightTheme.mint;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cardAccent.withValues(alpha: 0.35)),
            gradient: MidnightTheme.balanceCardGradient(isDailyLoss),
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
              Text(
                formatAmount(total),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: MidnightTheme.textPrimary,
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.8,
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
                    style: TextStyle(
                      color: netColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Today',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: MidnightTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.8,
                      height: 1.0,
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
                    children: const [
                      Text(
                        'All transactions',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.chevron_right_rounded, size: 22),
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
    return Row(
      children: [
        Expanded(
          child: _ActionPill(
            label: 'Income',
            icon: Icons.add_circle_rounded,
            accent: MidnightTheme.mint,
            glow: MidnightTheme.mint.withValues(alpha: 0.35),
            onTap: () => showNewTransactionModal(TransactionType.income),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionPill(
            label: 'Expense',
            icon: Icons.remove_circle_rounded,
            accent: MidnightTheme.coral,
            glow: MidnightTheme.coral.withValues(alpha: 0.35),
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
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
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
  await showModalBottomSheet<void>(
    backgroundColor: Colors.transparent,
    barrierColor: MidnightTheme.overlay,
    isScrollControlled: true,
    context: context,
    builder: (context) => Wrap(
      children: [
        IncomeForm(type: type),
      ],
    ),
  ).whenComplete(transactionController.resetFieldValues);
}
