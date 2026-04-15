import 'package:balance_sheet/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// Mint radial glow + bordered tile — matches PIN / lock screen mockups.
class PinHeroIcon extends StatelessWidget {
  const PinHeroIcon({super.key, required this.icon});

  final IconData icon;

  static const double _radius = 16;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: [
          BoxShadow(
            color: p.mint.withValues(alpha: 0.38),
            blurRadius: 26,
            spreadRadius: 0,
            offset: Offset.zero,
          ),
          BoxShadow(
            color: p.mint.withValues(alpha: 0.22),
            blurRadius: 44,
            spreadRadius: -4,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: p.mint.withValues(alpha: 0.12),
            blurRadius: 56,
            spreadRadius: 2,
            offset: Offset.zero,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          color: p.mint.withValues(alpha: 0.12),
          border: Border.all(
            color: p.mint.withValues(alpha: 0.28),
          ),
        ),
        child: Icon(
          icon,
          color: p.mint,
          size: 28,
        ),
      ),
    );
  }
}
