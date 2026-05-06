import 'package:balance_sheet/theme/app_palette.dart';
import 'package:balance_sheet/widgets/midnight_grid_painter.dart';
import 'package:balance_sheet/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// Shell for tabs that do not have features yet (no-op).
class PlaceholderTab extends StatelessWidget {
  const PlaceholderTab({
    super.key,
    required this.title,
    this.subtitle = 'Coming soon',
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
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
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    EmptyStateIconFrame(
                      padding: const EdgeInsets.all(22),
                      child: Icon(
                        Icons.hourglass_empty_rounded,
                        size: 56,
                        color: p.mint.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineSmall!.copyWith(
                                color: p.textPrimary,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            color: p.textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
