import 'package:balance_sheet/constants/app.dart';
import 'package:balance_sheet/constants/category.dart';
import 'package:balance_sheet/enums.dart';
import 'package:balance_sheet/screens/report.dart';
import 'package:balance_sheet/saved_views/saved_views_storage.dart';
import 'package:balance_sheet/widgets/saved_views_sheet.dart';
import 'package:balance_sheet/controllers/budget_controller.dart';
import 'package:balance_sheet/controllers/contact_controller.dart';
import 'package:balance_sheet/controllers/tag_controller.dart';
import 'package:balance_sheet/models/budget_line.dart';
import 'package:balance_sheet/models/contact.dart';
import 'package:balance_sheet/models/tag.dart';
import 'package:balance_sheet/services/pdf_export_service.dart';
import 'package:balance_sheet/theme/app_palette.dart';
import 'package:balance_sheet/controllers/currency_controller.dart';
import 'package:balance_sheet/utils.dart';
import 'package:balance_sheet/utils/app_haptics.dart';
import 'package:balance_sheet/widgets/adaptive_card_sliver_list.dart';
import 'package:balance_sheet/widgets/dual_currency_total.dart';
import 'package:balance_sheet/widgets/category_pill_label.dart';
import 'package:balance_sheet/widgets/inputs.dart';
import 'package:balance_sheet/widgets/midnight_grid_painter.dart';
import 'package:balance_sheet/widgets/slidable_peek_hint.dart';
import 'package:balance_sheet/widgets/widgets.dart';
import 'package:balance_sheet/utils/app_snack.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

const double _horizontalPad = 20.0;

String _categoryLabelForKey(String key) {
  if (key.isEmpty) return '';
  for (final Map<String, Object> m in Categories.CATEGORIES) {
    if (m['key'] == key) {
      return m['label']! as String;
    }
  }
  return key;
}

