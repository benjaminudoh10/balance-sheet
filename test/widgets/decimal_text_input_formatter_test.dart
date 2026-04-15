import 'package:balance_sheet/widgets/inputs.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DecimalTextInputFormatter', () {
    TextEditingValue apply(String oldText, String newText, {int decimalRange = 2}) {
      final DecimalTextInputFormatter f = DecimalTextInputFormatter(decimalRange: decimalRange);
      final TextEditingValue oldValue = TextEditingValue(
        text: oldText,
        selection: TextSelection.collapsed(offset: oldText.length),
      );
      final TextEditingValue newValue = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
      return f.formatEditUpdate(oldValue, newValue);
    }

    test('leading dot becomes 0.', () {
      final TextEditingValue out = apply('', '.');
      expect(out.text, '0.');
    });

    test('formatNewValue path when a third fractional digit is entered', () {
      // [formatNewValue] parses the string and rescales (see DecimalTextInputFormatter).
      final TextEditingValue out = apply('12.34', '12.345');
      expect(out.text, '123.45');
    });

    test('single dot as only input becomes 0.', () {
      final TextEditingValue out = apply('', '.');
      expect(out.text.startsWith('0.'), isTrue);
    });

    test('strips redundant leading zeros on integer part', () {
      final TextEditingValue out = apply('', '007');
      expect(out.text, '7');
    });
  });
}
