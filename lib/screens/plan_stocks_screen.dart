import 'package:balance_sheet/theme/app_palette.dart';
import 'package:balance_sheet/widgets/midnight_grid_painter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Placeholder for stock holdings and other balance-sheet assets — feeds a future net-worth dashboard.
class PlanStocksScreen extends StatelessWidget {
  const PlanStocksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: p.textPrimary,
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Investments',
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                color: p.textPrimary,
                letterSpacing: -0.4,
              ),
        ),
        centerTitle: false,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned.fill(
            child: CustomPaint(
              painter: MidnightGridPainter(heightFraction: 1.0, gridLineColor: p.gridLine),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: 12),
                  Icon(Icons.auto_graph_rounded, size: 56, color: p.mint.withValues(alpha: 0.85)),
                  const SizedBox(height: 20),
                  Text(
                    'Coming soon',
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                          color: p.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Track stocks and other assets here. Totals will roll into a future net-worth view alongside your cashflow balance.',
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: p.textSecondary,
                          height: 1.45,
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
