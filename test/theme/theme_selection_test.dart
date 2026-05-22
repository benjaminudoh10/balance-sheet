import 'package:balance_sheet/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppThemeScheme', () {
    test('fromId returns correct scheme for valid IDs', () {
      expect(
          AppThemeScheme.fromId('midnight_mint'), AppThemeScheme.midnightMint);
      expect(
          AppThemeScheme.fromId('midnight_blue'), AppThemeScheme.midnightBlue);
      expect(AppThemeScheme.fromId('midnight_purple'),
          AppThemeScheme.midnightPurple);
      expect(
          AppThemeScheme.fromId('midnight_gold'), AppThemeScheme.midnightGold);
      expect(
          AppThemeScheme.fromId('midnight_rose'), AppThemeScheme.midnightRose);
    });

    test('fromId returns default (midnight_mint) for invalid IDs', () {
      expect(AppThemeScheme.fromId('invalid'), AppThemeScheme.midnightMint);
      expect(AppThemeScheme.fromId(null), AppThemeScheme.midnightMint);
    });
  });

  group('AppPalette.forScheme', () {
    test('returns correct mint color for midnightMint (Dark)', () {
      final palette =
          AppPalette.forScheme(AppThemeScheme.midnightMint, Brightness.dark);
      expect(palette.mint, const Color(0xFF3EE6B5));
    });

    test('returns correct mint color for midnightBlue (Dark)', () {
      final palette =
          AppPalette.forScheme(AppThemeScheme.midnightBlue, Brightness.dark);
      expect(palette.mint, const Color(0xFF3E99E6));
    });

    test('returns correct mint color for midnightPurple (Dark)', () {
      final palette =
          AppPalette.forScheme(AppThemeScheme.midnightPurple, Brightness.dark);
      expect(palette.mint, const Color(0xFFB388FF));
    });

    test('returns correct mint color for midnightGold (Dark)', () {
      final palette =
          AppPalette.forScheme(AppThemeScheme.midnightGold, Brightness.dark);
      expect(palette.mint, const Color(0xFFFFD700));
    });

    test('returns correct mint color for midnightRose (Dark)', () {
      final palette =
          AppPalette.forScheme(AppThemeScheme.midnightRose, Brightness.dark);
      expect(palette.mint, const Color(0xFFFF80AB));
    });

    test('returns correct mint color for midnightMint (Light)', () {
      final palette =
          AppPalette.forScheme(AppThemeScheme.midnightMint, Brightness.light);
      expect(palette.mint, const Color(0xFF0D8F72));
    });

    test('returns correct mint color for midnightBlue (Light)', () {
      final palette =
          AppPalette.forScheme(AppThemeScheme.midnightBlue, Brightness.light);
      expect(palette.mint, const Color(0xFF0D648F));
    });
  });
}
