import 'package:balance_sheet/database/investment_operations.dart' as inv;
import 'package:balance_sheet/models/investment_holding.dart';
import 'package:balance_sheet/models/other_asset_line_item.dart';
import 'package:balance_sheet/models/other_investment.dart';
import 'package:get/get.dart';

/// Manual stock positions, lot history, and price points for charts / net worth.
class HoldingRowData {
  HoldingRowData({
    required this.quantity,
    required this.valueMinor,
    required this.deltaMinor,
    required this.deltaPct,
  });

  final double quantity;
  final int valueMinor;
  final int? deltaMinor;
  final double? deltaPct;
}

class InvestmentController extends GetxController {
  final RxList<InvestmentHolding> holdings = <InvestmentHolding>[].obs;
  final RxInt stocksTotalMinor = 0.obs;

  /// Sum of [otherInvestments] in LCY (net worth).
  final RxInt otherInvestmentsTotalMinor = 0.obs;
  final RxList<OtherInvestment> otherInvestments = <OtherInvestment>[].obs;
  final RxMap<int, HoldingRowData> rowByHoldingId = <int, HoldingRowData>{}.obs;
  final RxList<({int ms, int valueMinor})> portfolioHistory =
      <({int ms, int valueMinor})>[].obs;
  final Rxn<double> portfolioDayChangePct = Rxn<double>();
  final RxInt portfolioDayChangeMinor = 0.obs;

  final Rxn<double> portfolioPerformancePct = Rxn<double>();
  final RxInt portfolioPerformanceMinor = 0.obs;

  final RxBool loading = false.obs;

  int netWorthMinor(int ledgerBalanceMinor) =>
      ledgerBalanceMinor +
      stocksTotalMinor.value +
      otherInvestmentsTotalMinor.value;

  Future<void> reload() async {
    loading.value = true;
    try {
      final List<InvestmentHolding> list = await inv.listInvestmentHoldings();
      holdings.assignAll(list);
      stocksTotalMinor.value = await inv.getInvestmentStocksTotalMinor();
      otherInvestments.assignAll(await inv.listOtherInvestments());
      otherInvestmentsTotalMinor.value =
          await inv.getOtherInvestmentsTotalLcyMinor();

      final Map<int, HoldingRowData> rows = <int, HoldingRowData>{};
      for (final InvestmentHolding h in list) {
        final ({int valueMinor, int? deltaMinor, double? deltaPct}) m =
            await inv.holdingMetrics(h.id);
        final double qty = await inv.totalQuantityForHolding(h.id);
        rows[h.id] = HoldingRowData(
          quantity: qty,
          valueMinor: m.valueMinor,
          deltaMinor: m.deltaMinor,
          deltaPct: m.deltaPct,
        );
      }
      rowByHoldingId.assignAll(rows);

      final ({int deltaMinor, double? pct}) day =
          await inv.portfolioStocksDayChange();
      portfolioDayChangeMinor.value = day.deltaMinor;
      portfolioDayChangePct.value = day.pct;

      final ({int deltaMinor, double? pct}) perf =
          await inv.portfolioStocksTotalPerformance();
      portfolioPerformanceMinor.value = perf.deltaMinor;
      portfolioPerformancePct.value = perf.pct;

      portfolioHistory.assignAll(await inv.getPortfolioStocksHistory());
    } finally {
      loading.value = false;
    }
  }

  Future<void> addOtherInvestment({
    required String label,
    required bool entryIsFcy,
  }) async {
    await inv.insertOtherInvestment(
      label: label,
      entryCurrency: entryIsFcy ? 'fcy' : 'lcy',
    );
    await reload();
  }

  Future<void> updateOtherInvestment(OtherInvestment o) async {
    await inv.updateOtherInvestment(o);
    await reload();
  }

  Future<void> deleteOtherInvestment(int id) async {
    await inv.deleteOtherInvestment(id);
    await reload();
  }

  Future<List<OtherAssetLineItem>> getLineItemsForAsset(int assetId) {
    return inv.listOtherAssetLineItems(assetId);
  }

  Future<void> addOtherAssetLineItem({
    required int assetId,
    required String description,
    required int amountMinor,
    required bool entryIsFcy,
    required int entryAmountMinor,
    required int occurredAtMs,
  }) async {
    await inv.insertOtherAssetLineItem(
      assetId: assetId,
      description: description,
      amountMinor: amountMinor,
      entryCurrency: entryIsFcy ? 'fcy' : 'lcy',
      entryAmountMinor: entryAmountMinor,
      occurredAtMs: occurredAtMs,
    );
    await reload();
  }

  Future<void> updateOtherAssetLineItem(OtherAssetLineItem item) async {
    await inv.updateOtherAssetLineItem(item);
    await reload();
  }

  Future<void> deleteOtherAssetLineItem(int id, int assetId) async {
    await inv.deleteOtherAssetLineItem(id, assetId);
    await reload();
  }

  @override
  void onReady() {
    super.onReady();
    reload();
  }
}
