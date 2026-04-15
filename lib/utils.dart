import 'package:intl/intl.dart';

String formatAmount(kobo) {
  final formatCurrency = new NumberFormat.simpleCurrency(name: 'NGN');
  return formatCurrency.format(kobo / 100);
}

/// Signed net for “today” line (amounts in minor units, same as [formatAmount]).
String formatSignedNet(int netMinor) {
  if (netMinor == 0) {
    return formatAmount(0);
  }
  final sign = netMinor > 0 ? '+' : '−';
  return '$sign ${formatAmount(netMinor.abs())}';
}
