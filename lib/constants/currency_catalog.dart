import 'package:balance_sheet/constants/crypto_currencies.dart';
import 'package:balance_sheet/constants/iso4217_currencies.dart';

export 'iso4217_currencies.dart' show Iso4217Currency;

/// Fiat ([kIso4217Currencies]) and crypto ([kCryptoCurrencies]) merged — one flat list for pickers.
/// On duplicate [Iso4217Currency.code], the **fiat** entry is kept.
final List<Iso4217Currency> kCurrencyPickerOptions = _mergePickerOptions();

List<Iso4217Currency> _mergePickerOptions() {
  final Map<String, Iso4217Currency> byCode = <String, Iso4217Currency>{};
  for (final Iso4217Currency e in kIso4217Currencies) {
    byCode[e.code] = e;
  }
  for (final Iso4217Currency e in kCryptoCurrencies) {
    byCode.putIfAbsent(e.code, () => e);
  }
  final List<Iso4217Currency> out = byCode.values.toList();
  out.sort((Iso4217Currency a, Iso4217Currency b) => a.code.compareTo(b.code));
  return out;
}
