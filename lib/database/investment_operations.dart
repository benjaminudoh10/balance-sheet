import 'dart:math' as math;

import 'package:balance_sheet/constants/db.dart';
import 'package:balance_sheet/database/db.dart';
import 'package:balance_sheet/investment/investment_days.dart';
import 'package:balance_sheet/models/investment_holding.dart';
import 'package:balance_sheet/models/investment_lot_entry.dart';
import 'package:balance_sheet/models/investment_price_point.dart';
import 'package:balance_sheet/models/other_investment.dart';
import 'package:sqflite/sqflite.dart';

class _FifoLayer {
  _FifoLayer(this.qty, this.priceMinorPerShare);
  double qty;
  final int priceMinorPerShare;
}

// --- Holdings ---

Future<int> nextInvestmentSortOrder() async {
  final Database dbClient = await AppDb().db;
  final List<Map<String, Object?>> rows = await dbClient.rawQuery(
    'SELECT COALESCE(MAX(sort_order), -1) + 1 AS n FROM ${DBConstants.INVESTMENT_HOLDING}',
  );
  final Object? n = rows.first['n'];
  if (n is int) return n;
  if (n is num) return n.toInt();
  return 0;
}

Future<int> insertInvestmentHolding({
  required String ticker,
  String displayName = '',
}) async {
  final Database dbClient = await AppDb().db;
  final int now = DateTime.now().millisecondsSinceEpoch;
  return dbClient.insert(DBConstants.INVESTMENT_HOLDING, <String, Object?>{
    'ticker': ticker.trim().toUpperCase(),
    'display_name': displayName.trim(),
    'sort_order': await nextInvestmentSortOrder(),
    'created_at_ms': now,
  });
}

Future<void> updateInvestmentHolding(InvestmentHolding h) async {
  final Database dbClient = await AppDb().db;
  await dbClient.update(
    DBConstants.INVESTMENT_HOLDING,
    <String, Object?>{
      'ticker': h.ticker.trim().toUpperCase(),
      'display_name': h.displayName.trim(),
      'sort_order': h.sortOrder,
      'created_at_ms': h.createdAtMs,
    },
    where: 'id = ?',
    whereArgs: <Object>[h.id],
  );
}

Future<List<InvestmentHolding>> listInvestmentHoldings() async {
  final Database dbClient = await AppDb().db;
  final List<Map<String, Object?>> rows = await dbClient.query(
    DBConstants.INVESTMENT_HOLDING,
    orderBy: 'ticker ASC',
  );
  return rows.map(InvestmentHolding.fromMap).toList();
}

Future<InvestmentHolding?> getInvestmentHolding(int id) async {
  final Database dbClient = await AppDb().db;
  final List<Map<String, Object?>> rows = await dbClient.query(
    DBConstants.INVESTMENT_HOLDING,
    where: 'id = ?',
    whereArgs: <Object>[id],
    limit: 1,
  );
  if (rows.isEmpty) return null;
  return InvestmentHolding.fromMap(rows.first);
}

Future<void> deleteInvestmentHolding(int id) async {
  final Database dbClient = await AppDb().db;
  await dbClient.delete(
    DBConstants.INVESTMENT_LOT,
    where: 'holding_id = ?',
    whereArgs: <Object>[id],
  );
  await dbClient.delete(
    DBConstants.INVESTMENT_PRICE,
    where: 'holding_id = ?',
    whereArgs: <Object>[id],
  );
  await dbClient.delete(
    DBConstants.INVESTMENT_HOLDING,
    where: 'id = ?',
    whereArgs: <Object>[id],
  );
}

// --- Lots ---

Future<int> insertInvestmentLot({
  required int holdingId,
  required int occurredAtMs,
  required double quantityDelta,

  /// Canonical FIFO cost: **LCY** minor per share.
  required int purchasePriceMinorPerShare,
  bool purchaseEntryIsFcy = false,
  int? purchasePriceEntryMinorPerShare,
  String note = '',
}) async {
  final Database dbClient = await AppDb().db;
  final int entryMinor =
      purchasePriceEntryMinorPerShare ?? purchasePriceMinorPerShare;
  return dbClient.insert(DBConstants.INVESTMENT_LOT, <String, Object?>{
    'holding_id': holdingId,
    'occurred_at_ms': occurredAtMs,
    'quantity_delta': quantityDelta,
    'purchase_price_minor_per_share': purchasePriceMinorPerShare,
    'purchase_entry_currency': purchaseEntryIsFcy ? 'fcy' : 'lcy',
    'purchase_price_entry_minor': entryMinor,
    'note': note.trim(),
  });
}

