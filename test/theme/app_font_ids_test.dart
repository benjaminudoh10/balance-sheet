import 'package:balance_sheet/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppFontIds', () {
    test('defaultId is valid', () {
      expect(AppFontIds.isValid(AppFontIds.defaultId), isTrue);
    });

    test('isValid rejects unknown id', () {
      expect(AppFontIds.isValid('comic_sans'), isFalse);
    });

    test('choices cover all valid ids', () {
      for (final o in AppFontIds.choices) {
        expect(AppFontIds.isValid(o.id), isTrue, reason: o.id);
      }
    });
  });
}
