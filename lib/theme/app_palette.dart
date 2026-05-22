import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  /// Debug-only Blue Dark Palette.
  static const AppPalette darkBlue = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF0D1117),
    surface: Color(0xFF161B22),
    surfaceElevated: Color(0xFF21262D),
    border: Color(0xFF30363D),
    mint: Color(0xFF3E99E6),
    coral: Color(0xFFFF6B7A),
    textPrimary: Color(0xFFF0F6FC),
    textSecondary: Color(0xFF8B949E),
    overlay: Color(0xCC0D1117),
    gridLine: Color(0x153E99E6),
  );

  /// Debug-only Blue Light Palette.
  static const AppPalette lightBlue = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFF5F3FA),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFEDE9F4),
    border: Color(0xFFD4CDE0),
    mint: Color(0xFF0D648F),
    coral: Color(0xFFD63D4F),
    textPrimary: Color(0xFF1A1428),
    textSecondary: Color(0xFF5E5672),
    overlay: Color(0x99000000),
    gridLine: Color(0x220D648F),
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
