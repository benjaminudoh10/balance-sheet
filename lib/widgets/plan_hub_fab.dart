import 'package:balance_sheet/screens/budget_screen.dart';
import 'package:balance_sheet/screens/plan_stocks_screen.dart';
import 'package:balance_sheet/theme/app_palette.dart';
import 'package:balance_sheet/utils/app_haptics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Extra end padding for bottom controls on [Home] so they sit clear of [PlanHubFab] (58px + margin).
const double kPlanHubFabTrailingClearance = 76.0;

/// Expandable hub for plan-related flows (monthly budget, investments) without adding nav tabs.
class PlanHubFab extends StatelessWidget {
  const PlanHubFab({
    super.key,
    required this.expanded,
    required this.onExpandedChanged,
  });

  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;

  void _go(Widget page) {
    AppHaptics.light();
    onExpandedChanged(false);
    Get.to(() => page);
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: expanded
              ? IntrinsicWidth(
                  key: const ValueKey<String>('open'),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _HubActionPill(
                        label: 'Monthly budget',
                        subtitle: 'Planned spending',
                        icon: Icons.event_note_rounded,
                        accent: p.mint,
                        onTap: () => _go(const BudgetScreen()),
                      ),
                      const SizedBox(height: 10),
                      _HubActionPill(
                        label: 'Investments',
                        subtitle: 'Stocks & manual prices',
                        icon: Icons.candlestick_chart_rounded,
                        accent: const Color(0xFF818CF8),
                        onTap: () => _go(const PlanStocksScreen()),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                )
              : const SizedBox(key: ValueKey<String>('closed'), height: 0),
        ),
        Hero(
          tag: 'plan_hub_fab',
          child: Material(
            elevation: expanded ? 10 : 6,
            shadowColor: p.mint.withValues(alpha: expanded ? 0.45 : 0.35),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                AppHaptics.light();
                onExpandedChanged(!expanded);
              },
              child: Ink(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      p.mint.withValues(alpha: 0.95),
                      const Color(0xFF2DD4BF).withValues(alpha: 0.9),
                    ],
                  ),
                ),
                child: Icon(
                  expanded ? Icons.close_rounded : Icons.dashboard_customize_rounded,
                  color: const Color(0xFF0D1117),
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HubActionPill extends StatelessWidget {
  const _HubActionPill({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: AppHaptics.wrap(onTap),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: p.surfaceElevated,
            border: Border.all(color: accent.withValues(alpha: 0.4)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: accent.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(icon, color: accent, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            color: p.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            color: p.textSecondary,
                            letterSpacing: 0.2,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: p.textSecondary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
