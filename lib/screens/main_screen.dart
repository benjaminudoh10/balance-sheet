import 'dart:ui';

import 'package:balance_sheet/constants/app.dart';
import 'package:balance_sheet/controllers/currency_controller.dart';
import 'package:balance_sheet/dialogs/transaction_actions.dart';
import 'package:balance_sheet/controllers/investment_controller.dart';
import 'package:balance_sheet/controllers/summary_amounts_privacy_controller.dart';
import 'package:balance_sheet/theme/app_palette.dart';
import 'package:balance_sheet/controllers/transaction_controller.dart';
import 'package:balance_sheet/enums.dart';
import 'package:balance_sheet/models/transaction.dart';
import 'package:balance_sheet/screens/new_income_form.dart';
import 'package:balance_sheet/screens/report.dart';
import 'package:balance_sheet/utils.dart';
import 'package:balance_sheet/utils/app_haptics.dart';
import 'package:balance_sheet/widgets/dual_currency_total.dart';
import 'package:balance_sheet/widgets/midnight_grid_painter.dart';
import 'package:balance_sheet/widgets/adaptive_card_sliver_list.dart';
import 'package:balance_sheet/widgets/plan_hub_fab.dart';
import 'package:balance_sheet/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

const double _horizontalPad = 20.0;

double _homeHorizontalPad(double contentWidth) {
  return contentWidth >= AppConstants.adaptiveNavRailMinWidth
      ? 24.0
      : _horizontalPad;
}

/// Compact: pager. Adaptive (no pager): stacked, then side-by-side when wide enough.
///
/// [contentWidth] is the main column width (breakpoints). [heroLayoutWidth] is the width inside
/// [SliverPadding] horizontal insets — use this for the side-by-side [Row] so it does not overflow.
Widget _homeHeroForContentWidth({
  required AppPalette palette,
  required double contentWidth,
  required double heroLayoutWidth,
  required Widget balanceCard,
  required Widget netWorthStrip,
}) {
  if (contentWidth < AppConstants.adaptiveNavRailMinWidth) {
    return _BalanceNetWorthPager(
      palette: palette,
      balanceCard: balanceCard,
      netWorthStrip: netWorthStrip,
    );
  }
  if (contentWidth < AppConstants.homeHeroSideBySideMinWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        balanceCard,
        const SizedBox(height: 14),
        netWorthStrip,
      ],
    );
  }
  // Fixed column widths from [heroLayoutWidth] (already excludes horizontal sliver padding).
  const double gap = 14.0;
  final double inner = (heroLayoutWidth - gap).clamp(0.0, double.infinity);
  final double cardWidth = inner / 2;
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      SizedBox(
        width: cardWidth,
        child: balanceCard,
      ),
      SizedBox(width: gap),
      SizedBox(
        width: cardWidth,
        child: netWorthStrip,
      ),
    ],
  );
}

Widget _homeTransactionListSliver({
  required BuildContext context,
  required List<Transaction> list,
  required double contentWidth,
  required double horizontalPad,
}) {
  return adaptiveCardListSliver(
    contentWidth: contentWidth,
    padding: EdgeInsets.fromLTRB(
      horizontalPad,
      0,
      horizontalPad,
      24 + kPlanHubFabTrailingClearance,
    ),
    itemCount: list.length,
    itemBuilder: (BuildContext context, int index) {
      final transaction = list[index];
      return singleTransactionContainer(
        context,
        transaction,
        applySlidablePeek: index == 0,
        onTap: AppHaptics.wrap(() => showEditModal(
              transaction,
              getContactNameForTransaction(transaction),
            )),
      );
    },
  );
}

/// Extra [PageView] height so the net-worth strip (header + dual totals + rows) does not clip
/// when matched to the balance card height.
const double _kHomeBalancePagerHeightSlack = 28.0;

