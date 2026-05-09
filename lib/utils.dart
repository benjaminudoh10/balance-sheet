import 'package:balance_sheet/controllers/contact_controller.dart';
import 'package:balance_sheet/controllers/currency_controller.dart';
import 'package:balance_sheet/models/budget_line.dart';
import 'package:balance_sheet/models/transaction.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

String getContactNameForTransaction(Transaction transaction) {
  if (transaction.contactId <= 0) return '';
  final contacts = Get.find<ContactController>().contacts;
  for (final c in contacts) {
    if (c.id == transaction.contactId) return c.name;
  }
  return '';
}

/// Parses a plain amount string (e.g. `1,234.56`) into **minor units** (cents). Returns null if invalid.
int? parseMoneyStringToMinor(String raw) {
  final String t = raw.trim().replaceAll(',', '');
  if (t.isEmpty) return null;
  final double? v = double.tryParse(t);
  if (v == null) return null;
  return (v * 100).round();
}

String formatMinorUnits(int minor, String iso4217Code) {
  final String code = iso4217Code.trim().toUpperCase();
  if (code.isEmpty) {
    return NumberFormat.currency(locale: 'en_US', symbol: '')
        .format(minor / 100)
        .trim();
  }
  try {
    return NumberFormat.simpleCurrency(name: code).format(minor / 100);
  } catch (_) {
    return '${minor / 100} $code';
  }
}

/// Primary formatting for amounts stored in **LCY minor units** when no transaction context exists.
String formatAmount(int kobo) {
  if (Get.isRegistered<CurrencyController>()) {
    return formatMinorUnits(kobo, Get.find<CurrencyController>().lcyCode.value);
  }
  return NumberFormat.simpleCurrency(name: 'NGN').format(kobo / 100);
}

/// How a single ledger row should read: entered currency only ([Transaction.entryAmountMinor]).
String formatTransactionDisplayAmount(Transaction t) {
  final CurrencyController c = Get.find<CurrencyController>();
  if (t.entryIsFcy) {
    return formatMinorUnits(t.entryAmountMinor, c.fcyCode.value);
  }
  return formatMinorUnits(t.amount, c.lcyCode.value);
}

/// Planned budget line — show the currency the user chose when entering the plan.
String formatBudgetPlannedDisplay(BudgetLine line) {
  final CurrencyController c = Get.find<CurrencyController>();
  if (line.planEntryIsFcy) {
    return formatMinorUnits(line.planEntryAmountMinor, c.fcyCode.value);
  }
  return formatMinorUnits(line.plannedAmount, c.lcyCode.value);
}

/// Signed net for “today” line (amounts in minor units, same as [formatAmount]).
String formatSignedNet(int netMinor) {
  if (netMinor == 0) {
    return formatAmount(0);
  }
  final String sign = netMinor > 0 ? '+' : '−';
  return '$sign ${formatAmount(netMinor.abs())}';
}

/// Net without +/-; use UI color for sign (amounts in minor units).
String formatNetWithoutSign(int netMinor) {
  return formatAmount(netMinor.abs());
}
