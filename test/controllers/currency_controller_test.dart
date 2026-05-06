import 'package:balance_sheet/controllers/currency_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurrencyController.parseRateUserInput', () {
    test('plain and whitespace', () {
      expect(CurrencyController.parseRateUserInput('1400'), 1400);
      expect(CurrencyController.parseRateUserInput('  1.5 '), 1.5);
    });

    test('US-style thousands', () {
      expect(CurrencyController.parseRateUserInput('1,400'), 1400);
      expect(CurrencyController.parseRateUserInput('1,234.56'), 1234.56);
    });

    test('comma as decimal separator', () {
      expect(CurrencyController.parseRateUserInput('1,5'), 1.5);
      expect(CurrencyController.parseRateUserInput('12,50'), 12.5);
    });

    test('invalid', () {
      expect(CurrencyController.parseRateUserInput(''), isNull);
      expect(CurrencyController.parseRateUserInput('abc'), isNull);
    });
  });
}