class MainView extends StatelessWidget {
  MainView({super.key});

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
              painter: MidnightGridPainter(
                  heightFraction: 1.0, gridLineColor: p.gridLine),
            ),
          ),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints outer) {
              final double contentWidth = outer.maxWidth;
              final double hPad = _homeHorizontalPad(contentWidth);
              final double paddedInnerWidth =
                  (contentWidth - 2 * hPad).clamp(0.0, double.infinity);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Balanced',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge!
                              .copyWith(
                                color: p.textPrimary,
                                letterSpacing: -0.5,
                              ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Obx(() {
                      final list = _transactionController.transactions;
                      final int ledgerMinor =
                          _transactionController.total.value;
                      final InvestmentController inv =
                          Get.find<InvestmentController>();
                      final int stocksMinor = inv.stocksTotalMinor.value;
                      final int otherInvestMinor =
                          inv.otherInvestmentsTotalMinor.value;
                      final bool isLandscape =
                          MediaQuery.orientationOf(context) ==
                              Orientation.landscape;
                      final Widget balanceCard = _GlassBalanceCard(
                        total: _transactionController.total.value,
                        todayIncome: _transactionController.todaysIncome.value,
                        todayExpense:
                            _transactionController.todaysExpense.value,
                      );
                      final Widget netWorthStrip = _NetWorthStrip(
                        ledgerMinor: ledgerMinor,
                        stocksMinor: stocksMinor,
                        otherInvestmentsMinor: otherInvestMinor,
                      );
                      return CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: <Widget>[
                          SliverPadding(
                            padding: EdgeInsets.symmetric(horizontal: hPad),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  _homeHeroForContentWidth(
                                    palette: p,
                                    contentWidth: contentWidth,
                                    heroLayoutWidth: paddedInnerWidth,
                                    balanceCard: balanceCard,
                                    netWorthStrip: netWorthStrip,
                                  ),
                                  if (isLandscape) const SizedBox(height: 18),
                                  _IncomeExpenseRow(),
                                  if (list.isNotEmpty) ...<Widget>[
                                    const SizedBox(height: 28),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Recent Transactions',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge!
                                            .copyWith(
                                              color: p.textPrimary,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          if (list.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Padding(
                                padding: EdgeInsets.only(
                                  top: isLandscape ? 16 : 0,
                                  bottom: kPlanHubFabTrailingClearance,
                                ),
                                child: EmptyState(
                                  icon: Icon(
                                    Icons.receipt_long_outlined,
                                    size: 48,
                                    color: p.mint.withValues(alpha: 0.7),
                                  ),
                                  primaryText: Text(
                                    'Add your first transaction today',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium!
                                        .copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: p.textPrimary,
                                        ),
                                  ),
                                  secondaryText: Text(
                                    'Tap Income or Expense above.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                          color: p.textSecondary,
                                        ),
                                  ),
                                ),
                              ),
                            )
                          else
                            _homeTransactionListSliver(
                              context: context,
                              list: list,
                              contentWidth: paddedInnerWidth,
                              horizontalPad: hPad,
                            ),
                        ],
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

const Color _kNetWorthInvestAccent = Color(0xFF818CF8);

/// Swipe horizontally: main balance card, then net worth (same styling as before).
class _BalanceNetWorthPager extends StatefulWidget {
  const _BalanceNetWorthPager({
    required this.palette,
    required this.balanceCard,
    required this.netWorthStrip,
  });

  final AppPalette palette;
  final Widget balanceCard;
  final Widget netWorthStrip;

  @override
  State<_BalanceNetWorthPager> createState() => _BalanceNetWorthPagerState();
}

class _BalanceNetWorthPagerState extends State<_BalanceNetWorthPager> {
  late final PageController _pageController;
  final GlobalKey _balanceKey = GlobalKey();
  int _index = 0;
  double? _pageHeight;
  bool _coachScheduled = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _scheduleMeasureBalanceHeight() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _measureBalanceHeight());
  }

  void _measureBalanceHeight() {
    final BuildContext? ctx = _balanceKey.currentContext;
    if (ctx == null || !mounted) return;
    final RenderObject? ro = ctx.findRenderObject();
    if (ro is! RenderBox || !ro.hasSize) return;
    // Use intrinsic card height + slack. The balance card Column must use
    // [MainAxisSize.min] so it does not expand to the pager [SizedBox] height;
    // otherwise each measure grows by slack again (unbounded height).
    final double h = ro.size.height + _kHomeBalancePagerHeightSlack;
    if (_pageHeight == null || (h - _pageHeight!).abs() > 0.5) {
      setState(() => _pageHeight = h);
    }
  }

  @override
  void didUpdateWidget(_BalanceNetWorthPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleMeasureBalanceHeight();
  }

  void _maybeScheduleCoach() {
    if (_coachScheduled || _pageHeight == null) {
      return;
    }
    final GetStorage box = GetStorage();
    if (box.read(AppConstants.HOME_BALANCE_PAGER_COACH_DONE) == true) {
      return;
    }
    _coachScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _runBalancePagerCoach();
    });
  }

  Future<void> _runBalancePagerCoach() async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted || !_pageController.hasClients) {
      return;
    }
    await _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
    if (!mounted) {
      return;
    }
    AppHaptics.selection();
    await Future<void>.delayed(const Duration(milliseconds: 620));
    if (!mounted || !_pageController.hasClients) {
      return;
    }
    await _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeInOutCubic,
    );
    if (!mounted) {
      return;
    }
    await GetStorage().write(AppConstants.HOME_BALANCE_PAGER_COACH_DONE, true);
  }

  @override
  Widget build(BuildContext context) {
    _scheduleMeasureBalanceHeight();
    _maybeScheduleCoach();
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double w = constraints.maxWidth;
        final Widget balance = KeyedSubtree(
          key: _balanceKey,
          child: widget.balanceCard,
        );

        if (_pageHeight == null) {
          return SizedBox(
            width: w,
            child: balance,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              height: _pageHeight,
              child: PageView(
                controller: _pageController,
                onPageChanged: (int i) {
                  if (i != _index) AppHaptics.selection();
                  _index = i;
                },
                physics: const BouncingScrollPhysics(),
                children: <Widget>[
                  Align(
                    alignment: Alignment.topCenter,
                    child: balance,
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: w,
                      child: widget.netWorthStrip,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Tighter than [IconButton] so paired summary cards fit the home pager height.
class _CompactAmountVisibilityToggle extends StatelessWidget {
  const _CompactAmountVisibilityToggle({
    required this.amountsVisible,
    required this.onPressed,
    required this.iconColor,
  });

  final bool amountsVisible;
  final VoidCallback onPressed;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: amountsVisible ? 'Hide amounts' : 'Show amounts',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              amountsVisible
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _NetWorthStrip extends StatelessWidget {
  const _NetWorthStrip({
    required this.ledgerMinor,
    required this.stocksMinor,
    required this.otherInvestmentsMinor,
  });

  final int ledgerMinor;
  final int stocksMinor;
  final int otherInvestmentsMinor;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final SummaryAmountsPrivacyController priv =
        Get.find<SummaryAmountsPrivacyController>();
    final int total = ledgerMinor + stocksMinor + otherInvestmentsMinor;
    final TextStyle totalPrimary =
        Theme.of(context).textTheme.titleLarge!.copyWith(
              color: p.textPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            );
    final TextStyle totalSecondary =
        Theme.of(context).textTheme.bodySmall!.copyWith(
              color: p.textSecondary,
              fontWeight: FontWeight.w500,
            );
    return Obx(() {
      final bool showAmt = priv.showHomeSummaryAmounts.value;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: p.surface.withValues(alpha: 0.78),
          border:
              Border.all(color: _kNetWorthInvestAccent.withValues(alpha: 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.pie_chart_outline_rounded,
                    size: 18,
                    color: _kNetWorthInvestAccent.withValues(alpha: 0.95)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Net worth',
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: p.textSecondary,
                          letterSpacing: 0.2,
                        ),
                  ),
                ),
                _CompactAmountVisibilityToggle(
                  amountsVisible: showAmt,
                  iconColor: p.textSecondary.withValues(alpha: 0.88),
                  onPressed: () {
                    AppHaptics.light();
                    priv.toggleHomeSummaryAmounts();
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            DualCurrencyTotal(
              lcyMinor: total,
              textAlign: TextAlign.start,
              compactSecondary: true,
              primaryStyle: totalPrimary,
              secondaryStyle: totalSecondary,
              obscureAmount: !showAmt,
            ),
            _NetWorthRow(
                label: 'Ledger balance',
                minor: ledgerMinor,
                palette: p,
                obscureAmount: !showAmt),
            _NetWorthRow(
                label: 'Investments',
                minor: stocksMinor,
                palette: p,
                obscureAmount: !showAmt),
            _NetWorthRow(
                label: 'Other investments',
                minor: otherInvestmentsMinor,
                palette: p,
                obscureAmount: !showAmt),
          ],
        ),
      );
    });
  }
}

class _NetWorthRow extends StatelessWidget {
  const _NetWorthRow({
    required this.label,
    required this.minor,
    required this.palette,
    required this.obscureAmount,
  });

  final String label;
  final int minor;
  final AppPalette palette;
  final bool obscureAmount;

  @override
  Widget build(BuildContext context) {
    final TextStyle primaryAmt =
        Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: palette.textPrimary,
              fontWeight: FontWeight.w600,
            );
    final TextStyle secondaryAmt =
        Theme.of(context).textTheme.bodySmall!.copyWith(
              color: palette.textSecondary,
              fontWeight: FontWeight.w500,
            );
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(color: palette.textSecondary),
            ),
          ),
          Obx(() {
            final CurrencyController c = Get.find<CurrencyController>();
            if (obscureAmount) {
              return ObscuredAggregateAmount(
                textAlign: TextAlign.end,
                primaryStyle: primaryAmt,
                secondaryStyle: secondaryAmt,
                compactSecondary: true,
                dualLine: c.showDualTotals,
              );
            }
            if (!c.showDualTotals) {
              return Text(
                formatAmount(minor),
                textAlign: TextAlign.end,
                style: primaryAmt,
              );
            }
            final int fcyMinor = c.fcyMinorFromLcyMinor(minor);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  formatMinorUnits(minor, c.lcyCode.value),
                  textAlign: TextAlign.end,
                  style: primaryAmt,
                ),
                const SizedBox(height: 2),
                Text(
                  '≈ ${formatMinorUnits(fcyMinor, c.fcyCode.value)}',
                  textAlign: TextAlign.end,
                  style: secondaryAmt,
                ),
              ],
            );
          }),
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
    final SummaryAmountsPrivacyController priv =
        Get.find<SummaryAmountsPrivacyController>();
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
          width: double.infinity,
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
          child: Obx(() {
            final bool showAmt = priv.showHomeSummaryAmounts.value;
            return Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    DualCurrencyTotal(
                      lcyMinor: total,
                      textAlign: TextAlign.center,
                      obscureAmount: !showAmt,
                      primaryStyle:
                          Theme.of(context).textTheme.displaySmall!.copyWith(
                                color: p.textPrimary,
                                letterSpacing: -0.6,
                              ),
                    ),
                    const SizedBox(height: 10),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          showAmt ? formatSignedNet(todayNet) : '*****',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.titleLarge!.copyWith(
                                    color: netColor,
                                    letterSpacing: showAmt ? -0.2 : 2.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Today',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.labelMedium!.copyWith(
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
                        onPressed: () {
                          AppHaptics.light();
                          Get.to(() => const ReportView());
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cardAccent,
                          side: BorderSide(
                              color: cardAccent.withValues(alpha: 0.45)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              'All transactions',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall!
                                  .copyWith(
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
                Positioned(
                  top: 2,
                  right: 2,
                  child: _CompactAmountVisibilityToggle(
                    amountsVisible: showAmt,
                    iconColor: p.textSecondary.withValues(alpha: 0.88),
                    onPressed: () {
                      AppHaptics.light();
                      priv.toggleHomeSummaryAmounts();
                    },
                  ),
                ),
              ],
            );
          }),
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
        onTap: AppHaptics.wrap(onTap),
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
  AppHaptics.light();
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
