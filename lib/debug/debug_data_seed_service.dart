import 'dart:math' as math;

import 'package:balance_sheet/backup/backup_service.dart';
import 'package:balance_sheet/constants/db.dart';
import 'package:balance_sheet/database/db.dart';
import 'package:balance_sheet/investment/investment_days.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

/// Inserts rich sample data for development and QA. **Debug builds only** ([kDebugMode]).
///
/// Replaces all database rows targeted by the debug “clear local data” action (ledger, budget,
/// investments) so the dataset stays coherent. Does **not** change [GetStorage] preferences.
///
/// Each run uses a fresh [math.Random] seed so amounts, dates within months, and portfolio
/// marks differ while still spanning many calendar months.
class DebugDataSeedService {
  DebugDataSeedService._();

  static Future<void> apply() async {
    if (!kDebugMode) {
      return;
    }

    final math.Random rng = math.Random();

    final Database db = await AppDb().db;
    await db.transaction((Transaction sqlTxn) async {
      await _wipeDatabase(sqlTxn);

      final _Contacts c = await _insertContacts(sqlTxn);
      await _insertTransactions(sqlTxn, c, rng);
      await _insertBudgets(sqlTxn, c, rng);
      await _insertInvestments(sqlTxn, rng);
      await _insertOtherAssets(sqlTxn, rng);
    });

    await BackupService.refreshControllersAfterImport();
  }

  static Future<void> _wipeDatabase(Transaction sqlTxn) async {
    await sqlTxn.delete(DBConstants.INVESTMENT_PRICE);
    await sqlTxn.delete(DBConstants.INVESTMENT_LOT);
    await sqlTxn.delete(DBConstants.INVESTMENT_HOLDING);
    await sqlTxn.delete(DBConstants.INVESTMENT_OTHER_ASSET);
    await sqlTxn.delete(DBConstants.BUDGET_LINE);
    await sqlTxn.delete(DBConstants.BUDGET_MONTH);
    await sqlTxn.rawUpdate('UPDATE ${DBConstants.TRANSACTION} SET contactId = NULL');
    await sqlTxn.rawUpdate('UPDATE ${DBConstants.BUDGET_LINE} SET contact_id = NULL');
    await sqlTxn.delete(DBConstants.TRANSACTION);
    await sqlTxn.delete(DBConstants.CONTACT);
  }
}

class _Contacts {
  const _Contacts({
    required this.alex,
    required this.riverMarket,
    required this.powerCo,
    required this.savingsCircle,
    required this.metroTransit,
  });

  final int alex;
  final int riverMarket;
  final int powerCo;
  final int savingsCircle;
  final int metroTransit;
}

int _rnd(math.Random r, int min, int max) {
  return min + r.nextInt(max - min + 1);
}

DateTime _rndTimeOnDay(math.Random r, int y, int m, int d) {
  return DateTime(y, m, d, _rnd(r, 6, 22), _rnd(r, 0, 59));
}

int _lastDayOfMonth(int y, int m) => DateTime(y, m + 1, 0).day;

/// Demo FX: 1 USD (major) = 1400 LCY major → LCY minor = USD cents × 1400.
int _usdCentsToLcyMinor(int usdCents) => usdCents * 1400;

Future<_Contacts> _insertContacts(Transaction sqlTxn) async {
  Future<int> ins(String name) async {
    return sqlTxn.insert(
      DBConstants.CONTACT,
      <String, Object?>{'name': name},
    );
  }

  return _Contacts(
    alex: await ins('Alex Chen'),
    riverMarket: await ins('River Market'),
    powerCo: await ins('City Power Co.'),
    savingsCircle: await ins('Savings Circle'),
    metroTransit: await ins('Metro Transit'),
  );
}

