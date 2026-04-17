import 'package:balance_sheet/backup/backup_service.dart';
import 'package:balance_sheet/constants/app.dart';
import 'package:balance_sheet/constants/db.dart';
import 'package:balance_sheet/database/db.dart';
import 'package:balance_sheet/security/pin_hash.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sqflite/sqflite.dart';

/// Local data categories for the debug-only clear screen.
enum DebugDataClearTarget {
  /// All rows in [DBConstants.TRANSACTION].
  transactions,

  /// All rows in [DBConstants.CONTACT] (FKs on transactions and budget lines are cleared first).
  contacts,

  /// [DBConstants.BUDGET_LINE] then [DBConstants.BUDGET_MONTH].
  budget,

  /// Stock side: [DBConstants.INVESTMENT_PRICE], [DBConstants.INVESTMENT_LOT], [DBConstants.INVESTMENT_HOLDING].
  investmentStocks,

  /// [DBConstants.INVESTMENT_OTHER_ASSET] rows (e.g. cash / manual assets).
  investmentOther,

  /// Font + theme mode in [GetStorage].
  prefAppearance,

  /// LCY/FCY codes and manual rate in [GetStorage].
  prefCurrency,

  /// PIN hash/salt, legacy PIN key, fingerprint flag in [GetStorage].
  prefSecurity,
}

/// Clears selected SQLite tables and/or known [GetStorage] keys. **Debug builds only** ([kDebugMode]).
class DebugDataClearService {
  DebugDataClearService._();

  static Future<void> apply(Set<DebugDataClearTarget> targets) async {
    if (!kDebugMode || targets.isEmpty) {
      return;
    }

    final bool dbStock = targets.contains(DebugDataClearTarget.investmentStocks);
    final bool dbOther = targets.contains(DebugDataClearTarget.investmentOther);
    final bool dbBudget = targets.contains(DebugDataClearTarget.budget);
    final bool dbTxn = targets.contains(DebugDataClearTarget.transactions);
    final bool dbContact = targets.contains(DebugDataClearTarget.contacts);

    final Database db = await AppDb().db;
    await db.transaction((Transaction txn) async {
      if (dbStock) {
        await txn.delete(DBConstants.INVESTMENT_PRICE);
        await txn.delete(DBConstants.INVESTMENT_LOT);
        await txn.delete(DBConstants.INVESTMENT_HOLDING);
      }
      if (dbOther) {
        await txn.delete(DBConstants.INVESTMENT_OTHER_ASSET);
      }
      if (dbBudget) {
        await txn.delete(DBConstants.BUDGET_LINE);
        await txn.delete(DBConstants.BUDGET_MONTH);
      }
      if (dbContact) {
        await txn.rawUpdate('UPDATE ${DBConstants.TRANSACTION} SET contactId = NULL');
        await txn.rawUpdate('UPDATE ${DBConstants.BUDGET_LINE} SET contact_id = NULL');
      }
      if (dbTxn) {
        await txn.delete(DBConstants.TRANSACTION);
      }
      if (dbContact) {
        await txn.delete(DBConstants.CONTACT);
      }
    });

    final GetStorage box = GetStorage();
    if (targets.contains(DebugDataClearTarget.prefAppearance)) {
      await box.remove(AppConstants.APP_FONT_KEY);
      await box.remove(AppConstants.APP_THEME_MODE_KEY);
    }
    if (targets.contains(DebugDataClearTarget.prefCurrency)) {
      await box.remove(AppConstants.CURRENCY_LCY_KEY);
      await box.remove(AppConstants.CURRENCY_FCY_KEY);
      await box.remove(AppConstants.CURRENCY_RATE_KEY);
    }
    if (targets.contains(DebugDataClearTarget.prefSecurity)) {
      await PinHash.clearPin(box);
      await box.remove(AppConstants.USE_FINGERPRINT);
    }

    await BackupService.refreshControllersAfterImport();
  }

  /// Every database-backed target (excludes preferences).
  static const Set<DebugDataClearTarget> allDatabaseTargets = <DebugDataClearTarget>{
    DebugDataClearTarget.transactions,
    DebugDataClearTarget.contacts,
    DebugDataClearTarget.budget,
    DebugDataClearTarget.investmentStocks,
    DebugDataClearTarget.investmentOther,
  };

  static const Set<DebugDataClearTarget> allPreferenceTargets = <DebugDataClearTarget>{
    DebugDataClearTarget.prefAppearance,
    DebugDataClearTarget.prefCurrency,
    DebugDataClearTarget.prefSecurity,
  };

  static const Set<DebugDataClearTarget> allTargets = <DebugDataClearTarget>{
    ...allDatabaseTargets,
    ...allPreferenceTargets,
  };
}
