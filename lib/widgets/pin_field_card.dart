import 'package:balance_sheet/constants/midnight_theme.dart';
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: MidnightTheme.surface,
        border: Border.all(color: MidnightTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.35,
              height: 1.25,
              color: MidnightTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.45,
              color: MidnightTheme.textSecondary.withOpacity(0.78),
            ),
          ),
          const SizedBox(height: 18),
          field,
        ],
      ),
    );
  }
}
