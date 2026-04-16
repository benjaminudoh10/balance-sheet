import 'package:balance_sheet/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatAmount', () {
    test('formats zero kobo as a decimal amount', () {
      final String s = formatAmount(0);
      expect(s, matches(RegExp(r'0[.,]00')));
    });

    test('formats naira from kobo (100 naira from 10000 minor units)', () {
      expect(formatAmount(10000), matches(RegExp(r'100[.,]00')));
    });
  });

  group('formatSignedNet', () {
    test('zero uses unsigned format', () {
      expect(formatSignedNet(0), formatAmount(0));
    });

    test('positive shows plus', () {
      expect(formatSignedNet(500), contains('+'));
    });

    test('negative starts with a minus sign', () {
      final String s = formatSignedNet(-300);
      expect(
        s.substring(0, 1),
        anyOf('−', '-'),
        reason: 'Expected Unicode minus (U+2212) or ASCII hyphen: $s',
      );
    });

    test('absolute value used for magnitude', () {
      expect(formatSignedNet(-100), contains(formatAmount(100)));
    });
  });

  group('formatNetWithoutSign', () {
    test('matches unsigned amount for zero', () {
      expect(formatNetWithoutSign(0), formatAmount(0));
    });

    test('uses magnitude without sign for positive', () {
      expect(formatNetWithoutSign(500), formatAmount(500));
      expect(formatNetWithoutSign(500), isNot(contains('+')));
    });

    test('uses magnitude without sign for negative', () {
      expect(formatNetWithoutSign(-300), formatAmount(300));
    });
  });
}
