import 'package:balance_sheet/constants/colors.dart';
import 'package:balance_sheet/constants/db.dart';
import 'package:balance_sheet/debug/debug_data_clear_service.dart';
import 'package:balance_sheet/theme/app_palette.dart';
import 'package:balance_sheet/utils/app_haptics.dart';
import 'package:balance_sheet/widgets/midnight_grid_painter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Debug-only screen to wipe selected tables / [GetStorage] keys. Not reachable when [kDebugMode] is false.
class DebugClearDataScreen extends StatefulWidget {
  const DebugClearDataScreen({super.key});

  @override
  State<DebugClearDataScreen> createState() => _DebugClearDataScreenState();
}

class _DebugClearDataScreenState extends State<DebugClearDataScreen> {
  final Set<DebugDataClearTarget> _selected = <DebugDataClearTarget>{};
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(body: Center(child: Text('Unavailable')));
    }

    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppPalette p = AppPalette.of(context);

    return Scaffold(
      backgroundColor: p.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: MidnightGridPainter(heightFraction: 1.0, gridLineColor: p.gridLine),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _busy ? null : () => Get.back(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: p.textPrimary,
                      ),
                      Expanded(
                        child: Text(
                          'Clear local data',
                          style: textTheme.titleLarge!.copyWith(color: p.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Text(
                    'Debug builds only. Choose tables and/or stored settings, then confirm. This cannot be undone.',
                    style: textTheme.bodySmall!.copyWith(
                      color: p.textSecondary.withValues(alpha: 0.95),
                      height: 1.35,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('All database'),
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                  _selected.addAll(DebugDataClearService.allDatabaseTargets);
                                }),
                      ),
                      ActionChip(
                        label: const Text('All settings'),
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                  _selected.addAll(DebugDataClearService.allPreferenceTargets);
                                }),
                      ),
                      ActionChip(
                        label: const Text('Everything'),
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                  _selected.addAll(DebugDataClearService.allTargets);
                                }),
                      ),
                      ActionChip(
                        label: const Text('Clear selection'),
                        onPressed: _busy ? null : () => setState(_selected.clear),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      _sectionLabel(context, 'Ledger'),
                      _targetTile(
                        context,
                        target: DebugDataClearTarget.transactions,
                        title: 'Transaction records',
                        caption: 'SQLite: ${DBConstants.TRANSACTION}',
                      ),
                      _targetTile(
                        context,
                        target: DebugDataClearTarget.contacts,
                        title: 'Contacts',
                        caption: 'SQLite: ${DBConstants.CONTACT}',
                      ),
                      const SizedBox(height: 20),
                      _sectionLabel(context, 'Budget'),
                      _targetTile(
                        context,
                        target: DebugDataClearTarget.budget,
                        title: 'Budget months & lines',
                        caption: 'SQLite: ${DBConstants.BUDGET_LINE}, ${DBConstants.BUDGET_MONTH}',
                      ),
                      const SizedBox(height: 20),
                      _sectionLabel(context, 'Investments'),
                      _targetTile(
                        context,
                        target: DebugDataClearTarget.investmentStocks,
                        title: 'Stock positions & history',
                        caption:
                            'SQLite: ${DBConstants.INVESTMENT_HOLDING}, ${DBConstants.INVESTMENT_LOT}, ${DBConstants.INVESTMENT_PRICE} (together)',
                      ),
                      _targetTile(
                        context,
                        target: DebugDataClearTarget.investmentOther,
                        title: 'Other investment assets',
                        caption: 'SQLite: ${DBConstants.INVESTMENT_OTHER_ASSET}',
                      ),
                      const SizedBox(height: 20),
                      _sectionLabel(context, 'Stored settings'),
                      _targetTile(
                        context,
                        target: DebugDataClearTarget.prefAppearance,
                        title: 'Appearance',
                        caption: 'Theme mode and font (GetStorage)',
                      ),
                      _targetTile(
                        context,
                        target: DebugDataClearTarget.prefCurrency,
                        title: 'Currency & rate',
                        caption: 'LCY/FCY codes and manual rate (GetStorage)',
                      ),
                      _targetTile(
                        context,
                        target: DebugDataClearTarget.prefSecurity,
                        title: 'PIN & biometrics',
                        caption: 'PIN hash/salt and fingerprint flag (GetStorage)',
                      ),
                      _targetTile(
                        context,
                        target: DebugDataClearTarget.prefSlidablePeek,
                        title: 'First-run UI tips',
                        caption: 'Slidable row peeks and home balance / net worth coach (GetStorage)',
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: FilledButton(
                    onPressed: _busy || _selected.isEmpty ? null : _onClearPressed,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.SNACKBAR_RED,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _busy
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Delete selected'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppPalette p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: textTheme.labelMedium!.copyWith(
          letterSpacing: 1.4,
          color: p.textSecondary.withValues(alpha: 0.9),
        ),
      ),
    );
  }

  Widget _targetTile(
    BuildContext context, {
    required DebugDataClearTarget target,
    required String title,
    required String caption,
  }) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppPalette p = AppPalette.of(context);
    final bool on = _selected.contains(target);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _busy
              ? null
              : () {
                  AppHaptics.selection();
                  setState(() {
                    if (on) {
                      _selected.remove(target);
                    } else {
                      _selected.add(target);
                    }
                  });
                },
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: p.surface,
              border: Border.all(color: on ? p.mint.withValues(alpha: 0.45) : p.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  on ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                  color: on ? p.mint : p.textSecondary,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleMedium!.copyWith(color: p.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        caption,
                        style: textTheme.bodySmall!.copyWith(
                          color: p.textSecondary.withValues(alpha: 0.9),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onClearPressed() async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        final AppPalette p = AppPalette.of(ctx);
        final TextTheme tt = Theme.of(ctx).textTheme;
        return AlertDialog(
          backgroundColor: p.surface,
          title: Text(
            'Delete ${_selected.length} selection(s)?',
            style: tt.titleLarge?.copyWith(color: p.textPrimary),
          ),
          content: Text(
            'This permanently removes the selected rows and/or keys from this device.',
            style: tt.bodyMedium?.copyWith(color: p.textSecondary, height: 1.35),
          ),
          actions: [
            TextButton(
              onPressed: () {
                AppHaptics.light();
                Navigator.of(ctx).pop(false);
              },
              child: Text('Cancel', style: TextStyle(color: p.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                AppHaptics.medium();
                Navigator.of(ctx).pop(true);
              },
              child: Text('Delete', style: TextStyle(color: AppColors.SNACKBAR_RED)),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await DebugDataClearService.apply(Set<DebugDataClearTarget>.from(_selected));
      if (!mounted) return;
      setState(() {
        _selected.clear();
        _busy = false;
      });
      Get.snackbar(
        'Cleared',
        'Removed selected data.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.GREEN,
        colorText: Colors.white,
      );
    } catch (e, st) {
      debugPrint('$e\n$st');
      if (!mounted) return;
      Get.snackbar(
        'Clear failed',
        '$e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.SNACKBAR_RED,
        colorText: Colors.white,
      );
    } finally {
      if (mounted && _busy) {
        setState(() => _busy = false);
      }
    }
  }
}
