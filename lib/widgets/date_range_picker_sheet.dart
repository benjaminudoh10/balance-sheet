import 'package:balance_sheet/theme/app_palette.dart';
import 'package:balance_sheet/utils/app_haptics.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Modern bottom-sheet replacement for [showDateRangePicker].
///
/// Matches the app's aesthetic (rounded `surfaceElevated` card, mint accent,
/// drag handle, haptics) and layers UX niceties on top of the stock Material
/// picker:
///   * Quick presets (last 7/30/90 days, year to date, last year)
///   * Swipeable month pager with prev/next chevrons
///   * Visual track that connects the two endpoints across cells/rows
///   * Summary card with start, end, and number of days selected
///   * Reset / Apply footer with proper haptic feedback
///
/// Returns the selected [DateTimeRange], or `null` if the user dismissed.
Future<DateTimeRange?> showAppDateRangePicker(
  BuildContext context, {
  required DateTime firstDate,
  required DateTime lastDate,
  DateTimeRange? initialRange,
}) {
  final AppPalette p = AppPalette.of(context);
  final DateTime first = _dayOnly(firstDate);
  final DateTime last = _dayOnly(lastDate);
  return showModalBottomSheet<DateTimeRange>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: p.overlay,
    useSafeArea: true,
    builder: (BuildContext ctx) => _AppDateRangePickerSheet(
      firstDate: first,
      lastDate: last,
      initialRange: initialRange == null
          ? null
          : DateTimeRange(
              start: _dayOnly(initialRange.start),
              end: _dayOnly(initialRange.end),
            ),
    ),
  );
}

DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

int _monthsBetween(DateTime a, DateTime b) =>
    (b.year - a.year) * 12 + (b.month - a.month);

DateTime _addMonths(DateTime base, int months) =>
    DateTime(base.year, base.month + months, 1);

int _daysInMonth(int year, int month) =>
    DateTime(year, month + 1, 0).day;

enum _PresetKey { last7, last30, last90, ytd, lastYear }

class _PresetSpec {
  const _PresetSpec(this.key, this.label);

  final _PresetKey key;
  final String label;
}

const List<_PresetSpec> _kPresets = <_PresetSpec>[
  _PresetSpec(_PresetKey.last7, 'Last 7 days'),
  _PresetSpec(_PresetKey.last30, 'Last 30 days'),
  _PresetSpec(_PresetKey.last90, 'Last 90 days'),
  _PresetSpec(_PresetKey.ytd, 'Year to date'),
  _PresetSpec(_PresetKey.lastYear, 'Last year'),
];

DateTimeRange _rangeFromPreset(
  _PresetKey key,
  DateTime firstAllowed,
  DateTime lastAllowed,
) {
  final DateTime today = lastAllowed;
  late DateTime start;
  late DateTime end;
  switch (key) {
    case _PresetKey.last7:
      start = today.subtract(const Duration(days: 6));
      end = today;
      break;
    case _PresetKey.last30:
      start = today.subtract(const Duration(days: 29));
      end = today;
      break;
    case _PresetKey.last90:
      start = today.subtract(const Duration(days: 89));
      end = today;
      break;
    case _PresetKey.ytd:
      start = DateTime(today.year, 1, 1);
      end = today;
      break;
    case _PresetKey.lastYear:
      start = DateTime(today.year - 1, 1, 1);
      end = DateTime(today.year - 1, 12, 31);
      break;
  }
  if (start.isBefore(firstAllowed)) start = firstAllowed;
  if (end.isAfter(lastAllowed)) end = lastAllowed;
  if (end.isBefore(start)) end = start;
  return DateTimeRange(start: start, end: end);
}

