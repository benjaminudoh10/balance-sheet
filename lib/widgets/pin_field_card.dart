import 'package:balance_sheet/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// Dark surface card with centered title + hint, used for PIN entry sections.
class PinFieldCard extends StatelessWidget {
  const PinFieldCard({
    super.key,
    required this.label,
    required this.hint,
    required this.field,
  });

  final String label;
  final String hint;
  final Widget field;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: p.surface,
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  letterSpacing: 1.35,
                  height: 1.25,
                  color: p.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                  color: p.textSecondary.withValues(alpha: 0.78),
                ),
          ),
          const SizedBox(height: 18),
          field,
        ],
      ),
    );
  }
}
