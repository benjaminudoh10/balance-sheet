import 'package:balance_sheet/constants/colors.dart';
import 'package:balance_sheet/debug/debug_data_seed_service.dart';
import 'package:balance_sheet/theme/app_palette.dart';
import 'package:balance_sheet/utils/app_haptics.dart';
import 'package:balance_sheet/widgets/midnight_grid_painter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Debug-only screen that loads a full sample dataset. Not reachable when [kDebugMode] is false.
class DebugSeedDataScreen extends StatefulWidget {
  const DebugSeedDataScreen({super.key});

  @override
  State<DebugSeedDataScreen> createState() => _DebugSeedDataScreenState();
}

class _DebugSeedDataScreenState extends State<DebugSeedDataScreen> {
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
              painter: MidnightGridPainter(
                  heightFraction: 1.0, gridLineColor: p.gridLine),
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
                          'Seed sample data',
                          style: textTheme.titleLarge!
                              .copyWith(color: p.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Text(
                    'Debug builds only. Replaces all ledger, budget, and investment rows with a '
                    'randomized multi-month demo (amounts, dates, and portfolio marks differ each run). '
                    'Theme, currency, and PIN settings are left unchanged.',
                    style: textTheme.bodySmall!.copyWith(
                      color: p.textSecondary.withValues(alpha: 0.95),
                      height: 1.35,
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: FilledButton(
                    onPressed: _busy ? null : _onSeedPressed,
                    style: FilledButton.styleFrom(
                      backgroundColor: p.mint,
                      foregroundColor: p.background,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _busy
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Load sample data'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSeedPressed() async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        final AppPalette pal = AppPalette.of(ctx);
        final TextTheme tt = Theme.of(ctx).textTheme;
        return AlertDialog(
          backgroundColor: pal.surface,
          title: Text(
            'Replace with sample data?',
            style: tt.titleLarge?.copyWith(color: pal.textPrimary),
          ),
          content: Text(
            'This removes existing transactions, contacts, budgets, and investments on this device, '
            'then inserts demo content.',
            style:
                tt.bodyMedium?.copyWith(color: pal.textSecondary, height: 1.35),
          ),
          actions: [
            TextButton(
              onPressed: () {
                AppHaptics.light();
                Navigator.of(ctx).pop(false);
              },
              child: Text('Cancel', style: TextStyle(color: pal.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                AppHaptics.medium();
                Navigator.of(ctx).pop(true);
              },
              child: Text('Load sample', style: TextStyle(color: pal.mint)),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await DebugDataSeedService.apply();
      if (!mounted) return;
      Get.snackbar(
        'Sample data loaded',
        'Ledger, budget, and investments updated.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.GREEN,
        colorText: Colors.white,
      );
    } catch (e, st) {
      debugPrint('$e\n$st');
      if (!mounted) return;
      Get.snackbar(
        'Seed failed',
        '$e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.SNACKBAR_RED,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}