Future<void> deleteInvestmentLot(int lotId) async {
  final Database dbClient = await AppDb().db;
  await dbClient.delete(
    DBConstants.INVESTMENT_LOT,
    where: 'id = ?',
    whereArgs: <Object>[lotId],
  );
}

Future<List<InvestmentLotEntry>> listLotsForHolding(int holdingId) async {
  final Database dbClient = await AppDb().db;
  final List<Map<String, Object?>> rows = await dbClient.query(
    DBConstants.INVESTMENT_LOT,
    where: 'holding_id = ?',
    whereArgs: <Object>[holdingId],
    orderBy: 'occurred_at_ms DESC, id DESC',
  );
  return rows.map(InvestmentLotEntry.fromMap).toList();
}

Future<double> totalQuantityForHoldingAtMs(int holdingId, int maxMs) async {
  final Database dbClient = await AppDb().db;
  final List<Map<String, Object?>> rows = await dbClient.rawQuery(
    '''
    SELECT COALESCE(SUM(quantity_delta), 0) AS s
    FROM ${DBConstants.INVESTMENT_LOT}
    WHERE holding_id = ? AND occurred_at_ms <= ?
    ''',
    <Object>[holdingId, maxMs],
  );
  final Object? s = rows.first['s'];
  if (s is num) return s.toDouble();
  return double.tryParse('$s') ?? 0.0;
}

Future<double> totalQuantityForHolding(int holdingId) async {
  final int now = DateTime.now().millisecondsSinceEpoch;
  return totalQuantityForHoldingAtMs(holdingId, now);
}

// --- Prices ---

/// [asOfDayYyyymmdd] is the **calendar day** of this market snapshot (no time-of-day).
Future<int> insertInvestmentPricePoint({
  required int holdingId,
  required int asOfDayYyyymmdd,

  /// Canonical **LCY** minor per share.
  required int priceMinorPerShare,
  bool entryIsFcy = false,
  int? priceEntryMinorPerShare,
}) async {
  final Database dbClient = await AppDb().db;
  final int ms =
      localMidnightFromYyyymmdd(asOfDayYyyymmdd).millisecondsSinceEpoch;
  final int entryMinor = priceEntryMinorPerShare ?? priceMinorPerShare;
  return dbClient.insert(DBConstants.INVESTMENT_PRICE, <String, Object?>{
    'holding_id': holdingId,
    'as_of_ms': ms,
    'as_of_day': asOfDayYyyymmdd,
    'price_minor_per_share': priceMinorPerShare,
    'entry_currency': entryIsFcy ? 'fcy' : 'lcy',
    'price_entry_minor': entryMinor,
  });
}

Future<void> deleteInvestmentPricePoint(int priceId) async {
  final Database dbClient = await AppDb().db;
  await dbClient.delete(
    DBConstants.INVESTMENT_PRICE,
    where: 'id = ?',
    whereArgs: <Object>[priceId],
  );
}

Future<List<InvestmentPricePoint>> listPricePointsForHolding(
    int holdingId) async {
  final Database dbClient = await AppDb().db;
  final List<Map<String, Object?>> rows = await dbClient.query(
    DBConstants.INVESTMENT_PRICE,
    where: 'holding_id = ?',
    whereArgs: <Object>[holdingId],
    orderBy: 'as_of_day DESC, as_of_ms DESC, id DESC',
  );
  return rows.map(InvestmentPricePoint.fromMap).toList();
}

/// Latest market price on or before local calendar day [maxDayYyyymmdd] (and [maxMs] for legacy rows).
Future<int?> latestMarketPriceMinorOnOrBeforeDay(
    int holdingId, int maxDayYyyymmdd, int maxMsInclusive) async {
  final Database dbClient = await AppDb().db;
  final List<Map<String, Object?>> rows = await dbClient.rawQuery(
    '''
    SELECT price_minor_per_share AS p
    FROM ${DBConstants.INVESTMENT_PRICE}
    WHERE holding_id = ?
      AND (
        (as_of_day > 0 AND as_of_day <= ?)
        OR (COALESCE(as_of_day, 0) <= 0 AND as_of_ms <= ?)
      )
    ORDER BY as_of_day DESC, as_of_ms DESC, id DESC
    LIMIT 1
    ''',
    <Object>[holdingId, maxDayYyyymmdd, maxMsInclusive],
  );
  if (rows.isEmpty) return null;
  final Object? p = rows.first['p'];
  if (p is int) return p;
  if (p is num) return p.toInt();
  return int.tryParse('$p');
}

