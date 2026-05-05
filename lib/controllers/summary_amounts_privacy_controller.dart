import 'package:balance_sheet/constants/app.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Toggles visibility of monetary amounts on summary cards only (not lists / detail rows).
///
/// [showHomeSummaryAmounts] links the home balance card and net worth strip.
/// [showInvestmentSummaryAmounts] links holdings portfolio summary and other investments summary.
class SummaryAmountsPrivacyController extends GetxController {
  final RxBool showHomeSummaryAmounts = true.obs;
  final RxBool showInvestmentSummaryAmounts = true.obs;

  @override
  void onInit() {
    super.onInit();
    final GetStorage box = GetStorage();
    final bool? home =
        box.read<bool>(AppConstants.SHOW_HOME_SUMMARY_AMOUNTS_KEY);
    if (home != null) {
      showHomeSummaryAmounts.value = home;
    }
    final bool? inv =
        box.read<bool>(AppConstants.SHOW_INVESTMENT_SUMMARY_AMOUNTS_KEY);
    if (inv != null) {
      showInvestmentSummaryAmounts.value = inv;
    }
  }

  void toggleHomeSummaryAmounts() {
    showHomeSummaryAmounts.toggle();
    GetStorage().write(AppConstants.SHOW_HOME_SUMMARY_AMOUNTS_KEY,
        showHomeSummaryAmounts.value);
  }

  void toggleInvestmentSummaryAmounts() {
    showInvestmentSummaryAmounts.toggle();
    GetStorage().write(AppConstants.SHOW_INVESTMENT_SUMMARY_AMOUNTS_KEY,
        showInvestmentSummaryAmounts.value);
  }
}
