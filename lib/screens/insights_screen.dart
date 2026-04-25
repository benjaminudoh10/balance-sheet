import 'dart:math' show max;
import 'dart:ui' show ImageFilter;

import 'package:balance_sheet/constants/category.dart';
import 'package:balance_sheet/controllers/insights_controller.dart';
import 'package:balance_sheet/saved_views/saved_views_storage.dart';
import 'package:balance_sheet/screens/report.dart';
import 'package:balance_sheet/services/pdf_export_service.dart';
import 'package:balance_sheet/widgets/saved_views_sheet.dart';
import 'package:balance_sheet/utils/app_haptics.dart';
import 'package:balance_sheet/theme/app_palette.dart';
import 'package:balance_sheet/utils.dart';
import 'package:balance_sheet/widgets/dual_currency_total.dart';
import 'package:balance_sheet/widgets/midnight_grid_painter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

const double _horizontalPad = 20.0;

class InsightsView extends StatefulWidget {
  const InsightsView({super.key});

  @override
  State<InsightsView> createState() => _InsightsViewState();
}

class _InsightsViewState extends State<InsightsView> {
  final InsightsController _controller = Get.find<InsightsController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.load();
    });
  }

  Future<void> _exportPdf() async {
    AppHaptics.light();
    try {
      await PdfExportService.shareInsights(_controller);
    } catch (_) {
      if (!mounted) return;
      Get.snackbar('PDF export failed',
          'Could not export the current insights snapshot.');
    }
  }

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      _horizontalPad, 12, _horizontalPad, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Insights',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge!
                              .copyWith(
                                color: p.textPrimary,
                                letterSpacing: -0.5,
                              ),
                        ),
                      ),
                      Obx(() {
                        return PopupMenuButton<InsightsPeriod>(
                          tooltip: 'Period',
                          initialValue: _controller.period.value,
                          onSelected: (InsightsPeriod v) =>
                              _controller.setPeriod(v),
                          color: p.surfaceElevated,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  InsightsController.periodLabel(
                                      _controller.period.value),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall!
                                      .copyWith(
                                        color: p.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.expand_more_rounded,
                                    color: p.textSecondary, size: 20),
                              ],
                            ),
                          ),
                          itemBuilder: (BuildContext ctx) =>
                              <PopupMenuEntry<InsightsPeriod>>[
                            PopupMenuItem(
                              value: InsightsPeriod.today,
                              child: Text(InsightsController.periodLabel(
                                  InsightsPeriod.today)),
                            ),
                            PopupMenuItem(
                              value: InsightsPeriod.thisWeek,
                              child: Text(InsightsController.periodLabel(
                                  InsightsPeriod.thisWeek)),
                            ),
                            PopupMenuItem(
                              value: InsightsPeriod.thisMonth,
                              child: Text(InsightsController.periodLabel(
                                  InsightsPeriod.thisMonth)),
                            ),
                            PopupMenuItem(
                              value: InsightsPeriod.lastMonth,
                              child: Text(InsightsController.periodLabel(
                                  InsightsPeriod.lastMonth)),
                            ),
                          ],
                        );
                      }),
                      IconButton(
                        tooltip: 'Export PDF',
                        icon: Icon(Icons.picture_as_pdf_outlined,
                            color: p.textPrimary),
                        onPressed: _exportPdf,
                      ),
                      IconButton(
                        tooltip: 'Saved views',
                        icon: Icon(Icons.bookmarks_outlined,
                            color: p.textPrimary),
                        onPressed: () {
                          AppHaptics.light();
                          showSavedViewsSheet(
                            context,
                            palette: p,
                            featureKey: SavedViewsStorage.featureInsights,
                            surfaceTitle: 'Insights',
                            capturePayload: () =>
                                _controller.captureSavedViewState(),
                            applyPayload: _controller.applySavedViewState,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (_controller.loading.value) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: p.mint,
                        strokeWidth: 2,
                      ),
                    );
                  }
                  return CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                            _horizontalPad, 0, _horizontalPad, 28),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _ExpenseHeroCard(controller: _controller),
                              const SizedBox(height: 18),
                              _CategoryBarsPanel(controller: _controller),
                              const SizedBox(height: 18),
                              _WeeklyCashPanel(controller: _controller),
                              const SizedBox(height: 18),
                              _NetTrendCard(controller: _controller),
                              const SizedBox(height: 18),
                              _InsightsList(controller: _controller),
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed: () {
                                  AppHaptics.light();
                                  Get.to(() => const ReportView());
                                },
                                icon: Icon(Icons.receipt_long_outlined,
                                    color: p.mint, size: 20),
                                label: Text(
                                  'All transactions',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall!
                                      .copyWith(
                                        color: p.mint,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Based on recorded transactions through ${_footerDateLabel(_controller.rangeEndMs.value)}.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(
                                      color: p.textSecondary,
                                    ),
                              ),
                            ],
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

