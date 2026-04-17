import 'dart:ui' show ImageFilter;

import 'package:balance_sheet/theme/app_palette.dart';
import 'package:balance_sheet/controllers/reportController.dart';
import 'package:balance_sheet/dialogs/contact.dart';
import 'package:balance_sheet/enums.dart';
import 'package:balance_sheet/models/contact.dart';
import 'package:balance_sheet/models/transaction.dart';
import 'package:balance_sheet/widgets/dual_currency_total.dart';
import 'package:balance_sheet/widgets/category_pill_label.dart';
import 'package:balance_sheet/widgets/inputs.dart';
import 'package:balance_sheet/widgets/midnight_grid_painter.dart';
import 'package:balance_sheet/utils/app_haptics.dart';
import 'package:balance_sheet/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

const double _horizontalPad = 20.0;

/// Order of items in the period dropdown on All transactions.
const List<ReportType> _kPeriodOrder = <ReportType>[
  ReportType.today,
  ReportType.month,
  ReportType.thisWeek,
  ReportType.lastMonth,
  ReportType.singleDay,
  ReportType.dateRange,
];

String _periodMenuLabel(ReportType t) {
  switch (t) {
    case ReportType.today:
      return 'Today';
    case ReportType.month:
      return 'This month';
    case ReportType.thisWeek:
      return 'This week';
    case ReportType.lastMonth:
      return 'Last month';
    case ReportType.singleDay:
      return 'Single day';
    case ReportType.dateRange:
      return 'Date range';
  }
}

class ReportView extends StatefulWidget {
  const ReportView({super.key});

  @override
  State<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<ReportView> {
  late final ReportController _reportController;

  @override
  void initState() {
    super.initState();
    _reportController = Get.put(ReportController());
  }

  @override
  void dispose() {
    if (Get.isRegistered<ReportController>()) {
      Get.delete<ReportController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
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
          'All transactions',
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
            color: p.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        centerTitle: false,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: MidnightGridPainter(heightFraction: 1.0, gridLineColor: p.gridLine),
            ),
          ),
          SafeArea(
            child: Obx(() => CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(_horizontalPad, 8, _horizontalPad, 0),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ReportPeriodSummaryCard(controller: _reportController),
                            const SizedBox(height: 14),
                            _ReportFiltersSection(controller: _reportController),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    if (_reportController.transactions.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyState(
                          icon: Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: p.mint.withValues(alpha: 0.7),
                          ),
                          primaryText: Text(
                            'No transactions in this period',
                            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                              color: p.textPrimary,
                            ),
                          ),
                          secondaryText: Text(
                            _hasActiveFilters(_reportController)
                                ? 'Try clearing filters or choosing another date range'
                                : 'Change the period above or add entries from Home',
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: p.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(_horizontalPad, 0, _horizontalPad, 28),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate(
                            _buildGroupedTransactionSlivers(context, _reportController),
                          ),
                        ),
                      ),
                  ],
                )),
          ),
        ],
      ),
    );
  }
}

bool _hasActiveFilters(ReportController c) {
  final bool cat = c.category.value != 'Category';
  final bool contact = c.contact.value.id > 0;
  return cat || contact;
}

List<Widget> _buildGroupedTransactionSlivers(BuildContext context, ReportController c) {
  final Map<int, List<Transaction>> map = c.splitTransactions;
  final List<int> keys = map.keys.toList()..sort((a, b) => b.compareTo(a));
  final List<Widget> out = [];

  for (final int dayStart in keys) {
    final List<Transaction> dayTx = map[dayStart] ?? [];
    if (dayTx.isEmpty) continue;

    final DateTime date = DateTime.fromMillisecondsSinceEpoch(dayStart);
    final String headerLine =
        DateFormat('EEEE, MMM d').format(date).toUpperCase();

    out.add(_DaySectionHeader(
      title: headerLine,
      controller: c,
    ));
    out.add(const SizedBox(height: 10));

    for (int i = 0; i < dayTx.length; i++) {
      out.add(
        Padding(
          padding: EdgeInsets.only(bottom: i == dayTx.length - 1 ? 18 : 10),
          child: singleTransactionContainer(context, dayTx[i]),
        ),
      );
    }
  }

  return out;
}

class _ReportPeriodDropdown extends StatelessWidget {
  const _ReportPeriodDropdown({required this.controller});

