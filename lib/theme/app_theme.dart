import 'package:balance_sheet/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// User-selectable UI fonts (Google Fonts). Keys are persisted in storage.
///
/// Two sans families and one monospace — each visually distinct.
abstract final class AppFontIds {
  static const String inter = 'inter';
  static const String nunitoSans = 'nunito_sans';
  static const String jetbrainsMono = 'jetbrains_mono';

  static const String defaultId = inter;

  static const List<AppFontOption> choices = [
    AppFontOption(id: inter, label: 'Inter'),
    AppFontOption(id: nunitoSans, label: 'Nunito Sans'),
    AppFontOption(id: jetbrainsMono, label: 'JetBrains Mono'),
  ];

  static bool isValid(String id) =>
      choices.any((AppFontOption o) => o.id == id);
}

class AppFontOption {
  const AppFontOption({required this.id, required this.label});

  final String id;
  final String label;
}

TextTheme _googleTextThemeForId(String id, TextTheme base) {
  switch (id) {
    case AppFontIds.nunitoSans:
      return GoogleFonts.nunitoSansTextTheme(base);
    case AppFontIds.jetbrainsMono:
      return GoogleFonts.jetBrainsMonoTextTheme(base);
    case AppFontIds.inter:
    default:
      return GoogleFonts.interTextTheme(base);
  }
}

TextStyle _t(TextStyle? s, double size, FontWeight w, double height) {
  final TextStyle base = s ?? const TextStyle();
  return base.copyWith(fontSize: size, fontWeight: w, height: height);
}

/// Single type scale for the app: sizes and weights stay consistent across font families.
TextTheme midnightScaledTextTheme(TextTheme base) {
  return base.copyWith(
    displayLarge: _t(base.displayLarge, 36, FontWeight.w600, 1.15),
    displayMedium: _t(base.displayMedium, 32, FontWeight.w600, 1.18),
    displaySmall: _t(base.displaySmall, 34, FontWeight.w600, 1.2),
    headlineLarge: _t(base.headlineLarge, 26, FontWeight.w700, 1.25),
    headlineMedium: _t(base.headlineMedium, 24, FontWeight.w600, 1.25),
    headlineSmall: _t(base.headlineSmall, 22, FontWeight.w600, 1.3),
    titleLarge: _t(base.titleLarge, 18, FontWeight.w600, 1.35),
    titleMedium: _t(base.titleMedium, 16, FontWeight.w600, 1.35),
    titleSmall: _t(base.titleSmall, 15, FontWeight.w600, 1.35),
    bodyLarge: _t(base.bodyLarge, 16, FontWeight.w400, 1.45),
    bodyMedium: _t(base.bodyMedium, 14, FontWeight.w400, 1.45),
    bodySmall: _t(base.bodySmall, 13, FontWeight.w400, 1.4),
    labelLarge: _t(base.labelLarge, 14, FontWeight.w600, 1.2),
    labelMedium: _t(base.labelMedium, 12, FontWeight.w600, 1.25),
    labelSmall: _t(base.labelSmall, 11, FontWeight.w500, 1.2),
  );
}

ThemeData _buildAppTheme(String fontId, AppPalette palette) {
  final String id = AppFontIds.isValid(fontId) ? fontId : AppFontIds.defaultId;
  final bool isDark = palette.brightness == Brightness.dark;
  final ThemeData shell = ThemeData(
    brightness: palette.brightness,
    useMaterial3: true,
  );
  final TextTheme raw = _googleTextThemeForId(id, shell.textTheme);
  final TextTheme textTheme = midnightScaledTextTheme(raw).apply(
    bodyColor: palette.textPrimary,
    displayColor: palette.textPrimary,
  );

  final ColorScheme colorScheme = isDark
      ? ColorScheme.dark(
          surface: palette.surface,
          primary: palette.mint,
          secondary: palette.coral,
          onPrimary: Colors.black87,
          onSecondary: Colors.white,
          onSurface: palette.textPrimary,
        ).copyWith(surfaceTint: Colors.transparent)
      : ColorScheme.light(
          surface: palette.surface,
          primary: palette.mint,
          secondary: palette.coral,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: palette.textPrimary,
        ).copyWith(surfaceTint: Colors.transparent);

  return ThemeData(
    brightness: palette.brightness,
    useMaterial3: true,
    scaffoldBackgroundColor: palette.background,
    extensions: <ThemeExtension<dynamic>>[palette],
    colorScheme: colorScheme,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: palette.background,
      foregroundColor: palette.textPrimary,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: palette.systemUiOverlayStyle,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: palette.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.surfaceElevated,
      titleTextStyle: textTheme.titleLarge?.copyWith(color: palette.textPrimary),
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: palette.textPrimary),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.surfaceElevated,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: palette.textPrimary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
    ),
  );
}

/// Dark theme (previous default).
ThemeData buildDarkAppTheme(String fontId) => _buildAppTheme(fontId, AppPalette.dark);

/// Light theme.
ThemeData buildLightAppTheme(String fontId) => _buildAppTheme(fontId, AppPalette.light);