Future<void> _insertTransactions(Transaction sqlTxn, _Contacts c, math.Random r) async {
  final DateTime now = DateTime.now();

  Future<void> income({
    required String description,
    required String category,
    required int amountMinor,
    required DateTime date,
    int contactId = 0,
    bool entryFcy = false,
    int entryMinor = 0,
  }) async {
    final int entry = entryFcy ? entryMinor : amountMinor;
    await sqlTxn.insert(DBConstants.TRANSACTION, <String, Object?>{
      'description': description,
      'type': 'income',
      'amount': amountMinor,
      'date': date.millisecondsSinceEpoch,
      'category': category,
      'contactId': contactId > 0 ? contactId : null,
      'entryCurrency': entryFcy ? 'fcy' : 'lcy',
      'entryAmount': entry,
    });
  }

  Future<void> exp({
    required String description,
    required String category,
    required int amountMinor,
    required DateTime date,
    int contactId = 0,
    bool entryFcy = false,
    int entryMinor = 0,
  }) async {
    final int entry = entryFcy ? entryMinor : amountMinor;
    await sqlTxn.insert(DBConstants.TRANSACTION, <String, Object?>{
      'description': description,
      'type': 'expenditure',
      'amount': amountMinor,
      'date': date.millisecondsSinceEpoch,
      'category': category,
      'contactId': contactId > 0 ? contactId : null,
      'entryCurrency': entryFcy ? 'fcy' : 'lcy',
      'entryAmount': entry,
    });
  }

  // Total calendar months of history (inclusive of current month).
  final int monthSpan = _rnd(r, 16, 26);

  for (int back = monthSpan; back >= 0; back--) {
    final DateTime month = DateTime(now.year, now.month - back, 1);
    final int y = month.year;
    final int m = month.month;
    final int lastDay = _lastDayOfMonth(y, m);

    // Older months: sparser activity
    final bool sparse = back > 14;
    final bool medium = back > 6 && back <= 14;

    final int salaryMinor = _rnd(r, 4650000, 5350000);
    final int payDay = _rnd(r, 1, math.min(5, lastDay));
    await income(
      description: 'Salary deposit',
      category: 'salary',
      amountMinor: salaryMinor,
      date: _rndTimeOnDay(r, y, m, payDay),
      contactId: c.alex,
    );

    final int rentMinor = _rnd(r, 1080000, 1320000);
    final int rentDay = _rnd(r, 1, math.min(7, lastDay));
    await exp(description: 'Rent', category: 'rent', amountMinor: rentMinor, date: _rndTimeOnDay(r, y, m, rentDay));

    final int foodTrips = sparse ? _rnd(r, 2, 4) : (medium ? _rnd(r, 4, 7) : _rnd(r, 5, 10));
    for (int t = 0; t < foodTrips; t++) {
      final int day = _rnd(r, 1, lastDay);
      final int amt = _rnd(r, 75000, 165000);
      final bool withContact = r.nextBool();
      await exp(
        description: r.nextBool() ? 'Groceries' : 'Food & supplies',
        category: 'food',
        amountMinor: amt,
        date: _rndTimeOnDay(r, y, m, day),
        contactId: withContact ? c.riverMarket : 0,
      );
    }

    if (!sparse || r.nextDouble() < 0.85) {
      await exp(
        description: 'Fuel / transit',
        category: 'transport',
        amountMinor: _rnd(r, 35000, 95000),
        date: _rndTimeOnDay(r, y, m, _rnd(r, 1, lastDay)),
        contactId: r.nextBool() ? c.metroTransit : 0,
      );
    }

    if (!sparse || r.nextDouble() < 0.7) {
      await exp(
        description: 'Utilities',
        category: 'utilities',
        amountMinor: _rnd(r, 12000, 72000),
        date: _rndTimeOnDay(r, y, m, _rnd(r, 3, lastDay)),
        contactId: r.nextBool() ? c.powerCo : 0,
      );
    }

    if (medium || !sparse) {
      if (r.nextDouble() < 0.75) {
        await exp(
          description: 'Charity',
          category: 'charity',
          amountMinor: _rnd(r, 5000, 45000),
          date: _rndTimeOnDay(r, y, m, _rnd(r, 1, lastDay)),
        );
      }
      if (r.nextDouble() < 0.8) {
        await exp(
          description: 'Investments',
          category: 'investment',
          amountMinor: _rnd(r, 80000, 420000),
          date: _rndTimeOnDay(r, y, m, _rnd(r, 1, lastDay)),
        );
      }
      if (r.nextDouble() < 0.75) {
        await exp(
          description: 'Savings transfer',
          category: 'savings',
          amountMinor: _rnd(r, 50000, 320000),
          date: _rndTimeOnDay(r, y, m, _rnd(r, 1, lastDay)),
          contactId: r.nextBool() ? c.savingsCircle : 0,
        );
      }
      await exp(
        description: 'Misc',
        category: 'misc',
        amountMinor: _rnd(r, 8000, 48000),
        date: _rndTimeOnDay(r, y, m, _rnd(r, 1, lastDay)),
      );
    } else if (sparse && r.nextDouble() < 0.55) {
      await exp(
        description: 'Misc',
        category: 'misc',
        amountMinor: _rnd(r, 5000, 28000),
        date: _rndTimeOnDay(r, y, m, _rnd(r, 1, lastDay)),
      );
    }

    // FCY subscription (USD cents × 1400 → LCY minor)
    if (!sparse || r.nextDouble() < 0.5) {
      final int usdCents = _rnd(r, 2999, 8999);
      await exp(
        description: 'Cloud subscription (USD)',
        category: 'utilities',
        amountMinor: _usdCentsToLcyMinor(usdCents),
        date: _rndTimeOnDay(r, y, m, _rnd(r, 5, math.min(20, lastDay))),
        entryFcy: true,
        entryMinor: usdCents,
      );
    }

    if (back == 0 && r.nextDouble() < 0.85) {
      await income(
        description: 'Freelance invoice',
        category: 'salary',
        amountMinor: _rnd(r, 350000, 1250000),
        date: _rndTimeOnDay(r, y, m, _rnd(r, 10, lastDay)),
      );
    }
  }

  // One-off bonus in a random recent December
  final int bonusYear = now.month >= 3 ? now.year - 1 : now.year - 2;
  await income(
    description: 'Annual bonus',
    category: 'salary',
    amountMinor: _rnd(r, 900000, 2200000),
    date: _rndTimeOnDay(r, bonusYear, 12, _rnd(r, 10, 28)),
    contactId: c.alex,
  );
}