  final ReportController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final AppPalette p = AppPalette.of(context);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: p.surfaceElevated,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: p.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<ReportType>(
            value: controller.type.value,
            isExpanded: false,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: p.textSecondary,
              size: 22,
            ),
            dropdownColor: p.background,
            borderRadius: BorderRadius.circular(16),
            itemHeight: null,
            menuMaxHeight: 360,
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
              color: p.textPrimary,
            ),
            selectedItemBuilder: (BuildContext context) {
              return _kPeriodOrder.map((ReportType t) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    controller.type.value == t
                        ? controller.label.value
                        : _periodMenuLabel(t),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList();
            },
            items: _kPeriodOrder.map((ReportType t) {
              return DropdownMenuItem<ReportType>(
                value: t,
                child: Text(_periodMenuLabel(t)),
              );
            }).toList(),
            onChanged: (ReportType? t) {
              if (t == null) return;
              AppHaptics.selection();
              controller.applyPeriodType(t);
            },
          ),
        ),
      );
    });
  }
}

/// Time range, category, and contact on one scrollable row; clear filters as a pill on the next row when needed.
class _ReportFiltersSection extends StatelessWidget {
  const _ReportFiltersSection({required this.controller});

  final ReportController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool showClear = _hasActiveFilters(controller);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _ReportPeriodDropdown(controller: controller),
                const SizedBox(width: 10),
                ReportCategoryDropdown(controller: controller),
                const SizedBox(width: 10),
                _ContactFilterChip(controller: controller),
              ],
            ),
          ),
          if (showClear) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: _ClearFiltersPill(controller: controller),
            ),
          ],
        ],
      );
    });
  }
}

class _ClearFiltersPill extends StatelessWidget {
  const _ClearFiltersPill({required this.controller});

  final ReportController controller;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          AppHaptics.light();
          controller.category.value = 'Category';
          controller.categoryLabel.value = 'Category';
          controller.contact.value = Contact(name: 'Contact');
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.filter_alt_off_rounded,
                size: 18,
                color: p.mint.withValues(alpha: 0.95),
              ),
              const SizedBox(width: 6),
              Text(
                'Clear filters',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: p.mint.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactFilterChip extends StatelessWidget {
  const _ContactFilterChip({required this.controller});

  final ReportController controller;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final bool active = controller.contact.value.id > 0;
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => showContactPickerSheet(context, controller: controller),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 18,
                color: active ? p.mint : p.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  controller.contact.value.name,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: active ? p.textPrimary : p.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (active) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: () {
                    AppHaptics.light();
                    controller.contact.value = Contact(name: 'Contact');
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: p.textSecondary.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportPeriodSummaryCard extends StatelessWidget {
  const _ReportPeriodSummaryCard({required this.controller});

  final ReportController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final AppPalette p = AppPalette.of(context);
      final int income = controller.income.value;
      final int expense = controller.expense.value;
      final int net = income - expense;
      final bool isLoss = net < 0;
      final Color accent = isLoss ? p.coral : p.mint;

      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
              gradient: p.balanceCardGradient(isLoss),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.22),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DualCurrencyTotal(
                  lcyMinor: net,
                  textAlign: TextAlign.center,
                  primaryStyle: Theme.of(context).textTheme.displayMedium!.copyWith(
                    color: accent,
                    letterSpacing: -0.6,
                  ),
                  secondaryStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: p.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  controller.label.value,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: p.textSecondary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INCOME',
                            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                              color: p.textSecondary,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DualCurrencyTotal(
                            lcyMinor: income,
                            textAlign: TextAlign.start,
                            compactSecondary: true,
                            showFcyEquivalent: false,
                            primaryStyle: Theme.of(context).textTheme.titleLarge!.copyWith(
                              color: p.mint,
                              fontWeight: FontWeight.w700,
                            ),
                            secondaryStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: p.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'EXPENSES',
                            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                              color: p.textSecondary,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DualCurrencyTotal(
                            lcyMinor: expense,
                            textAlign: TextAlign.end,
                            compactSecondary: true,
                            showFcyEquivalent: false,
                            primaryStyle: Theme.of(context).textTheme.titleLarge!.copyWith(
                              color: p.coral,
                              fontWeight: FontWeight.w700,
                            ),
                            secondaryStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: p.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _DaySectionHeader extends StatelessWidget {
  const _DaySectionHeader({
    required this.title,
    required this.controller,
  });

  final String title;
  final ReportController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final AppPalette p = AppPalette.of(context);
      final bool categoryFilterOn = controller.category.value != 'Category';

      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: p.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
          if (categoryFilterOn)
            CategoryPillLabel(
              categoryKey: controller.category.value,
              label: controller.categoryLabel.value,
              compact: true,
            ),
        ],
      );
    });
  }
}
