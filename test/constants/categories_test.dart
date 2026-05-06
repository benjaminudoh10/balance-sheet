import 'package:balance_sheet/constants/category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const Set<String> knownKeys = {
    'food',
    'transport',
    'investment',
    'salary',
    'savings',
    'charity',
    'rent',
    'utilities',
    'misc',
  };

  group('Categories.iconForKey', () {
    test('known keys return distinct icons', () {
      final Set<IconData> icons = {};
      for (final String k in knownKeys) {
        icons.add(Categories.iconForKey(k));
      }
      expect(icons.length, greaterThan(1));
    });

    test('unknown key falls back to payments icon', () {
      expect(
        Categories.iconForKey('unknown_xyz'),
        Icons.payments_outlined,
      );
    });
  });

  group('Categories.pillStyleForKey', () {
    test('light and dark differ for food', () {
      final CategoryPillStyle light =
          Categories.pillStyleForKey('food', Brightness.light);
      final CategoryPillStyle dark =
          Categories.pillStyleForKey('food', Brightness.dark);
      expect(light.background, isNot(dark.background));
    });

    test('default branch for unknown key', () {
      final CategoryPillStyle l =
          Categories.pillStyleForKey('custom', Brightness.light);
      final CategoryPillStyle d =
          Categories.pillStyleForKey('custom', Brightness.dark);
      expect(l.foreground, isNot(equals(Colors.transparent)));
      expect(d.foreground, isNot(equals(Colors.transparent)));
    });

    test('CATEGORIES list has keys matching known set', () {
      final Set<String> keys =
          Categories.CATEGORIES.map((e) => e['key']!).toSet();
      expect(keys, knownKeys);
    });
  });
}