class _AppDateRangePickerSheet extends StatefulWidget {
  const _AppDateRangePickerSheet({
    required this.firstDate,
    required this.lastDate,
    this.initialRange,
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final DateTimeRange? initialRange;

  @override
  State<_AppDateRangePickerSheet> createState() =>
      _AppDateRangePickerSheetState();
}

class _AppDateRangePickerSheetState extends State<_AppDateRangePickerSheet> {
  /// Inclusive start of the active selection. `null` means nothing picked yet.
  DateTime? _start;

  /// Inclusive end of the active selection. `null` means the user has tapped
  /// only one endpoint so far.
  DateTime? _end;

  late int _totalMonths;
  late int _currentMonthIdx;
  late PageController _pageController;
  _PresetKey? _activePreset;

  @override
  void initState() {
    super.initState();

    final DateTime firstMonth = DateTime(widget.firstDate.year, widget.firstDate.month, 1);
    final DateTime lastMonth = DateTime(widget.lastDate.year, widget.lastDate.month, 1);
    _totalMonths = _monthsBetween(firstMonth, lastMonth) + 1;

    final DateTimeRange? init = widget.initialRange;
    if (init != null) {
      _start = init.start;
      _end = init.end;
      _currentMonthIdx = _monthsBetween(firstMonth, DateTime(init.start.year, init.start.month, 1));
    } else {
      _currentMonthIdx = _totalMonths - 1;
    }
    _currentMonthIdx = _currentMonthIdx.clamp(0, _totalMonths - 1);
    _pageController = PageController(initialPage: _currentMonthIdx);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _monthAt(int idx) =>
      _addMonths(DateTime(widget.firstDate.year, widget.firstDate.month, 1), idx);

  void _onDayTap(DateTime day) {
    if (day.isBefore(widget.firstDate) || day.isAfter(widget.lastDate)) return;
    AppHaptics.selection();
    setState(() {
      _activePreset = null;
      // Tapping after a complete range clears it and starts a new selection.
      if (_start == null || (_start != null && _end != null)) {
        _start = day;
        _end = null;
        return;
      }
      // Anchored on _start; second tap defines _end (auto-swap if before).
      if (day.isBefore(_start!)) {
        _start = day;
        _end = null;
      } else {
        _end = day;
      }
    });
  }

  void _applyPreset(_PresetSpec spec) {
    AppHaptics.selection();
    final DateTimeRange r =
        _rangeFromPreset(spec.key, widget.firstDate, widget.lastDate);
    setState(() {
      _start = r.start;
      _end = r.end;
      _activePreset = spec.key;
      _currentMonthIdx = _monthsBetween(
        DateTime(widget.firstDate.year, widget.firstDate.month, 1),
        DateTime(r.start.year, r.start.month, 1),
      ).clamp(0, _totalMonths - 1);
    });
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        _currentMonthIdx,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _reset() {
    AppHaptics.light();
    setState(() {
      _start = null;
      _end = null;
      _activePreset = null;
    });
  }

  void _apply() {
    AppHaptics.light();
    if (_start == null) {
      Navigator.of(context).pop();
      return;
    }
    final DateTime s = _start!;
    final DateTime e = _end ?? _start!;
    Navigator.of(context).pop(DateTimeRange(start: s, end: e));
  }

  void _stepMonth(int delta) {
    final int target = (_currentMonthIdx + delta).clamp(0, _totalMonths - 1);
    if (target == _currentMonthIdx) return;
    AppHaptics.selection();
    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final Size size = MediaQuery.sizeOf(context);
    final double insetBottom = MediaQuery.viewInsetsOf(context).bottom;
    // Side-by-side mode kicks in whenever vertical room is tight (landscape
    // phones, floating/split-screen windows). Portrait phones and tablet
    // landscape (height ≥ 600) keep the stacked layout.
    final bool isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final bool useTwoPane = isLandscape && size.height < 600;
    final double maxH = size.height * (useTwoPane ? 0.96 : 0.92);

    return Padding(
      padding: EdgeInsets.only(bottom: insetBottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          constraints: BoxConstraints(maxHeight: maxH),
          decoration: BoxDecoration(
            color: p.surfaceElevated,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: p.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: useTwoPane ? _buildTwoPane(p) : _buildSinglePane(p),
          ),
        ),
      ),
    );
  }

  Widget _buildSinglePane(AppPalette p) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildHandle(p),
        _buildHeader(p),
        _buildPresets(p),
        _buildSummary(p),
        _buildMonthNav(p),
        _buildWeekdayHeader(p),
        Flexible(child: _buildMonthPager(p)),
        _buildFooter(p),
      ],
    );
  }