Future<int?> latestPriceMinorAtOrBefore(int holdingId, int maxMs) async {
  final int maxDay = encodeLocalYyyymmddFromMs(maxMs);
  return latestMarketPriceMinorOnOrBeforeDay(holdingId, maxDay, maxMs);
}

Future<int?> latestPriceMinorForHolding(int holdingId) async {
  final int now = DateTime.now().millisecondsSinceEpoch;
  return latestPriceMinorAtOrBefore(holdingId, now);
}

/// FIFO remaining position cost (minor) and share count from purchase lots.
Future<({int costBasisMinor, double quantity})> fifoOpenPosition(
    int holdingId) async {
  final List<InvestmentLotEntry> lots = await listLotsForHolding(holdingId);
  // lots are DESC (newest first). FIFO needs ASC (oldest first).
  final List<InvestmentLotEntry> chronological = lots.reversed.toList();

  final List<_FifoLayer> layers = <_FifoLayer>[];
  for (final InvestmentLotEntry lot in chronological) {
    final double q = lot.quantityDelta;
    final int p = lot.purchasePriceMinorPerShare;
    if (q > 1e-9) {
      layers.add(_FifoLayer(q, p));
    } else if (q < -1e-9) {
      double toSell = -q;
      while (toSell > 1e-9 && layers.isNotEmpty) {
        final _FifoLayer first = layers.first;
        final double take = math.min(first.qty, toSell);
        first.qty -= take;
        toSell -= take;
        if (first.qty <= 1e-9) {
          layers.removeAt(0);
        }
      }
    }
  }
  double remQ = 0;
  int cost = 0;
  for (final _FifoLayer l in layers) {
    remQ += l.qty;
    cost += (l.qty * l.priceMinorPerShare).round();
  }
  return (costBasisMinor: cost, quantity: remQ);
}

// --- Other investments (cash, land, metals, etc.) — LCY canonical for net worth ---

int _asInt(Object? v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? 0;
}

Future<int> nextOtherInvestmentSortOrder() async {
  final Database dbClient = await AppDb().db;
  final List<Map<String, Object?>> rows = await dbClient.rawQuery(
    'SELECT COALESCE(MAX(sort_order), -1) + 1 AS n FROM ${DBConstants.INVESTMENT_OTHER_ASSET}',
  );
  final Object? n = rows.first['n'];
  if (n is int) return n;
  if (n is num) return n.toInt();
  return 0;
}

Future<List<OtherInvestment>> listOtherInvestments() async {
  final Database dbClient = await AppDb().db;
  final List<Map<String, Object?>> rows = await dbClient.query(
    DBConstants.INVESTMENT_OTHER_ASSET,
    orderBy: 'sort_order ASC, id ASC',
  );
  return rows.map(OtherInvestment.fromMap).toList();
}

Future<int> getOtherInvestmentsTotalLcyMinor() async {
  final Database dbClient = await AppDb().db;
  final List<Map<String, Object?>> rows = await dbClient.rawQuery(
    'SELECT COALESCE(SUM(value_lcy_minor), 0) AS s FROM ${DBConstants.INVESTMENT_OTHER_ASSET}',
  );
  return _asInt(rows.first['s']);
}

Future<int> insertOtherInvestment({
  required String label,
  required int valueLcyMinor,
  required String entryCurrency,
  required int entryMinor,
}) async {
  final Database dbClient = await AppDb().db;
  final int now = DateTime.now().millisecondsSinceEpoch;
  final String ec = entryCurrency.toLowerCase() == 'fcy' ? 'fcy' : 'lcy';
  return dbClient.insert(DBConstants.INVESTMENT_OTHER_ASSET, <String, Object?>{
    'label': label.trim(),
    'value_lcy_minor': valueLcyMinor,
    'entry_currency': ec,
    'entry_minor': entryMinor,
    'sort_order': await nextOtherInvestmentSortOrder(),
    'updated_at_ms': now,
  });
}

Future<void> updateOtherInvestment(OtherInvestment o) async {
  final Database dbClient = await AppDb().db;
  final int now = DateTime.now().millisecondsSinceEpoch;
  final String ec = o.entryCurrency.toLowerCase() == 'fcy' ? 'fcy' : 'lcy';
  await dbClient.update(
    DBConstants.INVESTMENT_OTHER_ASSET,
    <String, Object?>{
      'label': o.label.trim(),
      'value_lcy_minor': o.valueLcyMinor,
      'entry_currency': ec,
      'entry_minor': o.entryMinor,
      'updated_at_ms': now,
    },
    where: 'id = ?',
    whereArgs: <Object>[o.id],
  );
}

