import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Supported color schemes for the app.
enum AppThemeScheme {
  midnightMint('midnight_mint', 'Mint'),
  midnightBlue('midnight_blue', 'Blue'),
  midnightPurple('midnight_purple', 'Purple'),
  midnightGold('midnight_gold', 'Gold'),
  midnightRose('midnight_rose', 'Rose');

  const AppThemeScheme(this.id, this.label);
  final String id;
  final String label;

  static AppThemeScheme fromId(String? id) {
    return AppThemeScheme.values.firstWhere(
      (AppThemeScheme e) => e.id == id,
      orElse: () => AppThemeScheme.midnightMint,
    );
  }
}

/// Semantic colors for Balanced UI — registered via [ThemeExtension] on light and dark [ThemeData].
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.border,
    required this.mint,
    required this.coral,
    required this.textPrimary,
    required this.textSecondary,
    required this.overlay,
    required this.gridLine,
  });

  final Brightness brightness;

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color border;
  final Color mint;
  final Color coral;
  final Color textPrimary;
  final Color textSecondary;
  final Color overlay;
  final Color gridLine;

  static AppPalette of(BuildContext context) {
    final AppPalette? p = Theme.of(context).extension<AppPalette>();
    assert(p != null, 'ThemeData.extensions must include AppPalette');
    return p!;
  }

  /// Returns the palette for a specific scheme and brightness.
  static AppPalette forScheme(AppThemeScheme scheme, Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    // Base colors that stay consistent across schemes
    final Color background =
        isDark ? const Color(0xFF0D1117) : const Color(0xFFF5F3FA);
    final Color surface = isDark ? const Color(0xFF161B22) : Colors.white;
    final Color surfaceElevated =
        isDark ? const Color(0xFF21262D) : const Color(0xFFEDE9F4);
    final Color border =
        isDark ? const Color(0xFF30363D) : const Color(0xFFD4CDE0);
    final Color textPrimary =
        isDark ? const Color(0xFFF0F6FC) : const Color(0xFF1A1428);
    final Color textSecondary =
        isDark ? const Color(0xFF8B949E) : const Color(0xFF5E5672);
    final Color overlay =
        isDark ? const Color(0xCC0D1117) : const Color(0x99000000);

    // Scheme-specific accent colors (Mint = Income/Primary, Coral = Expense/Secondary)
    Color mint;
    Color coral;
    switch (scheme) {
      case AppThemeScheme.midnightBlue:
        mint = isDark ? const Color(0xFF3E99E6) : const Color(0xFF0D648F);
        coral = isDark
            ? const Color(0xFFFF9F40)
            : const Color(0xFFD66D00); // Orange
        break;
      case AppThemeScheme.midnightPurple:
        mint = isDark ? const Color(0xFFB388FF) : const Color(0xFF673AB7);
        coral =
            isDark ? const Color(0xFFFFD54F) : const Color(0xFFBF8F00); // Amber
        break;
      case AppThemeScheme.midnightGold:
        mint = isDark ? const Color(0xFFFFD700) : const Color(0xFFB8860B);
        coral = isDark
            ? const Color(0xFF9FA8DA)
            : const Color(0xFF3949AB); // Indigo
        break;
      case AppThemeScheme.midnightRose:
        mint = isDark ? const Color(0xFFFF80AB) : const Color(0xFFC2185B);
        coral =
            isDark ? const Color(0xFF4DB6AC) : const Color(0xFF00796B); // Teal
        break;
      case AppThemeScheme.midnightMint:
        mint = isDark ? const Color(0xFF3EE6B5) : const Color(0xFF0D8F72);
        coral = isDark
            ? const Color(0xFFFF6B7A)
            : const Color(0xFFD63D4F); // Coral Red
        break;
    }

    final Color gridLine = mint.withValues(alpha: isDark ? 0.08 : 0.14);

    return AppPalette(
      brightness: brightness,
      background: background,
      surface: surface,
      surfaceElevated: surfaceElevated,
      border: border,
      mint: mint,
      coral: coral,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      overlay: overlay,
      gridLine: gridLine,
    );
  }

  /// Status bar and navigation bar icons that contrast with [background].
  ///
  /// Transparent [AppBar]s (e.g. Budget) can otherwise pick the wrong brightness;
  /// that style may persist after leaving the screen unless a root overlay reapplies this.
  SystemUiOverlayStyle get systemUiOverlayStyle {
    final bool isDark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: background,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    );
  }

  /// Dark “Midnight Mint” palette (previous default).
  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF0D1117),
    surface: Color(0xFF161B22),
    surfaceElevated: Color(0xFF21262D),
    border: Color(0xFF30363D),
    mint: Color(0xFF3EE6B5),
    coral: Color(0xFFFF6B7A),
    textPrimary: Color(0xFFF0F6FC),
    textSecondary: Color(0xFF8B949E),
    overlay: Color(0xCC0D1117),
    gridLine: Color(0x153EE6B5),
  );

  /// Light theme — same accent family, light surfaces.
  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFF5F3FA),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFEDE9F4),
    border: Color(0xFFD4CDE0),
    mint: Color(0xFF0D8F72),
    coral: Color(0xFFD63D4F),
    textPrimary: Color(0xFF1A1428),
    textSecondary: Color(0xFF5E5672),
    overlay: Color(0x99000000),
    gridLine: Color(0x220D8F72),
  );

  LinearGradient get settingsHeroGradient {
    if (brightness == Brightness.dark) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xD821262D),
          Color(0xC8161B22),
          Color(0xCC21262D),
        ],
        stops: [0.0, 0.45, 1.0],
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xE8FFFFFF),
        Color(0xE0EDE9F4),
        Color(0xE6F0ECF8),
      ],
      stops: [0.0, 0.45, 1.0],
    );
  }

  LinearGradient balanceCardGradient(bool isDailyLoss) {
    if (brightness == Brightness.dark) {
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
    if (isDailyLoss) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.85),
          coral.withValues(alpha: 0.22),
        ],
      );
    }
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: 0.9),
        mint.withValues(alpha: 0.2),
      ],
    );
  }

  @override
  AppPalette copyWith({
    Brightness? brightness,
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? border,
    Color? mint,
    Color? coral,
    Color? textPrimary,
    Color? textSecondary,
    Color? overlay,
    Color? gridLine,
  }) {
    return AppPalette(
      brightness: brightness ?? this.brightness,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      border: border ?? this.border,
      mint: mint ?? this.mint,
      coral: coral ?? this.coral,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      overlay: overlay ?? this.overlay,
      gridLine: gridLine ?? this.gridLine,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    if (t == 0.0) return this;
    if (t == 1.0) return other;
    return AppPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      border: Color.lerp(border, other.border, t)!,
      mint: Color.lerp(mint, other.mint, t)!,
      coral: Color.lerp(coral, other.coral, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      gridLine: Color.lerp(gridLine, other.gridLine, t)!,
    );
  }
}