  /// Compact landscape layout: header/presets/summary on the left, the actual
  /// calendar (month nav + grid) on the right. Stacking everything vertically
  /// in landscape squeezed the calendar to a sliver.
  Widget _buildTwoPane(AppPalette p) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildHandle(p),
        Flexible(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                width: 280,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _buildHeader(p),
                      _buildPresets(p),
                      _buildSummary(p),
                    ],
                  ),
                ),
              ),
              Container(width: 1, color: p.border),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _buildMonthNav(p),
                    _buildWeekdayHeader(p),
                    Expanded(child: _buildMonthPager(p)),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildFooter(p),
      ],
    );
  }

  Widget _buildHandle(AppPalette p) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: p.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppPalette p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 8, 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Select date range',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: p.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  _start == null
                      ? 'Tap a day to start'
                      : (_end == null
                          ? 'Pick the end day'
                          : 'Tap any day to start over'),
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: p.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: p.textSecondary),
            onPressed: () {
              AppHaptics.light();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPresets(AppPalette p) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _kPresets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, int i) {
          final _PresetSpec spec = _kPresets[i];
          final bool active = _activePreset == spec.key;
          return _PresetChip(
            label: spec.label,
            active: active,
            palette: p,
            onTap: () => _applyPreset(spec),
          );
        },
      ),
    );
  }

  Widget _buildSummary(AppPalette p) {
    final DateFormat fmt = DateFormat('MMM d, yyyy');
    final String startText =
        _start == null ? '—' : fmt.format(_start!);
    final String endText = _end == null ? '—' : fmt.format(_end!);
    final int? days = (_start != null && _end != null)
        ? _end!.difference(_start!).inDays + 1
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.border),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: _SummaryEndpoint(
                label: 'FROM',
                value: startText,
                active: _start != null,
                palette: p,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: p.textSecondary.withValues(alpha: 0.8),
              ),
            ),
            Expanded(
              child: _SummaryEndpoint(
                label: 'TO',
                value: endText,
                active: _end != null,
                palette: p,
                alignEnd: true,
              ),
            ),
            if (days != null) ...<Widget>[
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: p.mint.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: p.mint.withValues(alpha: 0.45)),
                ),
                child: Text(
                  days == 1 ? '1 day' : '$days days',
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: p.mint,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMonthNav(AppPalette p) {
    final DateTime current = _monthAt(_currentMonthIdx);
    final String label = DateFormat('MMMM yyyy').format(current);
    final bool canPrev = _currentMonthIdx > 0;
    final bool canNext = _currentMonthIdx < _totalMonths - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: canPrev ? () => _stepMonth(-1) : null,
            icon: const Icon(Icons.chevron_left_rounded),
            color: p.textPrimary,
            disabledColor: p.textSecondary.withValues(alpha: 0.4),
          ),
          Expanded(
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      color: p.textPrimary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
              ),
            ),
          ),
          IconButton(
            onPressed: canNext ? () => _stepMonth(1) : null,
            icon: const Icon(Icons.chevron_right_rounded),
            color: p.textPrimary,
            disabledColor: p.textSecondary.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader(AppPalette p) {
    // Sunday-first to match the rest of the app's week math
    // (`reportController.getTimeFrame` treats Sunday as day 0).
    const List<String> labels = <String>['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: Row(
        children: labels
            .map(
              (String s) => Expanded(
                child: Center(
                  child: Text(
                    s,
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: p.textSecondary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildMonthPager(AppPalette p) {
    // The grid scales its row height to whatever vertical room the parent
    // hands down — preferred max of 44, but it will shrink to as little as
    // 30 in cramped layouts (e.g. landscape phones) so 6 rows always fit
    // without overflowing the inner Column.
    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints constraints) {
        final double available = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : _kMaxRowHeight * 6;
        final double rowH =
            (available / 6).clamp(_kMinRowHeight, _kMaxRowHeight);
        return SizedBox(
          height: rowH * 6,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _totalMonths,
            onPageChanged: (int idx) {
              AppHaptics.selection();
              setState(() => _currentMonthIdx = idx);
            },
            itemBuilder: (BuildContext _, int idx) {
              final DateTime m = _monthAt(idx);
              return _MonthGrid(
                month: m,
                firstAllowed: widget.firstDate,
                lastAllowed: widget.lastDate,
                start: _start,
                end: _end,
                palette: p,
                onDayTap: _onDayTap,
                rowHeight: rowH,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFooter(AppPalette p) {
    final bool hasSelection = _start != null;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        child: Row(
          children: <Widget>[
            TextButton(
              onPressed: hasSelection ? _reset : null,
              style: TextButton.styleFrom(
                foregroundColor: p.textSecondary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text('Reset'),
            ),
            const Spacer(),
            SizedBox(
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: p.mint,
                  foregroundColor: Colors.black87,
                  disabledBackgroundColor: p.mint.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                ),
                onPressed: hasSelection ? _apply : null,
                child: Text(
                  'Apply',
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryEndpoint extends StatelessWidget {
  const _SummaryEndpoint({
    required this.label,
    required this.value,
    required this.active,
    required this.palette,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool active;
  final AppPalette palette;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: palette.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
                color: active ? palette.textPrimary : palette.textSecondary,
                fontWeight: FontWeight.w600,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.active,
    required this.palette,
    required this.onTap,
  });

  final String label;
  final bool active;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active
          ? palette.mint.withValues(alpha: 0.16)
          : palette.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active
                  ? palette.mint.withValues(alpha: 0.55)
                  : palette.border,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: active ? palette.mint : palette.textPrimary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

const double _kMaxRowHeight = 44.0;
// Floor low enough that 6 rows still fit when the calendar pane is squeezed
// (e.g. narrow landscape phones); below ~22 the day numbers stop being
// readable so we'd rather clip a row than continue shrinking.
const double _kMinRowHeight = 22.0;

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.firstAllowed,
    required this.lastAllowed,
    required this.start,
    required this.end,
    required this.palette,
    required this.onDayTap,
    required this.rowHeight,
  });

  final DateTime month;
  final DateTime firstAllowed;
  final DateTime lastAllowed;
  final DateTime? start;
  final DateTime? end;
  final AppPalette palette;
  final ValueChanged<DateTime> onDayTap;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    final int daysInThis = _daysInMonth(month.year, month.month);
    final DateTime firstOfMonth = DateTime(month.year, month.month, 1);
    // Sunday=0, Saturday=6.
    final int leading = firstOfMonth.weekday % 7;
    final int totalCells = leading + daysInThis;
    final int rows = (totalCells / 7).ceil();

    final List<Widget> rowWidgets = <Widget>[];
    for (int r = 0; r < rows; r++) {
      final List<Widget> cells = <Widget>[];
      for (int c = 0; c < 7; c++) {
        final int cellIdx = r * 7 + c;
        final int dayNum = cellIdx - leading + 1;
        if (dayNum < 1 || dayNum > daysInThis) {
          cells.add(Expanded(child: SizedBox(height: rowHeight)));
        } else {
          final DateTime day = DateTime(month.year, month.month, dayNum);
          cells.add(
            Expanded(
              child: _DayCell(
                day: day,
                firstAllowed: firstAllowed,
                lastAllowed: lastAllowed,
                start: start,
                end: end,
                palette: palette,
                onTap: () => onDayTap(day),
                isFirstInRow: c == 0,
                isLastInRow: c == 6,
                rowHeight: rowHeight,
              ),
            ),
          );
        }
      }
      rowWidgets.add(Row(children: cells));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: rowWidgets,
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.firstAllowed,
    required this.lastAllowed,
    required this.start,
    required this.end,
    required this.palette,
    required this.onTap,
    required this.isFirstInRow,
    required this.isLastInRow,
    required this.rowHeight,
  });

  final DateTime day;
  final DateTime firstAllowed;
  final DateTime lastAllowed;
  final DateTime? start;
  final DateTime? end;
  final AppPalette palette;
  final VoidCallback onTap;
  final bool isFirstInRow;
  final bool isLastInRow;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    final bool disabled =
        day.isBefore(firstAllowed) || day.isAfter(lastAllowed);
    final bool isStart = start != null && _isSameDay(day, start!);
    final bool isEnd = end != null && _isSameDay(day, end!);
    final bool isSame =
        start != null && end != null && _isSameDay(start!, end!) && isStart;
    final bool inRange = start != null &&
        end != null &&
        day.isAfter(start!) &&
        day.isBefore(end!);

    final bool now = _isSameDay(day, DateTime.now());

    // Track corner radius tracks the row height so it always reads as a pill
    // around the endpoint circle even when rows shrink in landscape.
    final double trackCorner = rowHeight / 2;

    // Range track: a continuous translucent rail under the row that connects
    // the two endpoints. Endpoints get half-open rounding so the solid circle
    // sits on a flush track edge.
    Color trackColor = Colors.transparent;
    BorderRadius trackRadius = BorderRadius.zero;
    if (!isSame) {
      if (isStart && end != null) {
        trackColor = palette.mint.withValues(alpha: 0.16);
        trackRadius =
            BorderRadius.horizontal(left: Radius.circular(trackCorner));
      } else if (isEnd && start != null) {
        trackColor = palette.mint.withValues(alpha: 0.16);
        trackRadius =
            BorderRadius.horizontal(right: Radius.circular(trackCorner));
      } else if (inRange) {
        trackColor = palette.mint.withValues(alpha: 0.16);
        // Wrap rounding when a day lands at the row edge so the rail terminates
        // cleanly instead of bleeding off into the gutter.
        if (isFirstInRow && isLastInRow) {
          trackRadius = BorderRadius.circular(trackCorner);
        } else if (isFirstInRow) {
          trackRadius =
              BorderRadius.horizontal(left: Radius.circular(trackCorner));
        } else if (isLastInRow) {
          trackRadius =
              BorderRadius.horizontal(right: Radius.circular(trackCorner));
        }
      }
    }

    Color textColor;
    FontWeight textWeight = FontWeight.w500;
    if (disabled) {
      textColor = palette.textSecondary.withValues(alpha: 0.35);
    } else if (isStart || isEnd) {
      textColor = Colors.black87;
      textWeight = FontWeight.w700;
    } else if (inRange) {
      textColor = palette.textPrimary;
      textWeight = FontWeight.w600;
    } else {
      textColor = palette.textPrimary;
    }

    final double circleSize = (rowHeight - 6).clamp(24.0, 38.0);
    // Day numbers shrink slightly in compact rows so a "27" still sits inside
    // the circle without clipping.
    final double dayFontSize = rowHeight < 36 ? 12.0 : 14.0;

    final Widget circle = Container(
      width: circleSize,
      height: circleSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (isStart || isEnd) ? palette.mint : Colors.transparent,
        border: (now && !isStart && !isEnd && !inRange && !disabled)
            ? Border.all(color: palette.mint.withValues(alpha: 0.55), width: 1.4)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontSize: dayFontSize,
              color: textColor,
              fontWeight: textWeight,
            ),
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: disabled ? null : onTap,
      child: SizedBox(
        height: rowHeight,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            if (trackColor != Colors.transparent)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: trackColor,
                    borderRadius: trackRadius,
                  ),
                ),
              ),
            circle,
          ],
        ),
      ),
    );
  }
}