Future<void> _insertBudgets(Transaction sqlTxn, _Contacts c, math.Random r) async {
  final DateTime now = DateTime.now();

  Future<int> monthId(int year, int month) async {
    return sqlTxn.insert(DBConstants.BUDGET_MONTH, <String, Object?>{
      'year': year,
      'month': month,
    });
  }

  Future<void> line({
    required int budgetMonthId,
    required String description,
    required int plannedMinor,
    int contactId = 0,
    String category = '',
    required int sortOrder,
    bool planFcy = false,
    int planEntryMinor = 0,
  }) async {
    final int entry = planFcy ? planEntryMinor : plannedMinor;
    await sqlTxn.insert(DBConstants.BUDGET_LINE, <String, Object?>{
      'budget_month_id': budgetMonthId,
      'description': description,
      'planned_amount': plannedMinor,
      'contact_id': contactId > 0 ? contactId : null,
      'category': category,
      'sort_order': sortOrder,
      'entryCurrency': planFcy ? 'fcy' : 'lcy',
      'entryAmount': entry,
    });
  }

  final int budgetMonths = _rnd(r, 6, 11);
  for (int back = 0; back < budgetMonths; back++) {
    final DateTime ref = DateTime(now.year, now.month - back, 1);
    final int y = ref.year;
    final int m = ref.month;
    final int mid = await monthId(y, m);

    final int foodBase = _rnd(r, 620000, 880000);
    final int rentBase = _rnd(r, 1180000, 1320000);
    final int utilBundle = _rnd(r, 140000, 220000);

    await line(
      budgetMonthId: mid,
      description: 'Food & groceries',
      plannedMinor: foodBase + _rnd(r, -40000, 80000),
      category: 'food',
      sortOrder: 0,
    );
    await line(
      budgetMonthId: mid,
      description: 'Rent',
      plannedMinor: rentBase,
      category: 'rent',
      sortOrder: 1,
    );
    await line(
      budgetMonthId: mid,
      description: 'Utilities bundle',
      plannedMinor: utilBundle,
      category: 'utilities',
      sortOrder: 2,
    );
    await line(
      budgetMonthId: mid,
      description: 'Spend with River Market',
      plannedMinor: _rnd(r, 320000, 520000),
      contactId: c.riverMarket,
      sortOrder: 3,
    );
    await line(
      budgetMonthId: mid,
      description: 'Power company',
      plannedMinor: _rnd(r, 52000, 82000),
      category: 'utilities',
      contactId: c.powerCo,
      sortOrder: 4,
    );
    await line(
      budgetMonthId: mid,
      description: 'Transit (category + contact)',
      plannedMinor: _rnd(r, 38000, 65000),
      category: 'transport',
      contactId: c.metroTransit,
      sortOrder: 5,
    );
  }
}

