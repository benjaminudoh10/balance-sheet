import 'package:balance_sheet/controllers/app_controller.dart';
import 'package:balance_sheet/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MidnightBottomNav extends StatelessWidget {
  const MidnightBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final AppController controller = Get.find();
    final AppPalette p = AppPalette.of(context);

    return Obx(() {
      final int index = controller.index.value;
      return Material(
        color: p.surface,
        elevation: 8,
        child: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: p.border.withValues(alpha: 0.6)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  selected: index == 0,
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  label: 'Home',
                  onTap: () => controller.setIndex(0),
                ),
                _NavItem(
                  selected: index == 1,
                  icon: Icons.account_balance_wallet_outlined,
                  selectedIcon: Icons.account_balance_wallet_rounded,
                  label: 'Contacts',
                  onTap: () => controller.setIndex(1),
                ),
                _NavItem(
                  selected: index == 2,
                  icon: Icons.pie_chart_outline_rounded,
                  selectedIcon: Icons.pie_chart_rounded,
                  label: 'Budgets',
                  onTap: () => controller.setIndex(2),
                ),
                _NavItem(
                  selected: index == 3,
                  icon: Icons.insights_outlined,
                  selectedIcon: Icons.insights_rounded,
                  label: 'Insights',
                  onTap: () => controller.setIndex(3),
                ),
                _NavItem(
                  selected: index == 4,
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings_rounded,
                  label: 'Settings',
                  onTap: () => controller.setIndex(4),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final Color active = p.mint;
    final Color inactive = p.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: active.withValues(alpha: 0.12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 3,
                width: selected ? 28 : 0,
                decoration: BoxDecoration(
                  color: selected ? active : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 4),
              Icon(
                selected ? selectedIcon : icon,
                size: 22,
                color: selected ? active : inactive,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? active : inactive,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