String _footerDateLabel(int endMs) {
  final DateTime d = DateTime.fromMillisecondsSinceEpoch(endMs);
  return DateFormat.yMMMd().format(d);
}

class _ExpenseHeroCard extends StatelessWidget {
  const _ExpenseHeroCard({required this.controller});

  final InsightsController controller;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Obx(() {
      final int exp = controller.expenseTotal.value;
      final int prev = controller.expensePreviousPeriod.value;
      final String vs = controller.comparisonVsShort;
      int? pct;
      if (prev > 0) {
        pct = ((exp - prev) / prev * 100).round();
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: p.coral.withValues(alpha: 0.35)),
              gradient: p.balanceCardGradient(true),
              boxShadow: [
                BoxShadow(
                  color: p.coral.withValues(alpha: 0.22),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expenses',
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        color: p.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 6),
                DualCurrencyTotal(
                  lcyMinor: exp,
                  textAlign: TextAlign.start,
                  primaryStyle:
                      Theme.of(context).textTheme.displaySmall!.copyWith(
                            color: p.textPrimary,
                            letterSpacing: -0.6,
                          ),
                  secondaryStyle:
                      Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: p.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                ),
                if (pct != null && prev > 0) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        pct > 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 20,
                        color: pct > 0 ? p.coral : p.mint,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          pct == 0
                              ? 'Same as $vs'
                              : '${pct > 0 ? 'Up' : 'Down'} ${pct.abs()}% vs $vs',
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: p.textSecondary,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ] else if (prev == 0 && exp > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    controller.comparisonEmptyBaselineHint,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(color: p.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _CategoryBarsPanel extends StatelessWidget {
  const _CategoryBarsPanel({required this.controller});

  final InsightsController controller;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final Brightness b = Theme.of(context).brightness;
    return Obx(() {
      final List<CategoryBarRow> rows = controller.categoryBarRows.toList();
      if (rows.isEmpty) {
        return const SizedBox.shrink();
      }
      final int maxAmt =
          rows.map((CategoryBarRow r) => r.amountMinor).reduce(max);
      if (maxAmt <= 0) {
        return const SizedBox.shrink();
      }

      return _GlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expenses by category',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium!
                  .copyWith(color: p.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Same data as the donut, easier to compare amounts',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: 14),
            for (int i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _CategoryHorizontalBarRow(
                palette: p,
                brightness: b,
                row: rows[i],
                maxAmountMinor: maxAmt,
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _CategoryHorizontalBarRow extends StatelessWidget {
  const _CategoryHorizontalBarRow({
    required this.palette,
    required this.brightness,
    required this.row,
    required this.maxAmountMinor,
  });

  final AppPalette palette;
  final Brightness brightness;
  final CategoryBarRow row;
  final int maxAmountMinor;

  @override
  Widget build(BuildContext context) {
    final Color fill =
        Categories.pillStyleForKey(row.key, brightness).foreground;
    final double t =
        maxAmountMinor > 0 ? row.amountMinor / maxAmountMinor : 0.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 112,
          child: Text(
            row.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(color: palette.textPrimary),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 14,
                  color: palette.border.withValues(alpha: 0.45),
                ),
                FractionallySizedBox(
                  widthFactor: t.clamp(0.0, 1.0),
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: fill.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 76,
          child: Text(
            formatAmount(row.amountMinor),
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: palette.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _WeeklyCashPanel extends StatelessWidget {
  const _WeeklyCashPanel({required this.controller});

  final InsightsController controller;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Obx(() {
      final List<WeeklyCashRow> rows = controller.weeklyCashRows.toList();
      if (rows.isEmpty) {
        return const SizedBox.shrink();
      }

      double maxY = 1;
      for (final WeeklyCashRow w in rows) {
        maxY = max(maxY, w.incomeMinor.toDouble());
        maxY = max(maxY, w.expenseMinor.toDouble());
      }
      maxY *= 1.12;
      if (maxY < 1) {
        maxY = 1;
      }

      final double barW = rows.length > 5 ? 8 : 11;

      final List<BarChartGroupData> groups = List<BarChartGroupData>.generate(
        rows.length,
        (int i) {
          final WeeklyCashRow w = rows[i];
          return BarChartGroupData(
            x: i,
            barsSpace: 3,
            barRods: [
              BarChartRodData(
                toY: w.incomeMinor.toDouble(),
                color: p.mint,
                width: barW,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(3)),
              ),
              BarChartRodData(
                toY: w.expenseMinor.toDouble(),
                color: p.coral,
                width: barW,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(3)),
              ),
            ],
          );
        },
      );

      return _GlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Income vs expenses by week',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium!
                  .copyWith(color: p.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Weeks start on Monday · bars side-by-side per week',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _WeeklyLegendDot(color: p.mint, label: 'Income'),
                const SizedBox(width: 16),
                _WeeklyLegendDot(color: p.coral, label: 'Expenses'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 210,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  groupsSpace: rows.length > 4 ? 8 : 12,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => p.surfaceElevated,
                      getTooltipItem: (BarChartGroupData group, int groupIndex,
                          BarChartRodData rod, int rodIndex) {
                        final String kind =
                            rodIndex == 0 ? 'Income' : 'Expenses';
                        return BarTooltipItem(
                          '$kind\n${formatAmount(rod.toY.round())}',
                          Theme.of(context).textTheme.labelSmall!.copyWith(
                                color: p.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final int i = value.toInt();
                          if (i < 0 || i >= rows.length) {
                            return const SizedBox.shrink();
                          }
                          final DateTime start = rows[i].weekStartMonday;
                          return SideTitleWidget(
                            meta: meta,
                            space: 4,
                            child: Text(
                              DateFormat.Md().format(start),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall!
                                  .copyWith(
                                    color: p.textSecondary,
                                    fontSize: 10,
                                  ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        interval: maxY > 0
                            ? (maxY / 4).clamp(1, double.infinity)
                            : null,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            formatAmount(value.round()),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(
                                  color: p.textSecondary,
                                  fontSize: 9,
                                ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY > 0 ? maxY / 4 : 1,
                    getDrawingHorizontalLine: (double v) => FlLine(
                      color: p.gridLine,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: groups,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _WeeklyLegendDot extends StatelessWidget {
  const _WeeklyLegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall!
              .copyWith(color: p.textSecondary),
        ),
      ],
    );
  }
}

class _NetTrendCard extends StatelessWidget {
  const _NetTrendCard({required this.controller});

  final InsightsController controller;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final List<DailyNetPoint> points = controller.dailyNet.toList();
    if (points.isEmpty) {
      return _GlassPanel(
        child: Text(
          'No daily activity in this range.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium!
              .copyWith(color: p.textSecondary),
        ),
      );
    }

    double minY = 0;
    double maxY = 0;
    for (final DailyNetPoint pt in points) {
      final double v = pt.netMinor.toDouble();
      if (v < minY) minY = v;
      if (v > maxY) maxY = v;
    }
    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    } else {
      final double pad = (maxY - minY) * 0.12;
      minY -= pad;
      maxY += pad;
    }

    final List<FlSpot> spots = [
      for (int i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].netMinor.toDouble()),
    ];

    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Net per day',
            style: Theme.of(context)
                .textTheme
                .titleMedium!
                .copyWith(color: p.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Income minus expenses, by calendar day',
            style: Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (points.length - 1).toDouble().clamp(0, double.infinity),
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) > 0 ? (maxY - minY) / 4 : 1,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: p.gridLine,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: points.length > 8
                          ? (points.length / 4).ceilToDouble()
                          : 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final int i = value.round();
                        if (i < 0 || i >= points.length)
                          return const SizedBox.shrink();
                        if (points.length > 12 &&
                            i % ((points.length / 6).ceil()) != 0 &&
                            i != points.length - 1) {
                          return const SizedBox.shrink();
                        }
                        final DateTime d = points[i].day;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat.Md().format(d),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(
                                  color: p.textSecondary,
                                  fontSize: 10,
                                ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          formatAmount(value.round()),
                          style:
                              Theme.of(context).textTheme.labelSmall!.copyWith(
                                    color: p.textSecondary,
                                    fontSize: 9,
                                  ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => p.surfaceElevated,
                    getTooltipItems: (List<LineBarSpot> touched) {
                      return touched.map((LineBarSpot spot) {
                        final int i = spot.x.round();
                        if (i < 0 || i >= points.length) {
                          return null;
                        }
                        return LineTooltipItem(
                          '${DateFormat.yMMMd().format(points[i].day)}\n${formatSignedNet(points[i].netMinor)}',
                          Theme.of(context)
                              .textTheme
                              .labelSmall!
                              .copyWith(color: p.textPrimary),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: p.mint,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          p.mint.withValues(alpha: 0.35),
                          p.mint.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightsList extends StatelessWidget {
  const _InsightsList({required this.controller});

  final InsightsController controller;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final List<String> lines = controller.insightLines.toList();
    if (lines.isEmpty) {
      return _GlassPanel(
        child: Text(
          'Add a few more transactions to see takeaways.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium!
              .copyWith(color: p.textSecondary),
        ),
      );
    }

    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Takeaways',
            style: Theme.of(context)
                .textTheme
                .titleMedium!
                .copyWith(color: p.textPrimary),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < lines.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome_rounded,
                    size: 18, color: p.mint.withValues(alpha: 0.85)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    lines[i],
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: p.textPrimary,
                          height: 1.35,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border.withValues(alpha: 0.9)),
        color: p.surface.withValues(alpha: 0.88),
        boxShadow: [
          BoxShadow(
            color: p.mint.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
