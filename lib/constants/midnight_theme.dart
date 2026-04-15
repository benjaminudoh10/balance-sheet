import 'package:flutter/material.dart';

/// Midnight Mint (mockup 2) — dark shell, mint accents, coral expenses.
class MidnightTheme {
  MidnightTheme._();

  static const Color background = Color(0xFF0D1117);
  static const Color surface = Color(0xFF161B22);
  static const Color surfaceElevated = Color(0xFF21262D);
  static const Color border = Color(0xFF30363D);

  static const Color mint = Color(0xFF3EE6B5);
  static const Color mintMuted = Color(0x993EE6B5);
  static const Color coral = Color(0xFFFF6B7A);
  static const Color coralMuted = Color(0x99FF6B7A);

  static const Color textPrimary = Color(0xFFF0F6FC);
  static const Color textSecondary = Color(0xFF8B949E);

  static const Color overlay = Color(0xCC0D1117);
  static const Color gridLine = Color(0x153EE6B5);

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x33FFFFFF),
      Color(0x223EE6B5),
    ],
  );

  /// Profile hero **fill** — grey surfaces + light frost (no mint in the gradient).
  static const LinearGradient profileHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xD821262D),
      Color(0xC8161B22),
      Color(0xCC21262D),
    ],
    stops: [0.0, 0.45, 1.0],
  );

  /// Top balance card: green-tinted when [isDailyLoss] is false, red-tinted when the day is net negative.
  static LinearGradient balanceCardGradient(bool isDailyLoss) {
    if (isDailyLoss) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x33FFFFFF),
          Color(0x30FF6B7A),
        ],
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x33FFFFFF),
        Color(0x303EE6B5),
      ],
    );
  }
}
