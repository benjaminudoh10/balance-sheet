import 'package:balance_sheet/constants/app.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';

/// User-chosen local (LCY) and foreign (FCY) ISO 4217 codes and a manual rate:
/// **1 unit of FCY (major) = [rate] units of LCY (major)** (e.g. 1 USD = 1400 NGN).
///
/// Ledger [Transaction.amount] and aggregates are always stored in **LCY minor units**.
class CurrencyController extends GetxController {
  final RxString lcyCode = 'NGN'.obs;
  final RxString fcyCode = 'USD'.obs;
  final RxDouble rate = 1400.0.obs;

  /// Fiat ISO-style codes (3 letters) and common crypto tickers (often 2–5 letters).
  static final RegExp _currencyCodePattern = RegExp(r'^[A-Za-z]{2,8}$');

  static bool isValidCurrencyCode(String? raw) {
    if (raw == null) return false;
    final String t = raw.trim();
    if (t.isEmpty) return false;
    return _currencyCodePattern.hasMatch(t);
  }

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  void _load() {
    final GetStorage box = GetStorage();
    final String? l = box.read<String>(AppConstants.CURRENCY_LCY_KEY);
    final String? f = box.read<String>(AppConstants.CURRENCY_FCY_KEY);
    final double? r = _readRate(box);
    if (l != null && isValidCurrencyCode(l)) {
      lcyCode.value = l.trim().toUpperCase();
    }
    if (f != null && isValidCurrencyCode(f)) {
      fcyCode.value = f.trim().toUpperCase();
    }
    if (r != null && r > 0) {
      rate.value = r;
    }
  }

  double? _readRate(GetStorage box) {
    final Object? raw = box.read(AppConstants.CURRENCY_RATE_KEY);
    if (raw is double) return raw;
    if (raw is int) return raw.toDouble();
    if (raw is num) return raw.toDouble();
    if (raw is String) return parseRateUserInput(raw);
    return null;
  }

  /// Parses profile / backup values: plain numbers, JSON strings, comma decimals / thousands.
  static double? parseRateUserInput(String raw) {
    String s = raw.trim().replaceAll(RegExp(r'[\s\u00a0]'), '');
    double? d = double.tryParse(s);
    if (d != null) return d;

    if (s.contains(',') && !s.contains('.')) {
      final List<String> parts = s.split(',');
      if (parts.length == 2 &&
          parts[0].isNotEmpty &&
          parts[1].isNotEmpty &&
          parts[1].length <= 2) {
        d = double.tryParse('${parts[0]}.${parts[1]}');
        if (d != null) return d;
      }
    }

    s = s.replaceAll(',', '');
    return double.tryParse(s);
  }

  void setLcyCode(String code) {
    final String c = code.trim().toUpperCase();
    if (!isValidCurrencyCode(c)) return;
    lcyCode.value = c;
    GetStorage().write(AppConstants.CURRENCY_LCY_KEY, c);
  }

  void setFcyCode(String code) {
    final String c = code.trim().toUpperCase();
    if (!isValidCurrencyCode(c)) return;
    fcyCode.value = c;
    GetStorage().write(AppConstants.CURRENCY_FCY_KEY, c);
  }

  void setRate(double r) {
    if (r <= 0) return;
    rate.value = r;
    GetStorage().write(AppConstants.CURRENCY_RATE_KEY, r);
  }

  void syncFromStorage() {
    _load();
  }

  /// Minor FCY → minor LCY using [rate] (major FCY × rate = major LCY; same decimal scale).
  int lcyMinorFromFcyMinor(int fcyMinor) {
    if (fcyMinor == 0) return 0;
    if (rate.value <= 0) return fcyMinor;
    return (fcyMinor * rate.value).round();
  }

  /// Minor LCY → minor FCY.
  int fcyMinorFromLcyMinor(int lcyMinor) {
    if (lcyMinor == 0) return 0;
    if (rate.value <= 0) return lcyMinor;
    return (lcyMinor / rate.value).round();
  }

  String symbolFor(String iso4217) {
    final String c = iso4217.trim().toUpperCase();
    if (c.isEmpty) return '';
    try {
      final String? s = NumberFormat.simpleCurrency(name: c).currencySymbol;
      if (s != null && s.isNotEmpty) return s;
    } catch (_) {}
    return c;
  }

  bool get showDualTotals =>
      lcyCode.value != fcyCode.value && rate.value > 0;
}
