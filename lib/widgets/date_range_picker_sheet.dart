import 'package:balance_sheet/theme/app_palette.dart';
import 'package:balance_sheet/utils/app_haptics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    isDismissible: true,
    enableDrag: true,
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

  /// Toggles between the calendar grid and a Material-style "type the dates"
  /// view, so users can jump to a date in the distant past without paging
  /// through every month.
  bool _isInputMode = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// Bumped on Reset so the input fields rebuild from their (now empty)
  /// initial values — the typed-date field owns its `TextEditingController`
  /// so a value-key change is the cleanest way to clear it.
  int _formGeneration = 0;

  /// Held by the typed-date fields so we can move focus programmatically:
  /// auto-open the keyboard on the start field when input mode opens, and
  /// jump to the end field once the user finishes typing the start date
  /// (works on iOS, whose number pad has no on-keyboard Next button).
  final FocusNode _startFocus = FocusNode(debugLabel: 'rangePickerStart');
  final FocusNode _endFocus = FocusNode(debugLabel: 'rangePickerEnd');

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
    _startFocus.dispose();
    _endFocus.dispose();
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
      // Force the input fields to rebuild with empty initial values when the
      // user is in type-mode.
      _formGeneration++;
    });
  }

  void _apply() {
    AppHaptics.light();
    // If the user typed dates without submitting the keyboard, save the form
    // so [onDateSaved] runs and `_start` / `_end` reflect what's on screen.
    if (_isInputMode) {
      final FormState? form = _formKey.currentState;
      if (form != null) {
        if (!form.validate()) return;
        form.save();
      }
    }
    if (_start == null) {
      Navigator.of(context).pop();
      return;
    }
    DateTime s = _start!;
    DateTime e = _end ?? _start!;
    // If the user typed an end date that's earlier than the start, swap them
    // so we always return a forward range to the controller.
    if (e.isBefore(s)) {
      final DateTime tmp = s;
      s = e;
      e = tmp;
    }
    Navigator.of(context).pop(DateTimeRange(start: s, end: e));
  }

  void _toggleInputMode() {
    AppHaptics.light();
    if (_isInputMode) {
      // Commit whatever's already in the fields so partial entries aren't
      // lost when backing into the calendar. The typed-date field's
      // `onSaved` only commits cleanly parseable, in-range dates so
      // invalid/empty fields are harmless here.
      _formKey.currentState?.save();
      _startFocus.unfocus();
      _endFocus.unfocus();
    }
    setState(() {
      _isInputMode = !_isInputMode;
    });
    if (_isInputMode) {
      // Wait for the input view to be in the tree, then bring up the
      // keyboard automatically focused on the start field.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        FocusScope.of(context).requestFocus(_startFocus);
      });
      return;
    }
    // After returning to the calendar, scroll to the start month so the
    // user lands where they expect.
    if (_start != null && _pageController.hasClients) {
      final int idx = _monthsBetween(
        DateTime(widget.firstDate.year, widget.firstDate.month, 1),
        DateTime(_start!.year, _start!.month, 1),
      ).clamp(0, _totalMonths - 1);
      if (idx != _currentMonthIdx) {
        _pageController.animateToPage(
          idx,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  DateTime _clampDate(DateTime d) {
    if (d.isBefore(widget.firstDate)) return widget.firstDate;
    if (d.isAfter(widget.lastDate)) return widget.lastDate;
    return d;
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
    final double desiredMaxH = size.height * (useTwoPane ? 0.96 : 0.92);
    final double availableAboveKeyboard =
        (size.height - insetBottom - 12).clamp(96.0, size.height);
    final double maxH = desiredMaxH < availableAboveKeyboard
        ? desiredMaxH
        : availableAboveKeyboard;

    return Padding(
      padding: EdgeInsets.only(bottom: insetBottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
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
            child: _isInputMode
                ? _buildInputView(p)
                : (useTwoPane ? _buildTwoPane(p) : _buildSinglePane(p)),
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

  /// Type-the-dates view (parity with the platform date range picker's edit
  /// mode). Two text fields, locale-aware parsing/validation, and the same
  /// summary + footer as the calendar view so users can type a date in the
  /// distant past in seconds.
  Widget _buildInputView(AppPalette p) {
    final DateTime initialStart = _clampDate(_start ?? widget.lastDate);
    final DateTime initialEnd =
        _clampDate(_end ?? _start ?? widget.lastDate);

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _buildHandle(p),
          _buildHeader(p),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Theme(
                data: _appInputTheme(context, p),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _TypedDateField(
                      // Bump key on Reset so the controller text clears.
                      key: ValueKey<String>('start_$_formGeneration'),
                      label: 'Start date',
                      initialDate: _start == null ? null : initialStart,
                      firstDate: widget.firstDate,
                      lastDate: widget.lastDate,
                      focusNode: _startFocus,
                      textInputAction: TextInputAction.next,
                      onCommit: (DateTime d) =>
                          _commitTypedDate(start: true, value: d),
                      onAdvance: () =>
                          FocusScope.of(context).requestFocus(_endFocus),
                    ),
                    const SizedBox(height: 12),
                    _TypedDateField(
                      key: ValueKey<String>('end_$_formGeneration'),
                      label: 'End date',
                      initialDate: _end == null && _start == null
                          ? null
                          : initialEnd,
                      firstDate: widget.firstDate,
                      lastDate: widget.lastDate,
                      focusNode: _endFocus,
                      textInputAction: TextInputAction.done,
                      onCommit: (DateTime d) =>
                          _commitTypedDate(start: false, value: d),
                      onAdvance: () => _endFocus.unfocus(),
                    ),
                    if (_start != null && _end != null) ...<Widget>[
                      const SizedBox(height: 14),
                      _TypedRangeBadge(
                        start: _start!,
                        end: _end!,
                        palette: p,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          _buildFooter(p),
        ],
      ),
    );
  }

  void _commitTypedDate({required bool start, required DateTime value}) {
    setState(() {
      if (start) {
        _start = value;
      } else {
        _end = value;
      }
      _activePreset = null;
    });
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
    final String subtitle;
    if (_isInputMode) {
      subtitle = 'Type the start and end dates';
    } else if (_start == null) {
      subtitle = 'Tap a day to start';
    } else if (_end == null) {
      subtitle = 'Pick the end day';
    } else {
      subtitle = 'Tap any day to start over';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 4, 8),
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
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: p.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: _isInputMode ? 'Switch to calendar' : 'Type dates',
            icon: Icon(
              _isInputMode
                  ? Icons.calendar_month_outlined
                  : Icons.edit_calendar_outlined,
              color: p.textSecondary,
            ),
            onPressed: _toggleInputMode,
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

/// App-themed `InputDecorationTheme` so `InputDatePickerFormField` (which
/// pulls its decoration from the ambient theme) matches the rest of the
/// sheet — surface fill, mint focus accent, coral error border.
ThemeData _appInputTheme(BuildContext context, AppPalette p) {
  final ThemeData base = Theme.of(context);
  OutlineInputBorder border(Color c, {double width = 1.0}) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: width),
      );
  return base.copyWith(
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface,
      isDense: false,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border(p.border),
      enabledBorder: border(p.border),
      focusedBorder: border(p.mint, width: 1.5),
      errorBorder: border(p.coral),
      focusedErrorBorder: border(p.coral, width: 1.5),
      labelStyle: TextStyle(color: p.textSecondary),
      floatingLabelStyle:
          TextStyle(color: p.mint, fontWeight: FontWeight.w600),
      hintStyle: TextStyle(color: p.textSecondary.withValues(alpha: 0.7)),
      helperStyle: TextStyle(color: p.textSecondary),
      errorStyle: TextStyle(color: p.coral),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.mint,
      selectionColor: p.mint.withValues(alpha: 0.3),
      selectionHandleColor: p.mint,
    ),
  );
}

/// Numeric date input with auto-formatting (`mm/dd/yyyy`), validation
/// against [firstDate]/[lastDate], focus management, and live commits to
/// the parent state.
///
/// Uses [TextInputType.number] so the OS shows a digit-only keypad — the
/// `/` separators are inserted by [_DateTextFormatter] as the user types,
/// so no `/` key is needed on the soft keyboard.
class _TypedDateField extends StatefulWidget {
  const _TypedDateField({
    super.key,
    required this.label,
    required this.firstDate,
    required this.lastDate,
    required this.initialDate,
    required this.focusNode,
    required this.textInputAction,
    required this.onCommit,
    required this.onAdvance,
  });

  final String label;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? initialDate;
  final FocusNode focusNode;
  final TextInputAction textInputAction;

  /// Fired whenever the field contains a valid in-range date — used both for
  /// live updates (e.g. the day-count badge) and for the Form's `save()`
  /// pass on Apply.
  final ValueChanged<DateTime> onCommit;

  /// Fired once when the user finishes typing the date (8 digits) or hits
  /// the keyboard's submit action; the parent uses this to advance focus
  /// to the next field or dismiss the keyboard.
  final VoidCallback onAdvance;

  @override
  State<_TypedDateField> createState() => _TypedDateFieldState();
}

class _TypedDateFieldState extends State<_TypedDateField> {
  late final TextEditingController _controller;
  late int _lastDigitCount;

  static const String _hintText = 'mm/dd/yyyy';

  @override
  void initState() {
    super.initState();
    final DateTime? init = widget.initialDate;
    final String text = init != null ? _formatDate(init) : '';
    _controller = TextEditingController(text: text);
    _lastDigitCount = _digitsOnly(text).length;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.month)}/${two(d.day)}/${d.year}';
  }

  static String _digitsOnly(String s) => s.replaceAll(RegExp(r'\D'), '');

  /// Strict parse: empty / partial entries return null so we never commit a
  /// half-typed date by accident.
  DateTime? _parse(String? text) {
    if (text == null) return null;
    final RegExpMatch? m =
        RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(text.trim());
    if (m == null) return null;
    final int mm = int.parse(m.group(1)!);
    final int dd = int.parse(m.group(2)!);
    final int yyyy = int.parse(m.group(3)!);
    if (mm < 1 || mm > 12 || dd < 1 || dd > 31) return null;
    final DateTime d = DateTime(yyyy, mm, dd);
    // Reject overflows like Feb 30 → Mar 2.
    if (d.month != mm || d.day != dd) return null;
    return d;
  }

  String? _validate(String? text) {
    if (text == null || text.isEmpty) return 'Enter a date';
    final DateTime? d = _parse(text);
    if (d == null) return 'Use $_hintText';
    if (d.isBefore(widget.firstDate) || d.isAfter(widget.lastDate)) {
      return 'Outside allowed range';
    }
    return null;
  }

  void _commitIfValid(String? text) {
    final DateTime? d = _parse(text ?? '');
    if (d == null) return;
    if (d.isBefore(widget.firstDate) || d.isAfter(widget.lastDate)) return;
    widget.onCommit(d);
  }

  void _onChanged(String text) {
    _commitIfValid(text);
    final int digitCount = _digitsOnly(text).length;
    final bool justCompleted = digitCount == 8 && _lastDigitCount < 8;
    _lastDigitCount = digitCount;
    if (!justCompleted) return;
    // Only auto-advance when the completed entry is actually a valid,
    // in-range date — otherwise we'd shove the user off a field that
    // still has a "Use mm/dd/yyyy" / "Outside allowed range" error.
    final DateTime? parsed = _parse(text);
    if (parsed == null) return;
    if (parsed.isBefore(widget.firstDate) ||
        parsed.isAfter(widget.lastDate)) {
      return;
    }
    widget.onAdvance();
  }

  void _onFieldSubmitted(String text) {
    _commitIfValid(text);
    widget.onAdvance();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: widget.focusNode,
      keyboardType: const TextInputType.numberWithOptions(
        signed: false,
        decimal: false,
      ),
      textInputAction: widget.textInputAction,
      inputFormatters: <TextInputFormatter>[_DateTextFormatter()],
      validator: _validate,
      onChanged: _onChanged,
      onFieldSubmitted: _onFieldSubmitted,
      onSaved: _commitIfValid,
      decoration: const InputDecoration(
        labelText: '',
        hintText: _hintText,
      ).copyWith(
        labelText: widget.label,
      ),
    );
  }
}

/// Strips everything but digits, caps at 8, then re-inserts `/` after the
/// month and the day so the visible text is always `mm`, `mm/dd`, or
/// `mm/dd/yyyy` while the user types.
class _DateTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final String clamped =
        digits.length > 8 ? digits.substring(0, 8) : digits;

    final StringBuffer buf = StringBuffer();
    for (int i = 0; i < clamped.length; i++) {
      if (i == 2 || i == 4) buf.write('/');
      buf.write(clamped[i]);
    }
    final String formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _TypedRangeBadge extends StatelessWidget {
  const _TypedRangeBadge({
    required this.start,
    required this.end,
    required this.palette,
  });

  final DateTime start;
  final DateTime end;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final DateTime ordered = end.isBefore(start) ? start : end;
    final DateTime orderedStart = end.isBefore(start) ? end : start;
    final int days = ordered.difference(orderedStart).inDays + 1;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: palette.mint.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: palette.mint.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.event_available_rounded,
                size: 16, color: palette.mint),
            const SizedBox(width: 6),
            Text(
              days == 1 ? '1 day selected' : '$days days selected',
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: palette.mint,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
            ),
          ],
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