Future<void> deleteOtherInvestment(int id) async {
  final Database dbClient = await AppDb().db;
  await dbClient.delete(
    DBConstants.INVESTMENT_OTHER_ASSET,
    where: 'id = ?',
    whereArgs: <Object>[id],
  );
}

// --- Valuation ---

int _positionValueMinor(double quantity, int? priceMinor) {
  if (priceMinor == null || quantity <= 0) return 0;
  return (quantity * priceMinor).round();
}

/// Total market value of all stock positions (minor units, LCY). Holdings without a price contribute 0.
Future<int> getInvestmentStocksTotalMinor() async {
  final List<InvestmentHolding> holdings = await listInvestmentHoldings();
  int sum = 0;
  final int now = DateTime.now().millisecondsSinceEpoch;
  for (final InvestmentHolding h in holdings) {
    final double q = await totalQuantityForHoldingAtMs(h.id, now);
    final int? p = await latestPriceMinorAtOrBefore(h.id, now);
    sum += _positionValueMinor(q, p);
  }
  return sum;
}

/// Portfolio value at the last moment <= [maxMs] (uses lots and prices effective by then).
Future<int> portfolioStocksValueAtMs(int maxMs) async {
  final List<InvestmentHolding> holdings = await listInvestmentHoldings();
  int sum = 0;
  for (final InvestmentHolding h in holdings) {
    final double q = await totalQuantityForHoldingAtMs(h.id, maxMs);
    final int? p = await latestPriceMinorAtOrBefore(h.id, maxMs);
    sum += _positionValueMinor(q, p);
  }
  return sum;
}

/// Today’s change vs portfolio value at local start-of-day (stocks only).
Future<({int deltaMinor, double? pct})> portfolioStocksDayChange() async {
  final DateTime now = DateTime.now();
  final int startToday =
      DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
  final int endNow = now.millisecondsSinceEpoch;
  final int vNow = await portfolioStocksValueAtMs(endNow);
  final int vOpen = await portfolioStocksValueAtMs(startToday);
  final int delta = vNow - vOpen;
  if (vOpen <= 0) {
    return (deltaMinor: delta, pct: null);
  }
  return (deltaMinor: delta, pct: 100.0 * delta / vOpen);
}

/// [deltaMinor] / [deltaPct] = total gain (realized + unrealized) vs cost basis.
Future<({int valueMinor, int? deltaMinor, double? deltaPct})> holdingMetrics(
    int holdingId) async {
  final int now = DateTime.now().millisecondsSinceEpoch;
  final double q = await totalQuantityForHoldingAtMs(holdingId, now);
  final int maxDay = encodeLocalYyyymmddFromMs(now);
  final int? mkt =
      await latestMarketPriceMinorOnOrBeforeDay(holdingId, maxDay, now);
  final int value = _positionValueMinor(q, mkt);

  final List<InvestmentLotEntry> lots = await listLotsForHolding(holdingId);
  if (lots.isEmpty) {
    return (valueMinor: value, deltaMinor: null, deltaPct: null);
  }

  int totalCostMinor = 0;
  int totalProceedsMinor = 0;
  for (final InvestmentLotEntry lot in lots) {
    final double dq = lot.quantityDelta;
    final int p = lot.purchasePriceMinorPerShare;
    if (dq > 0) {
      totalCostMinor += (dq * p).round();
    } else {
      totalProceedsMinor += (-dq * p).round();
    }
  }

  if (totalCostMinor <= 0) {
    return (valueMinor: value, deltaMinor: null, deltaPct: null);
  }

  final int gain = (value + totalProceedsMinor) - totalCostMinor;
  return (
    valueMinor: value,
    deltaMinor: gain,
    deltaPct: 100.0 * gain / totalCostMinor,
  );
}

/// Total performance (realized + unrealized gain) vs cost basis across all stock holdings.
Future<({int deltaMinor, double? pct})>
    portfolioStocksTotalPerformance() async {
  final List<InvestmentHolding> holdings = await listInvestmentHoldings();
  int totalGain = 0;
  int totalCost = 0;

  final int now = DateTime.now().millisecondsSinceEpoch;
  final int maxDay = encodeLocalYyyymmddFromMs(now);

  for (final InvestmentHolding h in holdings) {
    final double q = await totalQuantityForHoldingAtMs(h.id, now);
    final int? mkt =
        await latestMarketPriceMinorOnOrBeforeDay(h.id, maxDay, now);
    final int value = _positionValueMinor(q, mkt);

    final List<InvestmentLotEntry> lots = await listLotsForHolding(h.id);
    int hCost = 0;
    int hProceeds = 0;
    for (final InvestmentLotEntry lot in lots) {
      final double dq = lot.quantityDelta;
      final int p = lot.purchasePriceMinorPerShare;
      if (dq > 0) {
        hCost += (dq * p).round();
      } else {
        hProceeds += (-dq * p).round();
      }
    }

    totalGain += (value + hProceeds) - hCost;
    totalCost += hCost;
  }

  if (totalCost <= 0) {
    return (deltaMinor: totalGain, pct: null);
  }
  return (deltaMinor: totalGain, pct: 100.0 * totalGain / totalCost);
}

