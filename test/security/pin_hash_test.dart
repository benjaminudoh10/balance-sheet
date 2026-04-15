import 'dart:convert';
import 'dart:typed_data';

import 'package:balance_sheet/constants/app.dart';
import 'package:balance_sheet/security/pin_hash.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

import '../helpers/path_provider_mock.dart';

void main() {
  late GetStorage box;

  setUp(() async {
    setupPathProviderMock();
    await GetStorage.init('pin_hash_tests');
    box = GetStorage('pin_hash_tests');
    box.erase();
  });

  group('PinHash.computeHash', () {
    test('same pin and salt yields same hash', () {
      final Uint8List salt = Uint8List.fromList(List<int>.generate(16, (i) => i));
      final String a = PinHash.computeHash('1234', salt);
      final String b = PinHash.computeHash('1234', salt);
      expect(a, b);
      expect(a.isNotEmpty, isTrue);
    });

    test('different salt yields different hash', () {
      final Uint8List s1 = Uint8List(16);
      final Uint8List s2 = Uint8List.fromList(List<int>.filled(16, 1));
      expect(
        PinHash.computeHash('1234', s1),
        isNot(PinHash.computeHash('1234', s2)),
      );
    });
  });

  group('PinHash.verify', () {
    test('returns false when storage is empty', () {
      expect(PinHash.verify(box, '1234'), isFalse);
    });

    test('returns false when hash missing', () async {
      await box.write(AppConstants.USER_PIN_SALT_KEY, base64Encode(Uint8List(16)));
      expect(PinHash.verify(box, '1234'), isFalse);
    });

    test('returns false when salt is invalid base64', () async {
      await box.write(AppConstants.USER_PIN_HASH_KEY, 'abc');
      await box.write(AppConstants.USER_PIN_SALT_KEY, 'not-valid-base64!!!');
      expect(PinHash.verify(box, '1234'), isFalse);
    });

    test('returns true for correct PIN after persistPin', () async {
      await PinHash.persistPin(box, '9876');
      expect(PinHash.verify(box, '9876'), isTrue);
      expect(PinHash.verify(box, '9875'), isFalse);
    });
  });

  group('PinHash.hasPin', () {
    test('false when empty', () {
      expect(PinHash.hasPin(box), isFalse);
    });

    test('true after persistPin', () async {
      await PinHash.persistPin(box, '1111');
      expect(PinHash.hasPin(box), isTrue);
    });
  });

  group('PinHash.clearPin', () {
    test('removes pin material', () async {
      await PinHash.persistPin(box, '2222');
      expect(PinHash.hasPin(box), isTrue);
      await PinHash.clearPin(box);
      expect(PinHash.hasPin(box), isFalse);
    });
  });
}
