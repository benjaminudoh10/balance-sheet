import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:balance_sheet/constants/app.dart';
import 'package:crypto/crypto.dart';
import 'package:get_storage/get_storage.dart';

/// Salted SHA-256 for the access PIN. Plain PIN is never persisted.
class PinHash {
  PinHash._();

  static const int _saltBytes = 16;

  static Uint8List _generateSalt() {
    final Random r = Random.secure();
    final Uint8List b = Uint8List(_saltBytes);
    for (int i = 0; i < _saltBytes; i++) {
      b[i] = r.nextInt(256);
    }
    return b;
  }

  /// SHA-256(salt || utf8(pin)), encoded as Base64.
  static String computeHash(String pin, Uint8List salt) {
    final List<int> pinBytes = utf8.encode(pin);
    final Uint8List combined = Uint8List(salt.length + pinBytes.length);
    combined.setAll(0, salt);
    combined.setAll(salt.length, pinBytes);
    final Digest d = sha256.convert(combined);
    return base64Encode(d.bytes);
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    int r = 0;
    for (int i = 0; i < a.length; i++) {
      r |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return r == 0;
  }

  /// Returns true if [candidate] matches stored hash/salt in [box].
  static bool verify(GetStorage box, String candidate) {
    final String? hashB64 = box.read<String>(AppConstants.USER_PIN_HASH_KEY);
    final String? saltB64 = box.read<String>(AppConstants.USER_PIN_SALT_KEY);
    if (hashB64 == null ||
        saltB64 == null ||
        hashB64.isEmpty ||
        saltB64.isEmpty) {
      return false;
    }
    Uint8List salt;
    try {
      salt = base64Decode(saltB64);
    } catch (_) {
      return false;
    }
    final String expected = computeHash(candidate, salt);
    return _constantTimeEquals(expected, hashB64);
  }

  static bool hasPin(GetStorage box) {
    final String? h = box.read<String>(AppConstants.USER_PIN_HASH_KEY);
    final String? s = box.read<String>(AppConstants.USER_PIN_SALT_KEY);
    return h != null && h.isNotEmpty && s != null && s.isNotEmpty;
  }

  /// Persists new hash + salt; removes legacy plaintext key if present.
  static Future<void> persistPin(GetStorage box, String pin) async {
    final Uint8List salt = _generateSalt();
    final String hash = computeHash(pin, salt);
    box.write(AppConstants.USER_PIN_HASH_KEY, hash);
    box.write(AppConstants.USER_PIN_SALT_KEY, base64Encode(salt));
    await box.remove(AppConstants.USER_PIN_KEY);
  }

  static Future<void> clearPin(GetStorage box) async {
    await box.remove(AppConstants.USER_PIN_HASH_KEY);
    await box.remove(AppConstants.USER_PIN_SALT_KEY);
    await box.remove(AppConstants.USER_PIN_KEY);
  }
}