/// Sorted points (end-of-day ms, total minor) for charting portfolio growth. Downsamples if huge.
Future<List<({int ms, int valueMinor})>> getPortfolioStocksHistory(
    {int maxPoints = 200}) async {
  final Database dbClient = await AppDb().db;
  final Set<int> days = <int>{};
  final List<Map<String, Object?>> lotRows = await dbClient.rawQuery(
    'SELECT DISTINCT occurred_at_ms AS t FROM ${DBConstants.INVESTMENT_LOT}',
  );
  for (final Map<String, Object?> m in lotRows) {
    final Object? t = m['t'];
    final int? ms = t is int ? t : (t is num ? t.toInt() : int.tryParse('$t'));
    if (ms != null) {
      days.add(encodeLocalYyyymmddFromMs(ms));
    }
  }
  final List<Map<String, Object?>> priceDayRows = await dbClient.rawQuery(
    'SELECT DISTINCT as_of_day AS d FROM ${DBConstants.INVESTMENT_PRICE} WHERE as_of_day > 0',
  );
  for (final Map<String, Object?> m in priceDayRows) {
    final Object? d = m['d'];
    final int? day = d is int ? d : (d is num ? d.toInt() : int.tryParse('$d'));
    if (day != null && day > 0) {
      days.add(day);
    }
  }
  if (days.isEmpty) {
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int v = await portfolioStocksValueAtMs(now);
    return <({int ms, int valueMinor})>[(ms: now, valueMinor: v)];
  }
  final List<int> sortedDays = days.toList()..sort();
  final List<({int ms, int valueMinor})> raw = <({int ms, int valueMinor})>[];
  for (final int day in sortedDays) {
    final int endMs = endOfLocalDayMs(day);
    final int v = await portfolioStocksValueAtMs(endMs);
    raw.add((ms: endMs, valueMinor: v));
  }
  final int now = DateTime.now().millisecondsSinceEpoch;
  final int vEnd = await portfolioStocksValueAtMs(now);
  if (raw.isEmpty || raw.last.ms < now) {
    raw.add((ms: now, valueMinor: vEnd));
  } else {
    raw[raw.length - 1] = (ms: now, valueMinor: vEnd);
  }
  if (raw.length <= maxPoints) return raw;
  final int step = math.max(1, (raw.length / maxPoints).ceil());
  final List<({int ms, int valueMinor})> out = <({int ms, int valueMinor})>[];
  for (int i = 0; i < raw.length; i += step) {
    out.add(raw[i]);
  }
  if (out.isEmpty || out.last.ms != raw.last.ms) {
    out.add(raw.last);
  }
  return out;
}

Future<int> netWorthTotalMinor({
  required int ledgerBalanceMinor,
}) async {
  final int stocks = await getInvestmentStocksTotalMinor();
  final int other = await getOtherInvestmentsTotalLcyMinor();
  return ledgerBalanceMinor + stocks + other;
}

// --- Backup helpers ---

Future<List<Map<String, Object?>>> queryAllInvestmentHoldingRows() async {
  final Database dbClient = await AppDb().db;
  return dbClient.query(DBConstants.INVESTMENT_HOLDING, orderBy: 'id ASC');
}

Future<List<Map<String, Object?>>> queryAllInvestmentLotRows() async {
  final Database dbClient = await AppDb().db;
  return dbClient.query(DBConstants.INVESTMENT_LOT, orderBy: 'id ASC');
}

Future<List<Map<String, Object?>>> queryAllInvestmentPriceRows() async {
  final Database dbClient = await AppDb().db;
  return dbClient.query(DBConstants.INVESTMENT_PRICE, orderBy: 'id ASC');
}

Future<List<Map<String, Object?>>> queryAllOtherInvestmentRows() async {
  final Database dbClient = await AppDb().db;
  return dbClient.query(DBConstants.INVESTMENT_OTHER_ASSET, orderBy: 'id ASC');
}