Future<void> _insertInvestments(Transaction sqlTxn, math.Random r) async {
  final int nowMs = DateTime.now().millisecondsSinceEpoch;
  final DateTime today = DateTime.now();

  Future<int> holding(String ticker, String name, int sort) async {
    return sqlTxn.insert(DBConstants.INVESTMENT_HOLDING, <String, Object?>{
      'ticker': ticker,
      'display_name': name,
      'sort_order': sort,
      'created_at_ms': nowMs - _rnd(r, 300, 500) * 86400000,
    });
  }

  final int vti = await holding('VTI', 'Vanguard Total Stock', 0);
  final int aapl = await holding('AAPL', 'Apple Inc.', 1);

  Future<void> lot({
    required int holdingId,
    required DateTime when,
    required double qty,
    required int priceMinorLcy,
    bool purchaseFcy = false,
    int? entryMinor,
  }) async {
    await sqlTxn.insert(DBConstants.INVESTMENT_LOT, <String, Object?>{
      'holding_id': holdingId,
      'occurred_at_ms': when.millisecondsSinceEpoch,
      'quantity_delta': qty,
      'purchase_price_minor_per_share': priceMinorLcy,
      'purchase_entry_currency': purchaseFcy ? 'fcy' : 'lcy',
      'purchase_price_entry_minor': entryMinor ?? priceMinorLcy,
      'note': '',
    });
  }

  Future<void> price({
    required int holdingId,
    required DateTime day,
    required int priceMinorLcy,
    bool entryFcy = false,
    int? entryMinor,
  }) async {
    final int ymd = encodeLocalYyyymmdd(DateTime(day.year, day.month, day.day));
    final int ms = localMidnightFromYyyymmdd(ymd).millisecondsSinceEpoch;
    final int em = entryMinor ?? priceMinorLcy;
    await sqlTxn.insert(DBConstants.INVESTMENT_PRICE, <String, Object?>{
      'holding_id': holdingId,
      'as_of_ms': ms,
      'as_of_day': ymd,
      'price_minor_per_share': priceMinorLcy,
      'entry_currency': entryFcy ? 'fcy' : 'lcy',
      'price_entry_minor': em,
    });
  }

  final int vtiHorizon = _rnd(r, 12, 18);
  final int d1 = _rnd(r, 1, 28);
  await lot(
    holdingId: vti,
    when: _rndTimeOnDay(r, today.year, today.month - vtiHorizon, d1),
    qty: 8 + r.nextDouble() * 8,
    priceMinorLcy: _rnd(r, 195000, 235000),
  );
  await lot(
    holdingId: vti,
    when: _rndTimeOnDay(r, today.year, today.month - _rnd(r, 5, 10), _rnd(r, 1, 28)),
    qty: 4 + r.nextDouble() * 6,
    priceMinorLcy: _rnd(r, 205000, 245000),
  );
  if (r.nextBool()) {
    await lot(
      holdingId: vti,
      when: _rndTimeOnDay(r, today.year, today.month - _rnd(r, 1, 4), _rnd(r, 1, 28)),
      qty: -(1 + r.nextDouble() * 4),
      priceMinorLcy: _rnd(r, 210000, 250000),
    );
  }

  int vtiMark = _rnd(r, 198000, 228000);
  for (int i = 0; i <= vtiHorizon; i++) {
    final DateTime d = DateTime(today.year, today.month - (vtiHorizon - i), _rnd(r, 1, 28));
    vtiMark += _rnd(r, -8000, 12000);
    vtiMark = vtiMark.clamp(170000, 280000);
    await price(holdingId: vti, day: d, priceMinorLcy: vtiMark);
  }

  final int usdCentsBuy = _rnd(r, 16500, 21000);
  final int aaplLcyPerShare = _usdCentsToLcyMinor(usdCentsBuy);
  await lot(
    holdingId: aapl,
    when: _rndTimeOnDay(r, today.year, today.month - _rnd(r, 4, 9), _rnd(r, 1, 28)),
    qty: 2 + r.nextDouble() * 5,
    priceMinorLcy: aaplLcyPerShare,
    purchaseFcy: true,
    entryMinor: usdCentsBuy,
  );

  final int weeks = _rnd(r, 8, 14);
  int aaplMarkLcy = _rnd(r, 25000000, 28500000);
  int aaplUsdCents = _rnd(r, 17500, 20500);
  for (int w = 0; w < weeks; w++) {
    final DateTime d = DateTime(today.year, today.month, today.day).subtract(Duration(days: w * 7 + _rnd(r, 0, 3)));
    aaplMarkLcy += _rnd(r, -420000, 480000);
    aaplUsdCents += _rnd(r, -250, 280);
    await price(
      holdingId: aapl,
      day: d,
      priceMinorLcy: aaplMarkLcy,
      entryFcy: true,
      entryMinor: aaplUsdCents.clamp(12000, 28000),
    );
  }
}

Future<void> _insertOtherAssets(Transaction sqlTxn, math.Random r) async {
  final int t = DateTime.now().millisecondsSinceEpoch;

  Future<void> row(String label, int lcyMinor, int sort, {bool fcy = false, int entryMinor = 0}) async {
    final int em = fcy ? entryMinor : lcyMinor;
    await sqlTxn.insert(DBConstants.INVESTMENT_OTHER_ASSET, <String, Object?>{
      'label': label,
      'value_lcy_minor': lcyMinor,
      'entry_currency': fcy ? 'fcy' : 'lcy',
      'entry_minor': em,
      'sort_order': sort,
      'updated_at_ms': t,
    });
  }

  await row('High-yield savings', _rnd(r, 18000000, 32000000), 0);
  await row('Physical gold (oz)', _rnd(r, 6200000, 10200000), 1);
  final int walletUsdCents = _rnd(r, 180000, 320000);
  await row(
    'USD cash wallet',
    _usdCentsToLcyMinor(walletUsdCents),
    2,
    fcy: true,
    entryMinor: walletUsdCents,
  );
}