int _minorFromAmountText(String value) {
  final String t = value.trim();
  if (t.isEmpty || t == '.') {
    return 0;
  }
  final double? d = double.tryParse(t);
  if (d == null) {
    return 0;
  }
  return (d * 1000).floor() ~/ 10;
}

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final BudgetController _budget = Get.find<BudgetController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _budget.reloadFocusMonth();
    });
  }

  Future<void> _exportPdf() async {
    AppHaptics.light();
    try {
      await PdfExportService.shareBudget(_budget);
    } catch (_) {
      if (!mounted) return;
      AppSnack.show(
          'PDF export failed', 'Could not export the current budget snapshot.');
    }
  }

  Future<void> _openEditor({BudgetLine? line}) async {
    final BuildContext ctx = context;
    await showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppPalette.of(ctx).overlay,
      builder: (BuildContext context) => _BudgetLineEditorSheet(existing: line),
    );
  }

  /// Swipe left → next month, swipe right → previous (matches chevron buttons).
  void _onBudgetHorizontalDragEnd(DragEndDetails details) {
    final double? v = details.primaryVelocity;
    if (v == null) {
      return;
    }
    const double threshold = 380;
    if (v < -threshold) {
      AppHaptics.selection();
      _budget.shiftMonth(1);
    } else if (v > threshold) {
      AppHaptics.selection();
      _budget.shiftMonth(-1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final bool landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    return Scaffold(
      backgroundColor: p.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: p.systemUiOverlayStyle,
        automaticallyImplyLeading: false,
        toolbarHeight: landscape ? 64 : kToolbarHeight,
        titleSpacing: landscape ? 16 : NavigationToolbar.kMiddleSpacing,
        title: landscape
            ? Obx(() {
                final DateTime m = _budget.focusMonth.value;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Budgets',
                      style:
                          Theme.of(context).textTheme.headlineSmall!.copyWith(
                                color: p.textPrimary,
                                letterSpacing: -0.4,
                              ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: _MonthSwitcher(
                          dense: true,
                          label: DateFormat('MMMM yyyy').format(m),
                          onPrev: () => _budget.shiftMonth(-1),
                          onNext: () => _budget.shiftMonth(1),
                        ),
                      ),
                    ),
                  ],
                );
              })
            : Text(
                'Budgets',
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      color: p.textPrimary,
                      letterSpacing: -0.4,
                    ),
              ),
        centerTitle: false,
        actions: <Widget>[
          IconButton(
            tooltip: 'Copy to next month',
            icon: Icon(Icons.copy_all_outlined, color: p.textPrimary),
            onPressed: () async {
              AppHaptics.light();

              if (_budget.lines.isEmpty) {
                AppSnack.show(
                  'Empty Budget',
                  'Add some items to this month first.',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: p.coral,
                  colorText: Colors.white,
                );
                return;
              }

              final DateTime current = _budget.focusMonth.value;
              final DateTime next = DateTime(current.year, current.month + 1);
              final bool? confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Copy to Next Month'),
                  content: Text(
                      'Copy all budget items to ${DateFormat('MMMM yyyy').format(next)}?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Copy')),
                  ],
                ),
              );
              if (confirmed == true) {
                final int? sourceId = _budget.activeBudgetMonth.value?.id;
                if (sourceId != null) {
                  await _budget.copyToNextMonth(
                      sourceId, next.year, next.month);
                  AppSnack.show(
                    'Success',
                    'Budget copied to ${DateFormat('MMMM yyyy').format(next)}',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: p.mint,
                    colorText: Colors.white,
                  );
                }
              }
            },
          ),
          IconButton(
            tooltip: 'Export PDF',
            icon: Icon(Icons.picture_as_pdf_outlined, color: p.textPrimary),
            onPressed: _exportPdf,
          ),
          IconButton(
            tooltip: 'Saved views',
            icon: Icon(Icons.bookmarks_outlined, color: p.textPrimary),
            onPressed: () {
              AppHaptics.light();
              showSavedViewsSheet(
                context,
                palette: p,
                featureKey: SavedViewsStorage.featureBudget,
                surfaceTitle: 'Budget',
                capturePayload: () {
                  final DateTime m = _budget.focusMonth.value;
                  return <String, dynamic>{
                    'year': m.year,
                    'month': m.month,
                  };
                },
                applyPayload: (Map<String, dynamic> payload) async {
                  final int y =
                      (payload['year'] as num?)?.toInt() ?? DateTime.now().year;
                  final int mo = (payload['month'] as num?)?.toInt() ??
                      DateTime.now().month;
                  _budget.focusMonth.value = DateTime(y, mo, 1);
                  await _budget.reloadFocusMonth();
                },
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: p.textPrimary),
            onPressed: () {
              AppHaptics.light();
              _budget.reloadFocusMonth();
            },
          ),
        ],
      ),
      bottomNavigationBar: _BudgetAddLineBar(onPressed: () => _openEditor()),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned.fill(
            child: CustomPaint(
              painter: MidnightGridPainter(
                  heightFraction: 1.0, gridLineColor: p.gridLine),
            ),
          ),
          SafeArea(
            child: Obx(() {
              return GestureDetector(
                onHorizontalDragEnd: _onBudgetHorizontalDragEnd,
                behavior: HitTestBehavior.deferToChild,
                child: _budget.loading.value && _budget.lines.isEmpty
                    ? Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: p.mint,
                          ),
                        ),
                      )
                    : _buildBudgetScrollContent(context, p),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetScrollContent(BuildContext context, AppPalette p) {
    final DateTime m = _budget.focusMonth.value;
    final bool landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final double listLayoutWidth =
        (MediaQuery.sizeOf(context).width - 2 * _horizontalPad)
            .clamp(0.0, double.infinity);
    final bool dupContacts = _hasDuplicateContactLinks(_budget.lines);
    final bool dupCategories = _hasDuplicateCategoryLinks(_budget.lines);
    final bool dupComposite = _hasDuplicateCompositeTrackers(_budget.lines);
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        SliverPadding(
          padding:
              const EdgeInsets.fromLTRB(_horizontalPad, 8, _horizontalPad, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (!landscape)
                  _MonthSwitcher(
                    label: DateFormat('MMMM yyyy').format(m),
                    onPrev: () => _budget.shiftMonth(-1),
                    onNext: () => _budget.shiftMonth(1),
                  ),
                if (_budget.lines.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 16),
                  if (landscape)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: _SummaryCard(
                            plannedMinor: _budget.plannedTotalMinor,
                            trackedSpentMinor: _budget.trackedSpentTotalMinor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              if (dupContacts)
                                const _InfoCallout(
                                  text:
                                      'Some lines share the same contact. “Spent” can count the same transactions on more than one line.',
                                ),
                              if (dupCategories) ...<Widget>[
                                if (dupContacts) const SizedBox(height: 12),
                                const _InfoCallout(
                                  text:
                                      'Some lines share the same category tag. “Spent” is the full category total, so totals can overlap across lines.',
                                ),
                              ],
                              if (dupComposite) ...<Widget>[
                                if (dupContacts || dupCategories)
                                  const SizedBox(height: 12),
                                const _InfoCallout(
                                  text:
                                      'Some lines share the same category + contact pair. “Spent” uses the same union for each, so the summary can double-count.',
                                ),
                              ],
                              SizedBox(
                                height: (dupContacts ||
                                        dupCategories ||
                                        dupComposite)
                                    ? 20
                                    : 0,
                              ),
                              Text(
                                'Planned items',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge!
                                    .copyWith(
                                      color: p.textPrimary,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Optionally pick a category tag and/or a contact. With both, “Spent” includes expenses in that tag or to that contact (union).',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      color: p.textSecondary,
                                      height: 1.35,
                                    ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _SummaryCard(
                          plannedMinor: _budget.plannedTotalMinor,
                          trackedSpentMinor: _budget.trackedSpentTotalMinor,
                        ),
                        if (dupContacts) ...<Widget>[
                          const SizedBox(height: 12),
                          const _InfoCallout(
                            text:
                                'Some lines share the same contact. “Spent” can count the same transactions on more than one line.',
                          ),
                        ],
                        if (dupCategories) ...<Widget>[
                          const SizedBox(height: 12),
                          const _InfoCallout(
                            text:
                                'Some lines share the same category tag. “Spent” is the full category total, so totals can overlap across lines.',
                          ),
                        ],
                        if (dupComposite) ...<Widget>[
                          const SizedBox(height: 12),
                          const _InfoCallout(
                            text:
                                'Some lines share the same category + contact pair. “Spent” uses the same union for each, so the summary can double-count.',
                          ),
                        ],
                        const SizedBox(height: 20),
                        Text(
                          'Planned items',
                          style:
                              Theme.of(context).textTheme.titleLarge!.copyWith(
                                    color: p.textPrimary,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Optionally pick a category tag and/or a contact. With both, “Spent” includes expenses in that tag or to that contact (union).',
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: p.textSecondary,
                                    height: 1.35,
                                  ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                ],
              ],
            ),
          ),
        ),
        if (_budget.lines.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: _horizontalPad),
                child: const _BudgetLinesEmptyCard(),
              ),
            ),
          )
        else
          adaptiveCardListSliver(
            contentWidth: listLayoutWidth,
            padding: EdgeInsets.fromLTRB(
              _horizontalPad,
              0,
              _horizontalPad,
              20,
            ),
            itemCount: _budget.lines.length,
            itemBuilder: (BuildContext context, int index) {
              final BudgetLine line = _budget.lines[index];
              return _BudgetLineTile(
                line: line,
                applySlidablePeek: index == 0,
                spentMinor: line.hasSpendTracker
                    ? (_budget.spentMinorByLineId[line.id] ?? 0)
                    : null,
                onTap: () {
                  AppHaptics.light();
                  final DateTime monthDate = _budget.focusMonth.value;
                  final DateTime start =
                      DateTime(monthDate.year, monthDate.month, 1);
                  final DateTime end =
                      DateTime(monthDate.year, monthDate.month + 1, 0);
                  Get.to(() => const ReportView(), arguments: {
                    'filter_report_type': ReportType.dateRange,
                    'filter_start_date': start,
                    'filter_end_date': end,
                    'filter_category': line.categoryKey,
                    'filter_contact_id': line.contactId,
                    'filter_tag_id': line.tagId,
                  });
                },
                onEdit: () {
                  _openEditor(line: line);
                },
                onDelete: () => _confirmDelete(context, line),
              );
            },
          ),
      ],
    );
  }

  bool _hasDuplicateContactLinks(List<BudgetLine> lines) {
    final List<int> ids = lines
        .where((BudgetLine l) => l.contactId > 0)
        .map((BudgetLine l) => l.contactId)
        .toList();
    return ids.length != ids.toSet().length;
  }

  bool _hasDuplicateCategoryLinks(List<BudgetLine> lines) {
    final List<String> keys = lines
        .where((BudgetLine l) => l.categoryKey.isNotEmpty)
        .map((BudgetLine l) => l.categoryKey)
        .toList();
    return keys.length != keys.toSet().length;
  }

  bool _hasDuplicateCompositeTrackers(List<BudgetLine> lines) {
    final List<String> pairs = lines
        .where((BudgetLine l) => l.categoryKey.isNotEmpty && l.contactId > 0)
        .map((BudgetLine l) => '${l.contactId}:${l.categoryKey}')
        .toList();
    return pairs.length != pairs.toSet().length;
  }

  Future<void> _confirmDelete(BuildContext context, BudgetLine line) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        final AppPalette p = AppPalette.of(ctx);
        return AlertDialog(
          backgroundColor: p.surfaceElevated,
          title: Text('Remove item?', style: TextStyle(color: p.textPrimary)),
          content: Text(
            line.description.isEmpty
                ? 'This budget line will be deleted.'
                : '“${line.description}” will be removed.',
            style: TextStyle(color: p.textSecondary),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                AppHaptics.light();
                Navigator.pop(ctx, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                AppHaptics.medium();
                Navigator.pop(ctx, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (ok == true) {
      await _budget.deleteLine(line.id);
    }
  }
}

class _BudgetLinesEmptyCard extends StatelessWidget {
  const _BudgetLinesEmptyCard();

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    const String detail =
        'Use “Add budget line” below to plan what you expect to spend this month.';
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: p.surfaceElevated,
          border: Border.all(color: p.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            EmptyStateIconFrame(
              padding: const EdgeInsets.all(20),
              child: Icon(
                Icons.event_note_rounded,
                size: 40,
                color: p.mint.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Nothing planned yet',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: p.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: p.textSecondary,
                    height: 1.4,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetAddLineBar extends StatelessWidget {
  const _BudgetAddLineBar({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Material(
      color: p.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: p.border.withValues(alpha: 0.6)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              _horizontalPad,
              10,
              _horizontalPad,
              10,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: AppHaptics.wrap(onPressed),
                icon: const Icon(Icons.add_rounded, size: 22),
                label: const Text('Add budget line'),
                style: FilledButton.styleFrom(
                  backgroundColor: p.mint,
                  foregroundColor: const Color(0xFF0D1117),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
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

class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({
    required this.label,
    required this.onPrev,
    required this.onNext,
    this.dense = false,
  });

  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  /// Tighter padding and icons for the landscape [AppBar] so content is not clipped.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final double iconSize = dense ? 24 : 28;
    final ButtonStyle? iconStyle = dense
        ? IconButton.styleFrom(
            padding: const EdgeInsets.all(4),
            minimumSize: const Size(40, 40),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          )
        : null;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 4 : 8,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(dense ? 14 : 16),
        border: Border.all(color: p.border.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            style: iconStyle,
            onPressed: () {
              AppHaptics.selection();
              onPrev();
            },
            icon: Icon(
              Icons.chevron_left_rounded,
              color: p.textPrimary,
              size: iconSize,
            ),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: dense ? 1 : null,
              overflow: dense ? TextOverflow.ellipsis : TextOverflow.visible,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: p.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: dense ? 15 : null,
                  ),
            ),
          ),
          IconButton(
            style: iconStyle,
            onPressed: () {
              AppHaptics.selection();
              onNext();
            },
            icon: Icon(
              Icons.chevron_right_rounded,
              color: p.textPrimary,
              size: iconSize,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.plannedMinor,
    required this.trackedSpentMinor,
  });

  final int plannedMinor;
  final int trackedSpentMinor;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final int remaining = plannedMinor - trackedSpentMinor;
    final bool over = remaining < 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: p.surfaceElevated,
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Planned (this month)',
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: p.textSecondary,
                  letterSpacing: 0.6,
                ),
          ),
          const SizedBox(height: 4),
          DualCurrencyTotal(
            lcyMinor: plannedMinor,
            textAlign: TextAlign.start,
            primaryStyle: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  color: p.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
            secondaryStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: p.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Spent (tracked)',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall!
                          .copyWith(color: p.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    DualCurrencyTotal(
                      lcyMinor: trackedSpentMinor,
                      textAlign: TextAlign.start,
                      compactSecondary: true,
                      primaryStyle:
                          Theme.of(context).textTheme.titleMedium!.copyWith(
                                color: p.mint,
                                fontWeight: FontWeight.w600,
                              ),
                      secondaryStyle:
                          Theme.of(context).textTheme.bodySmall!.copyWith(
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
                  children: <Widget>[
                    Text(
                      'Remaining vs tracked',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall!
                          .copyWith(color: p.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    DualCurrencySignedNet(
                      netMinor: remaining,
                      textAlign: TextAlign.end,
                      primaryStyle:
                          Theme.of(context).textTheme.titleMedium!.copyWith(
                                color: over ? p.coral : p.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                      secondaryStyle:
                          Theme.of(context).textTheme.bodySmall!.copyWith(
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
    );
  }
}

class _InfoCallout extends StatelessWidget {
  const _InfoCallout({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: p.mint.withValues(alpha: 0.08),
        border: Border.all(color: p.mint.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline_rounded, size: 20, color: p.mint),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: p.textSecondary,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetLineTile extends StatelessWidget {
  const _BudgetLineTile({
    required this.line,
    required this.applySlidablePeek,
    required this.spentMinor,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final BudgetLine line;
  final bool applySlidablePeek;
  final int? spentMinor;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final ContactController contacts = Get.find<ContactController>();
    final TagController tags = Get.find<TagController>();
    final CurrencyController currency = Get.find<CurrencyController>();
    return Obx(() {
      // Always read [RxList] so Obx subscribes (lines with no contact/tag would otherwise skip the list).
      final List<Contact> contactList = contacts.contacts.toList();
      final List<Tag> tagList = tags.allTags.toList();
      String resolvedContact = '';
      if (line.contactId > 0) {
        for (final Contact c in contactList) {
          if (c.id == line.contactId) {
            resolvedContact = c.name;
            break;
          }
        }
      }
      String resolvedTag = '';
      if (line.tagId > 0) {
        for (final Tag t in tagList) {
          if (t.id == line.tagId) {
            resolvedTag = t.name;
            break;
          }
        }
      }

      final bool hasTrack = spentMinor != null;
      final double progress = hasTrack && line.plannedAmount > 0
          ? ((spentMinor ?? 0) / line.plannedAmount).clamp(0.0, 1.0).toDouble()
          : 0.0;
      final bool overBudget =
          hasTrack && (spentMinor ?? 0) > line.plannedAmount;

      return Slidable(
        key: ValueKey<int>(line.id),
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.28,
          children: <Widget>[
            SlidableAction(
              onPressed: AppHaptics.wrapSlidable((_) => onEdit()),
              backgroundColor: p.mint.withValues(alpha: 0.9),
              foregroundColor: Colors.white,
              icon: Icons.edit_outlined,
              label: 'Edit',
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.28,
          children: <Widget>[
            SlidableAction(
              onPressed: AppHaptics.wrapSlidable((_) => onDelete()),
              backgroundColor: p.coral.withValues(alpha: 0.9),
              foregroundColor: Colors.white,
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
            ),
          ],
        ),
        child: SlidablePeekHint(
          storageKey: AppConstants.SLIDABLE_PEEK_BUDGET,
          enabled: applySlidablePeek,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: AppHaptics.wrap(onTap),
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: p.surface.withValues(alpha: 0.95),
                  border: Border.all(color: p.border.withValues(alpha: 0.75)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      line.description.isEmpty ? 'Untitled' : line.description,
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            color: p.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (line.categoryKey.isNotEmpty ||
                        resolvedContact.isNotEmpty ||
                        resolvedTag.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        runSpacing: 4,
                        children: <Widget>[
                          if (line.categoryKey.isNotEmpty)
                            CategoryPillLabel(
                              categoryKey: line.categoryKey,
                              label: _categoryLabelForKey(line.categoryKey),
                              compact: true,
                            ),
                          if (resolvedContact.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(Icons.person_outline_rounded,
                                    size: 16, color: p.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  resolvedContact,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium!
                                      .copyWith(color: p.mint),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          if (resolvedTag.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(Icons.local_offer_outlined,
                                    size: 15, color: p.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  resolvedTag,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium!
                                      .copyWith(
                                        color: p.coral.withValues(alpha: 0.9),
                                        fontWeight: FontWeight.w600,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Plan ${formatBudgetPlannedDisplay(line)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge!
                                    .copyWith(color: p.textSecondary),
                              ),
                              if (currency.showDualTotals)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    '≈ ${line.planEntryIsFcy ? formatAmount(line.plannedAmount) : formatMinorUnits(currency.fcyMinorFromLcyMinor(line.plannedAmount), currency.fcyCode.value)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(
                                          color: p.textSecondary
                                              .withValues(alpha: 0.7),
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (hasTrack)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              Text(
                                'Spent ${formatAmount(spentMinor!)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge!
                                    .copyWith(
                                      color:
                                          overBudget ? p.coral : p.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              if (currency.showDualTotals)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    '≈ ${formatMinorUnits(currency.fcyMinorFromLcyMinor(spentMinor!), currency.fcyCode.value)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(
                                          color: p.textSecondary
                                              .withValues(alpha: 0.7),
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ),
                            ],
                          )
                        else
                          Text(
                            'No category or contact',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium!
                                .copyWith(
                                  color:
                                      p.textSecondary.withValues(alpha: 0.85),
                                ),
                          ),
                      ],
                    ),
                    if (hasTrack && line.plannedAmount > 0) ...<Widget>[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 5,
                          backgroundColor: p.border.withValues(alpha: 0.5),
                          color: overBudget ? p.coral : p.mint,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _BudgetLineEditorSheet extends StatefulWidget {
  const _BudgetLineEditorSheet({this.existing});

  final BudgetLine? existing;

  @override
  State<_BudgetLineEditorSheet> createState() => _BudgetLineEditorSheetState();
}

class _BudgetLineEditorSheetState extends State<_BudgetLineEditorSheet> {
  late final TextEditingController _desc;
  late final TextEditingController _amount;
  late final FocusNode _descFocus;
  late final FocusNode _amountFocus;
  int _contactId = 0;
  int _tagId = 0;
  String _categoryKey = '';
  bool _planEntryIsFcy = false;
  final BudgetController _budget = Get.find<BudgetController>();
  final ContactController _contacts = Get.find<ContactController>();
  final TagController _tags = Get.find<TagController>();
  final CurrencyController _currency = Get.find<CurrencyController>();

  @override
  void initState() {
    super.initState();
    _descFocus = FocusNode();
    _amountFocus = FocusNode();
    final BudgetLine? e = widget.existing;
    _desc = TextEditingController(text: e?.description ?? '');
    _planEntryIsFcy = e?.planEntryIsFcy ?? false;
    final int showMinor = e != null
        ? (e.planEntryIsFcy ? e.planEntryAmountMinor : e.plannedAmount)
        : 0;
    _amount = TextEditingController(
      text: showMinor > 0 ? (showMinor / 100).toStringAsFixed(2) : '',
    );
    _contactId = e?.contactId ?? 0;
    _tagId = e?.tagId ?? 0;
    _categoryKey = e?.categoryKey ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _descFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _descFocus.dispose();
    _amountFocus.dispose();
    _desc.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String d = _desc.text.trim();
    if (d.isEmpty) {
      AppSnack.show(
          'Missing description', 'Add a short label for this planned item.');
      return;
    }
    final int entryMinor = _minorFromAmountText(_amount.text);
    if (entryMinor <= 0) {
      AppSnack.show('Amount', 'Enter a planned amount greater than zero.');
      return;
    }
    final int plannedLcyMinor = _planEntryIsFcy
        ? _currency.lcyMinorFromFcyMinor(entryMinor)
        : entryMinor;
    final BudgetLine? e = widget.existing;
    if (e == null) {
      await _budget.addLine(
        description: d,
        plannedAmountMinor: plannedLcyMinor,
        contactId: _contactId,
        tagId: _tagId,
        categoryKey: _categoryKey,
        planEntryIsFcy: _planEntryIsFcy,
        planEntryAmountMinor: _planEntryIsFcy ? entryMinor : plannedLcyMinor,
      );
    } else {
      await _budget.updateLine(
        e.copyWith(
          description: d,
          plannedAmount: plannedLcyMinor,
          contactId: _contactId,
          tagId: _tagId,
          categoryKey: _categoryKey,
          planEntryIsFcy: _planEntryIsFcy,
          planEntryAmountMinor: _planEntryIsFcy ? entryMinor : plannedLcyMinor,
        ),
      );
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
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
                widget.existing == null
                    ? 'Add planned item'
                    : 'Edit planned item',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: p.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _desc,
                focusNode: _descFocus,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(_amountFocus);
                },
                decoration: InputDecoration(
                  labelText: 'What you plan to spend on',
                  labelStyle: TextStyle(color: p.textSecondary),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: p.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: p.mint.withValues(alpha: 0.8)),
                  ),
                ),
                style: TextStyle(color: p.textPrimary),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              Obx(() {
                final String lCode = _currency.lcyCode.value;
                final String fCode = _currency.fcyCode.value;
                final String code = _planEntryIsFcy ? fCode : lCode;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'PLANNED AMOUNT ($code)',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium!
                                .copyWith(
                                  letterSpacing: 1.15,
                                  height: 1.2,
                                  color: p.textPrimary.withValues(alpha: 0.88),
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SegmentedButton<bool>(
                          segments: <ButtonSegment<bool>>[
                            ButtonSegment<bool>(
                              value: false,
                              label: Text(lCode),
                            ),
                            ButtonSegment<bool>(
                              value: true,
                              label: Text(fCode),
                            ),
                          ],
                          selected: <bool>{_planEntryIsFcy},
                          onSelectionChanged: (Set<bool> next) {
                            if (next.isEmpty) return;
                            final bool toFcy = next.single;
                            if (toFcy == _planEntryIsFcy) return;
                            setState(() {
                              final int cur =
                                  _minorFromAmountText(_amount.text);
                              if (cur <= 0) {
                                _planEntryIsFcy = toFcy;
                                return;
                              }
                              if (toFcy) {
                                final int fcy =
                                    _currency.fcyMinorFromLcyMinor(cur);
                                _planEntryIsFcy = true;
                                _amount.text = (fcy / 100).toStringAsFixed(2);
                              } else {
                                final int lcy =
                                    _currency.lcyMinorFromFcyMinor(cur);
                                _planEntryIsFcy = false;
                                _amount.text = (lcy / 100).toStringAsFixed(2);
                              }
                            });
                          },
                          style: SegmentedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: p.surface,
                            foregroundColor: p.textPrimary,
                            side: BorderSide(color: p.border),
                            selectedBackgroundColor: p.coral,
                            selectedForegroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _amount,
                      focusNode: _amountFocus,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: <TextInputFormatter>[
                        DecimalTextInputFormatter()
                      ],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => FocusScope.of(context).unfocus(),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: TextStyle(color: p.textSecondary),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: p.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: p.mint.withValues(alpha: 0.8)),
                        ),
                      ),
                      style: TextStyle(color: p.textPrimary),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Category tag (optional)',
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                          color: p.textSecondary,
                          letterSpacing: 0.2,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Builder(
                    builder: (BuildContext context) {
                      final List<String> keys = Categories.CATEGORIES
                          .map((Map<String, Object> m) => m['key']! as String)
                          .toList();
                      final String value =
                          _categoryKey.isEmpty || !keys.contains(_categoryKey)
                              ? ''
                              : _categoryKey;
                      final List<Map<String, Object>> list =
                          Categories.CATEGORIES;
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: p.border),
                          borderRadius: BorderRadius.circular(10.0),
                          color: p.surface,
                        ),
                        padding: const EdgeInsets.fromLTRB(9, 8, 7, 8),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: value,
                            isExpanded: true,
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: p.textSecondary,
                              size: 22,
                            ),
                            dropdownColor: p.background,
                            borderRadius: BorderRadius.circular(14.0),
                            itemHeight: null,
                            menuMaxHeight: 320,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            selectedItemBuilder: (BuildContext buttonContext) {
                              return <Widget>[
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: _BudgetNoCategoryPill(),
                                ),
                                ...list.map((Map<String, Object> c) {
                                  final String k = c['key']! as String;
                                  final String lbl = c['label']! as String;
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: CategoryPillLabel(
                                        categoryKey: k, label: lbl),
                                  );
                                }),
                              ];
                            },
                            items: <DropdownMenuItem<String>>[
                              DropdownMenuItem<String>(
                                value: '',
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: _BudgetNoCategoryPill(),
                                ),
                              ),
                              ...list.map((Map<String, Object> c) {
                                final String k = c['key']! as String;
                                final String lbl = c['label']! as String;
                                return DropdownMenuItem<String>(
                                  value: k,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 1.0),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: CategoryPillLabel(
                                          categoryKey: k, label: lbl),
                                    ),
                                  ),
                                );
                              }),
                            ],
                            onChanged: (String? v) {
                              AppHaptics.selection();
                              setState(() => _categoryKey = v ?? '');
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Obx(() {
                final List<DropdownMenuItem<int>> items =
                    <DropdownMenuItem<int>>[
                  DropdownMenuItem<int>(
                    value: 0,
                    child: Text('No contact',
                        style: TextStyle(color: p.textPrimary)),
                  ),
                  ..._contacts.contacts.map(
                    (c) => DropdownMenuItem<int>(
                      value: c.id,
                      child: Text(c.name, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ];
                final int dropdownContactId = _contactId > 0 &&
                        _contacts.contacts.any((c) => c.id == _contactId)
                    ? _contactId
                    : 0;
                return InputDecorator(
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 15),
                    labelText: 'Contact (optional)',
                    labelStyle: TextStyle(color: p.textSecondary, fontSize: 15),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: p.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: p.mint.withValues(alpha: 0.8)),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: dropdownContactId,
                      isDense: true,
                      isExpanded: true,
                      dropdownColor: p.surfaceElevated,
                      style: TextStyle(color: p.textPrimary, fontSize: 15),
                      items: items,
                      onChanged: (int? v) {
                        AppHaptics.selection();
                        setState(() => _contactId = v ?? 0);
                      },
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              Obx(() {
                final List<DropdownMenuItem<int>> items =
                    <DropdownMenuItem<int>>[
                  DropdownMenuItem<int>(
                    value: 0,
                    child:
                        Text('No tag', style: TextStyle(color: p.textPrimary)),
                  ),
                  ..._tags.allTags.map(
                    (t) => DropdownMenuItem<int>(
                      value: t.id,
                      child: Text(t.name, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ];
                final int dropdownTagId =
                    _tagId > 0 && _tags.allTags.any((t) => t.id == _tagId)
                        ? _tagId
                        : 0;
                return InputDecorator(
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 15),
                    labelText: 'Tag (optional)',
                    labelStyle: TextStyle(color: p.textSecondary, fontSize: 15),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: p.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: p.mint.withValues(alpha: 0.8)),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: dropdownTagId,
                      isDense: true,
                      isExpanded: true,
                      dropdownColor: p.surfaceElevated,
                      style: TextStyle(color: p.textPrimary, fontSize: 15),
                      items: items,
                      onChanged: (int? v) {
                        AppHaptics.selection();
                        setState(() => _tagId = v ?? 0);
                      },
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              Text(
                'Spent = category expenses, contact expenses, tag expenses, or — if multiple are set — their union (any condition).',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(color: p.textSecondary, height: 1.35),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  AppHaptics.light();
                  await _save();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: p.mint,
                  foregroundColor: const Color(0xFF0D1117),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(widget.existing == null ? 'Add' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Neutral pill for “no category” — same capsule shape as [CategoryPillLabel].
class _BudgetNoCategoryPill extends StatelessWidget {
  const _BudgetNoCategoryPill();

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final TextStyle base = Theme.of(context).textTheme.labelSmall!;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 10.0),
      decoration: BoxDecoration(
        color: p.surfaceElevated,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: p.border),
      ),
      child: Text(
        'No category',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: base.copyWith(
          fontSize: base.fontSize ?? 11,
          fontWeight: FontWeight.w600,
          color: p.textSecondary,
        ),
      ),
    );
  }
}
