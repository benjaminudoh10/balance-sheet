import 'package:balance_sheet/controllers/currency_controller.dart';
import 'package:balance_sheet/controllers/investment_controller.dart';
import 'package:balance_sheet/controllers/transaction_controller.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class WearService {
  static const MethodChannel _channel = MethodChannel('balanced/wear');

  /// Fetches latest data from controllers and pushes to Wear OS.
  static Future<void> sync() async {
    try {
      if (!Get.isRegistered<TransactionController>() ||
          !Get.isRegistered<InvestmentController>() ||
          !Get.isRegistered<CurrencyController>()) {
        return;
      }

      final TransactionController tx = Get.find();
      final InvestmentController inv = Get.find();
      final CurrencyController cur = Get.find();

      final String currencySymbol = cur.symbolFor(cur.lcyCode.value);

      // Values are in minor units (cents), convert to major units for display.
      final String balanceStr = (tx.total.value / 100).toStringAsFixed(2);
      final int invTotalMinor =
          inv.stocksTotalMinor.value + inv.otherInvestmentsTotalMinor.value;
      final String investmentStr = (invTotalMinor / 100).toStringAsFixed(2);
      final String netWorthStr =
          ((tx.total.value + invTotalMinor) / 100).toStringAsFixed(2);

      await _channel.invokeMethod('syncWearData', {
        'balance': balanceStr,
        'investments': investmentStr,
        'netWorth': netWorthStr,
        'currency': currencySymbol,
      });
    } catch (e) {
      // Fail silently for now to avoid disrupting main app flow.
      // ignore: avoid_print
      print('Wear OS Sync Error: $e');
    }
  }
}
