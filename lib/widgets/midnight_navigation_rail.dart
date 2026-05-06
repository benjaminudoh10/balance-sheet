import 'dart:math' as math;

import 'package:balance_sheet/controllers/app_controller.dart';
import 'package:balance_sheet/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Left [NavigationRail] for tablet / desktop — same destinations as [MidnightBottomNav].
class MidnightNavigationRail extends StatelessWidget {
  const MidnightNavigationRail({super.key});

  /// [NavigationRail] uses internal [Expanded] and requires a finite max height. A
  /// [SingleChildScrollView] gives its child unbounded max height, so we wrap the rail in a
  /// [SizedBox] at least this tall — enough for leading + 5 destinations with labels — then
  /// scroll when the viewport (e.g. landscape + keyboard) is shorter.
  static const double _kRailMinOuterHeight = 472.0;

  @override
  Widget build(BuildContext context) {
    final AppController controller = Get.find();
    final AppPalette p = AppPalette.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Obx(() {
      final int index = controller.index.value;

      return Material(
        color: p.surface,
        elevation: 0,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double viewH = constraints.maxHeight;
            final double outerH = viewH.isFinite
                ? math.max(viewH, _kRailMinOuterHeight)
                : _kRailMinOuterHeight;
            return SingleChildScrollView(
              clipBehavior: Clip.hardEdge,
              physics: const ClampingScrollPhysics(),
              child: SizedBox(
                height: outerH,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      right:
                          BorderSide(color: p.border.withValues(alpha: 0.55)),
                    ),
                  ),
                  child: NavigationRailTheme(
                    data: NavigationRailThemeData(
                      backgroundColor: p.surface,
                      indicatorColor: p.mint.withValues(alpha: 0.18),
                      selectedIconTheme: IconThemeData(color: p.mint, size: 24),
                      unselectedIconTheme:
                          IconThemeData(color: p.textSecondary, size: 22),
                      selectedLabelTextStyle: textTheme.labelMedium!.copyWith(
                        color: p.mint,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelTextStyle: textTheme.labelMedium!.copyWith(
                        color: p.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    child: NavigationRail(
                      minWidth: 80,
                      selectedIndex: index,
                      onDestinationSelected: controller.setIndex,
                      labelType: NavigationRailLabelType.all,
                      useIndicator: true,
                      leading: const SizedBox(height: 8),
                      destinations: const <NavigationRailDestination>[
                        NavigationRailDestination(
                          icon: Icon(Icons.home_outlined),
                          selectedIcon: Icon(Icons.home_rounded),
                          label: Text('Home'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.account_balance_wallet_outlined),
                          selectedIcon:
                              Icon(Icons.account_balance_wallet_rounded),
                          label: Text('Contacts'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.pie_chart_outline_rounded),
                          selectedIcon: Icon(Icons.pie_chart_rounded),
                          label: Text('Budgets'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.insights_outlined),
                          selectedIcon: Icon(Icons.insights_rounded),
                          label: Text('Insights'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.settings_outlined),
                          selectedIcon: Icon(Icons.settings_rounded),
                          label: Text('Settings'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
