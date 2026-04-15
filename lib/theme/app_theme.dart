import 'package:balance_sheet/constants/midnight_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// User-selectable UI fonts (Google Fonts). Keys are persisted in storage.
///
/// Sans options are visually distinct (neutral, rounded, humanist). Monospace
/// options are for code-like / tabular readability — not duplicates of the sans set.
abstract final class AppFontIds {
  static const String inter = 'inter';
  static const String nunitoSans = 'nunito_sans';
  static const String sourceSans3 = 'source_sans_3';
  static const String jetbrainsMono = 'jetbrains_mono';
  static const String sourceCodePro = 'source_code_pro';
  static const String ibmPlexMono = 'ibm_plex_mono';

  static const String defaultId = inter;

  static const List<AppFontOption> choices = [
    AppFontOption(id: inter, label: 'Inter'),
    AppFontOption(id: nunitoSans, label: 'Nunito Sans'),
    AppFontOption(id: sourceSans3, label: 'Source Sans 3'),
    AppFontOption(id: jetbrainsMono, label: 'JetBrains Mono'),
    AppFontOption(id: sourceCodePro, label: 'Source Code Pro'),
    AppFontOption(id: ibmPlexMono, label: 'IBM Plex Mono'),
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
    case AppFontIds.sourceSans3:
      return GoogleFonts.sourceSans3TextTheme(base);
    case AppFontIds.jetbrainsMono:
      return GoogleFonts.jetBrainsMonoTextTheme(base);
    case AppFontIds.sourceCodePro:
      return GoogleFonts.sourceCodeProTextTheme(base);
    case AppFontIds.ibmPlexMono:
      return GoogleFonts.ibmPlexMonoTextTheme(base);
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

ThemeData buildMidnightAppTheme(String fontId) {
  final String id = AppFontIds.isValid(fontId) ? fontId : AppFontIds.defaultId;
  final ThemeData shell = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
  );
  final TextTheme raw = _googleTextThemeForId(id, shell.textTheme);
  final TextTheme textTheme = midnightScaledTextTheme(raw).apply(
    bodyColor: MidnightTheme.textPrimary,
    displayColor: MidnightTheme.textPrimary,
  );

  return ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: MidnightTheme.background,
    colorScheme: ColorScheme.dark(
      surface: MidnightTheme.surface,
      primary: MidnightTheme.mint,
      secondary: MidnightTheme.coral,
      onPrimary: Colors.black87,
      onSecondary: Colors.white,
      onSurface: MidnightTheme.textPrimary,
    ).copyWith(surfaceTint: Colors.transparent),
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: MidnightTheme.background,
      foregroundColor: MidnightTheme.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: MidnightTheme.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: MidnightTheme.surfaceElevated,
      titleTextStyle: textTheme.titleLarge?.copyWith(color: MidnightTheme.textPrimary),
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: MidnightTheme.textPrimary),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: MidnightTheme.surfaceElevated,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: MidnightTheme.textPrimary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: textTheme.bodyMedium?.copyWith(color: MidnightTheme.textSecondary),
    ),
  );
}
