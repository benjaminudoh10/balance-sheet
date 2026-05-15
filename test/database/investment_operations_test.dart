import 'package:balance_sheet/database/investment_operations.dart' as inv_ops;
import 'package:balance_sheet/models/investment_holding.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/database_test_setup.dart';

void main() {
  setUpAll(() {
    initializeSqfliteFfiForTests();
  });

  setUp(() async {
    await resetAppDatabaseFile();
  });

  group('Investment Operations Sorting', () {
    test(
        'listInvestmentHoldings returns holdings sorted alphabetically by ticker',
        () async {
      // Insert in non-alphabetical order
      await inv_ops.insertInvestmentHolding(
          ticker: 'Zebra', displayName: 'Zebra Co');
      await inv_ops.insertInvestmentHolding(
          ticker: 'Apple', displayName: 'Apple Inc');
      await inv_ops.insertInvestmentHolding(
          ticker: 'Microsoft', displayName: 'Microsoft Corp');

      final List<InvestmentHolding> holdings =
          await inv_ops.listInvestmentHoldings();

      expect(holdings.length, 3);
      // insertInvestmentHolding converts tickers to uppercase
      expect(holdings[0].ticker, 'APPLE');
      expect(holdings[1].ticker, 'MICROSOFT');
      expect(holdings[2].ticker, 'ZEBRA');
    });

    test('listLotsForHolding returns lots in reverse chronological order',
        () async {
      final int hid = await inv_ops.insertInvestmentHolding(
          ticker: 'TST', displayName: 'Test');

      final int t1 = DateTime(2026, 1, 1).millisecondsSinceEpoch;
      final int t2 = DateTime(2026, 1, 2).millisecondsSinceEpoch;
      final int t3 = DateTime(2026, 1, 3).millisecondsSinceEpoch;

      await inv_ops.insertInvestmentLot(
          holdingId: hid,
          occurredAtMs: t1,
          quantityDelta: 1,
          purchasePriceMinorPerShare: 100);
      await inv_ops.insertInvestmentLot(
          holdingId: hid,
          occurredAtMs: t3,
          quantityDelta: 1,
          purchasePriceMinorPerShare: 100);
      await inv_ops.insertInvestmentLot(
          holdingId: hid,
          occurredAtMs: t2,
          quantityDelta: 1,
          purchasePriceMinorPerShare: 100);

      final lots = await inv_ops.listLotsForHolding(hid);

      expect(lots.length, 3);
      expect(lots[0].occurredAtMs, t3);
      expect(lots[1].occurredAtMs, t2);
      expect(lots[2].occurredAtMs, t1);
    });

    test(
        'listPricePointsForHolding returns prices in reverse chronological order',
        () async {
      final int hid = await inv_ops.insertInvestmentHolding(
          ticker: 'TST', displayName: 'Test');

      await inv_ops.insertInvestmentPricePoint(
          holdingId: hid, asOfDayYyyymmdd: 20260101, priceMinorPerShare: 100);
      await inv_ops.insertInvestmentPricePoint(
          holdingId: hid, asOfDayYyyymmdd: 20260103, priceMinorPerShare: 300);
      await inv_ops.insertInvestmentPricePoint(
          holdingId: hid, asOfDayYyyymmdd: 20260102, priceMinorPerShare: 200);

      final prices = await inv_ops.listPricePointsForHolding(hid);

      expect(prices.length, 3);
      expect(prices[0].asOfDay, 20260103);
      expect(prices[1].asOfDay, 20260102);
      expect(prices[2].asOfDay, 20260101);
    });
  });
}
