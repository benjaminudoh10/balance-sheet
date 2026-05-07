import 'dart:convert';

import 'package:balance_sheet/constants/app.dart';
import 'package:balance_sheet/constants/backup_constants.dart';
import 'package:balance_sheet/constants/db.dart';
import 'package:balance_sheet/controllers/app_controller.dart';
import 'package:balance_sheet/controllers/currency_controller.dart';
import 'package:balance_sheet/controllers/contact_controller.dart';
import 'package:balance_sheet/controllers/report_controller.dart';
import 'package:balance_sheet/controllers/security_controller.dart';
import 'package:balance_sheet/controllers/investment_controller.dart';
import 'package:balance_sheet/controllers/transaction_controller.dart';
import 'package:balance_sheet/database/db.dart';
import 'package:balance_sheet/database/investment_operations.dart' as inv_db;
import 'package:balance_sheet/models/budget_line.dart';
import 'package:balance_sheet/models/budget_month.dart';
import 'package:balance_sheet/models/contact.dart';
import 'package:balance_sheet/models/transaction.dart' as txn_model;
import 'package:balance_sheet/saved_views/saved_views_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

class BackupException implements Exception {
  BackupException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Progress event emitted during backup import.
///
/// [message] is a short human-readable label for the current phase (e.g.
/// "Restoring transactions"). [value] is determinate progress in `[0, 1]`
/// when known and `null` for indeterminate work (parsing, refreshing
/// controllers, etc.).
@immutable
class BackupImportProgress {
  const BackupImportProgress({required this.message, this.value});

  final String message;
  final double? value;

  @override
  String toString() => 'BackupImportProgress(message: $message, value: $value)';
}

typedef BackupImportProgressCallback = void Function(
    BackupImportProgress progress);

/// Emit progress every N row inserts during the DB transaction. Picked to keep
/// the dialog updating smoothly without paying excessive yield overhead on
/// large backups (tens of thousands of rows).
const int _kImportProgressChunk = 50;

/// JSON export/import for SQLite + [GetStorage] (option A backup).
class BackupService {
  BackupService._();

  static Future<String> exportJsonString() async {
    final Database dbClient = await AppDb().db;
    final List<Map<String, dynamic>> contactRows =
        await dbClient.query(DBConstants.CONTACT, orderBy: 'id ASC');
    final List<Map<String, dynamic>> txnRows =
        await dbClient.query(DBConstants.TRANSACTION, orderBy: 'date DESC');
    final List<Map<String, dynamic>> budgetMonthRows =
        await dbClient.query(DBConstants.BUDGET_MONTH, orderBy: 'id ASC');
    final List<Map<String, dynamic>> budgetLineRows =
        await dbClient.query(DBConstants.BUDGET_LINE, orderBy: 'id ASC');
    final List<Map<String, Object?>> investmentHoldingRows =
        await inv_db.queryAllInvestmentHoldingRows();
    final List<Map<String, Object?>> investmentLotRows =
        await inv_db.queryAllInvestmentLotRows();
    final List<Map<String, Object?>> investmentPriceRows =
        await inv_db.queryAllInvestmentPriceRows();
    final List<Map<String, Object?>> investmentOtherAssetRows =
        await inv_db.queryAllOtherInvestmentRows();

    final GetStorage box = GetStorage();
    // Security state (PIN hash/salt, biometric flag, legacy PIN key) is intentionally excluded:
    // PIN and fingerprint are device-local and can only be configured through the app's
    // Settings flow. Backups carry data + display preferences, never auth material.
    final Map<String, dynamic> preferences = <String, dynamic>{
      AppConstants.APP_FONT_KEY: box.read(AppConstants.APP_FONT_KEY),
      AppConstants.APP_THEME_MODE_KEY:
          box.read(AppConstants.APP_THEME_MODE_KEY),
      AppConstants.CURRENCY_LCY_KEY: box.read(AppConstants.CURRENCY_LCY_KEY),
      AppConstants.CURRENCY_FCY_KEY: box.read(AppConstants.CURRENCY_FCY_KEY),
      AppConstants.CURRENCY_RATE_KEY: box.read(AppConstants.CURRENCY_RATE_KEY),
    };

    final Object? savedViewsRoot = box.read(SavedViewsStorage.rootKey);

    final Map<String, Object?> payload = <String, Object?>{
      'format': BackupConstants.formatId,
      'version': BackupConstants.formatVersion,
      'dbSchemaVersion': DBConstants.DB_VERSION,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'contacts': contactRows
          .map((Map<String, dynamic> r) => Contact.fromJson(r).toJson())
          .toList(),
      'transactions': txnRows
          .map((Map<String, dynamic> r) =>
              txn_model.Transaction.fromJson(r).toJson())
          .toList(),
      'budgetMonths': budgetMonthRows
          .map((Map<String, dynamic> r) => BudgetMonth.fromJson(r).toJson())
          .toList(),
      'budgetLines': budgetLineRows
          .map((Map<String, dynamic> r) => BudgetLine.fromJson(r).toJson())
          .toList(),
      'investmentHoldings': investmentHoldingRows,
      'investmentLots': investmentLotRows,
      'investmentPrices': investmentPriceRows,
      'investmentOtherAssets': investmentOtherAssetRows,
      'preferences': preferences,
      'savedViews': savedViewsRoot,
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Opens the system save dialog so the user picks where to store the JSON file.
  /// Returns the saved path, or `null` if the user cancelled.
  static Future<String?> exportBackup() async {
    final String json = await exportJsonString();
    final String name =
        'balanced_backup_${DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now())}.json';
    return FilePicker.saveFile(
      dialogTitle: 'Save backup',
      fileName: name,
      type: FileType.custom,
      allowedExtensions: <String>['json'],
      bytes: Uint8List.fromList(utf8.encode(json)),
    );
  }

  /// Replaces all local transactions, contacts, and known preferences.
  /// Security state (PIN hash/salt, biometric flag) is intentionally NOT touched.
  /// Call [refreshControllersAfterImport] afterward to refresh in-memory controllers.
  ///
  /// When [onProgress] is supplied the service emits a sequence of
  /// [BackupImportProgress] events: an indeterminate "validating" tick, a
  /// stream of determinate "restoring …" ticks while rows are inserted in the
  /// SQLite transaction, and a closing "preferences" tick. Long-running
  /// imports yield to the event loop between chunks so the UI can repaint.
  static Future<void> importFromJsonString(
    String raw, {
    BackupImportProgressCallback? onProgress,
  }) async {
    void emit(String message, {double? value}) {
      onProgress?.call(BackupImportProgress(message: message, value: value));
    }

    emit('Validating backup…');

    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw BackupException('This file is not a valid JSON backup.');
    }
    final Map<String, dynamic> map = Map<String, dynamic>.from(decoded);

    if (map['format'] != BackupConstants.formatId) {
      throw BackupException('Not a Balanced backup file.');
    }
    final int? v = map['version'] is int
        ? map['version'] as int
        : int.tryParse('${map['version']}');
    if (v == null || v != BackupConstants.formatVersion) {
      throw BackupException(
          'This backup version is not supported. Update the app and try again.');
    }

    final int? schemaV = map['dbSchemaVersion'] is int
        ? map['dbSchemaVersion'] as int
        : int.tryParse('${map['dbSchemaVersion']}');
    if (schemaV != null && schemaV > DBConstants.DB_VERSION) {
      throw BackupException('This backup needs a newer app version.');
    }

    final List<dynamic>? contactList = map['contacts'] as List<dynamic>?;
    final List<dynamic>? txnList = map['transactions'] as List<dynamic>?;
    if (contactList == null || txnList == null) {
      throw BackupException('Backup is missing contacts or transactions.');
    }

    final List<Contact> contacts = contactList
        .map((dynamic e) => Contact.fromJson(
            Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
        .toList();
    final List<txn_model.Transaction> transactions = txnList
        .map((dynamic e) => txn_model.Transaction.fromJson(
            Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
        .toList();

    final List<BudgetMonth> budgetMonths = <BudgetMonth>[];
    final List<BudgetLine> budgetLines = <BudgetLine>[];
    final List<dynamic>? bmList = map['budgetMonths'] as List<dynamic>?;
    final List<dynamic>? blList = map['budgetLines'] as List<dynamic>?;
    if (bmList != null) {
      for (final dynamic e in bmList) {
        budgetMonths.add(BudgetMonth.fromJson(
            Map<String, dynamic>.from(e as Map<dynamic, dynamic>)));
      }
    }
    if (blList != null) {
      for (final dynamic e in blList) {
        budgetLines.add(BudgetLine.fromJson(
            Map<String, dynamic>.from(e as Map<dynamic, dynamic>)));
      }
    }

    final Set<int> contactIds = contacts.map((Contact c) => c.id).toSet();
    for (final txn_model.Transaction t in transactions) {
      final int cid = t.contactId;
      if (cid > 0 && !contactIds.contains(cid)) {
        throw BackupException(
          'Backup is inconsistent: a transaction references a missing contact (id $cid).',
        );
      }
    }

    final Set<int> budgetMonthIds =
        budgetMonths.map((BudgetMonth b) => b.id).toSet();
    for (final BudgetLine bl in budgetLines) {
      if (!budgetMonthIds.contains(bl.budgetMonthId)) {
        throw BackupException(
          'Backup is inconsistent: a budget line references a missing budget month (id ${bl.budgetMonthId}).',
        );
      }
      if (bl.contactId > 0 && !contactIds.contains(bl.contactId)) {
        throw BackupException(
          'Backup is inconsistent: a budget line references a missing contact (id ${bl.contactId}).',
        );
      }
    }

    final List<Map<String, dynamic>> investmentHoldings =
        <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> investmentLots = <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> investmentPrices =
        <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> investmentOtherAssets =
        <Map<String, dynamic>>[];
    Map<String, dynamic>? investmentCashLegacy;
    final List<dynamic>? ih = map['investmentHoldings'] as List<dynamic>?;
    final List<dynamic>? il = map['investmentLots'] as List<dynamic>?;
    final List<dynamic>? ip = map['investmentPrices'] as List<dynamic>?;
    if (ih != null) {
      for (final dynamic e in ih) {
        investmentHoldings
            .add(Map<String, dynamic>.from(e as Map<dynamic, dynamic>));
      }
    }
    if (il != null) {
      for (final dynamic e in il) {
        investmentLots
            .add(Map<String, dynamic>.from(e as Map<dynamic, dynamic>));
      }
    }
    if (ip != null) {
      for (final dynamic e in ip) {
        investmentPrices
            .add(Map<String, dynamic>.from(e as Map<dynamic, dynamic>));
      }
    }
    final List<dynamic>? io = map['investmentOtherAssets'] as List<dynamic>?;
    if (io != null) {
      for (final dynamic e in io) {
        investmentOtherAssets
            .add(Map<String, dynamic>.from(e as Map<dynamic, dynamic>));
      }
    }
    final Object? ic = map['investmentCash'];
    if (ic is Map) {
      investmentCashLegacy = Map<String, dynamic>.from(ic);
    }
    if (investmentOtherAssets.isEmpty && investmentCashLegacy != null) {
      final int bal = investmentCashLegacy['balance_minor'] is int
          ? investmentCashLegacy['balance_minor'] as int
          : int.tryParse('${investmentCashLegacy['balance_minor']}') ?? 0;
      final String ec =
          '${investmentCashLegacy['balance_entry_currency'] ?? 'lcy'}'
              .toLowerCase();
      int ent = investmentCashLegacy['balance_entry_minor'] is int
          ? investmentCashLegacy['balance_entry_minor'] as int
          : int.tryParse('${investmentCashLegacy['balance_entry_minor']}') ?? 0;
      if (ent == 0 && bal != 0) {
        ent = bal;
      }
      final int um = investmentCashLegacy['updated_at_ms'] is int
          ? investmentCashLegacy['updated_at_ms'] as int
          : int.tryParse('${investmentCashLegacy['updated_at_ms']}') ??
              DateTime.now().millisecondsSinceEpoch;
      if (bal != 0 || ent != 0) {
        investmentOtherAssets.add(<String, dynamic>{
          'label': 'Cash',
          'value_lcy_minor': bal,
          'entry_currency': ec == 'fcy' ? 'fcy' : 'lcy',
          'entry_minor': ent,
          'sort_order': 0,
          'updated_at_ms': um,
        });
      }
    }

    final Set<int> investmentHoldingIds =
        investmentHoldings.map((Map<String, dynamic> r) {
      final Object? id = r['id'];
      if (id is int) return id;
      if (id is num) return id.toInt();
      return int.tryParse('$id') ?? 0;
    }).toSet();

    for (final Map<String, dynamic> row in investmentLots) {
      final Object? hid = row['holding_id'];
      final int h = hid is int
          ? hid
          : (hid is num ? hid.toInt() : int.tryParse('$hid') ?? 0);
      if (h > 0 && !investmentHoldingIds.contains(h)) {
        throw BackupException(
          'Backup is inconsistent: an investment lot references a missing holding (id $h).',
        );
      }
    }
    for (final Map<String, dynamic> row in investmentPrices) {
      final Object? hid = row['holding_id'];
      final int h = hid is int
          ? hid
          : (hid is num ? hid.toInt() : int.tryParse('$hid') ?? 0);
      if (h > 0 && !investmentHoldingIds.contains(h)) {
        throw BackupException(
          'Backup is inconsistent: an investment price references a missing holding (id $h).',
        );
      }
    }

    final int totalRows = contacts.length +
        transactions.length +
        budgetMonths.length +
        budgetLines.length +
        investmentOtherAssets.length +
        investmentHoldings.length +
        investmentLots.length +
        investmentPrices.length;
    int inserted = 0;

    // Snapshots progress against the global insert total so the dialog's
    // single progress bar advances monotonically across every section.
    Future<void> tickProgress(String message, {bool force = false}) async {
      if (onProgress == null) return;
      if (!force && inserted % _kImportProgressChunk != 0) return;
      final double v = totalRows == 0 ? 1.0 : inserted / totalRows;
      onProgress(BackupImportProgress(message: message, value: v));
      // Yield so the engine has a chance to repaint between chunks. The
      // sqflite transaction lock is not released by yielding to the event
      // loop, so consistency is unaffected.
      await Future<void>.delayed(Duration.zero);
    }

    emit('Restoring data…', value: totalRows == 0 ? 1.0 : 0.0);

    final Database dbClient = await AppDb().db;
    await dbClient.transaction((Transaction sqlTxn) async {
      await sqlTxn.delete(DBConstants.INVESTMENT_LOT);
      await sqlTxn.delete(DBConstants.INVESTMENT_PRICE);
      await sqlTxn.delete(DBConstants.INVESTMENT_HOLDING);
      await sqlTxn.delete(DBConstants.INVESTMENT_OTHER_ASSET);
      await sqlTxn.delete(DBConstants.TRANSACTION);
      await sqlTxn.delete(DBConstants.BUDGET_LINE);
      await sqlTxn.delete(DBConstants.BUDGET_MONTH);
      await sqlTxn.delete(DBConstants.CONTACT);

      for (final Contact c in contacts) {
        await sqlTxn.insert(
          DBConstants.CONTACT,
          <String, Object?>{'id': c.id, 'name': c.name},
        );
        inserted++;
        await tickProgress('Restoring contacts');
      }
      if (contacts.isNotEmpty) {
        await tickProgress('Restoring contacts', force: true);
      }

      for (final txn_model.Transaction t in transactions) {
        final Map<String, dynamic> row = t.toJson();
        await sqlTxn.insert(DBConstants.TRANSACTION, <String, Object?>{
          'id': row['id'],
          'description': row['description'],
          'type': row['type'],
          'amount': row['amount'],
          'date': row['date'],
          'category': row['category'],
          'contactId': t.contactId == 0 ? null : t.contactId,
          'entryCurrency': row['entryCurrency'] ?? 'lcy',
          'entryAmount': row['entryAmount'] ?? row['amount'],
        });
        inserted++;
        await tickProgress('Restoring transactions');
      }
      if (transactions.isNotEmpty) {
        await tickProgress('Restoring transactions', force: true);
      }

      for (final BudgetMonth b in budgetMonths) {
        await sqlTxn.insert(DBConstants.BUDGET_MONTH, <String, Object?>{
          'id': b.id,
          'year': b.year,
          'month': b.month,
        });
        inserted++;
        await tickProgress('Restoring budgets');
      }
      for (final BudgetLine bl in budgetLines) {
        await sqlTxn.insert(DBConstants.BUDGET_LINE, <String, Object?>{
          'id': bl.id,
          'budget_month_id': bl.budgetMonthId,
          'description': bl.description,
          'planned_amount': bl.plannedAmount,
          'contact_id': bl.contactId <= 0 ? null : bl.contactId,
          'category': bl.categoryKey,
          'sort_order': bl.sortOrder,
          'entryCurrency': bl.planEntryIsFcy ? 'fcy' : 'lcy',
          'entryAmount': bl.planEntryAmountMinor > 0
              ? bl.planEntryAmountMinor
              : bl.plannedAmount,
        });
        inserted++;
        await tickProgress('Restoring budgets');
      }
      if (budgetMonths.isNotEmpty || budgetLines.isNotEmpty) {
        await tickProgress('Restoring budgets', force: true);
      }

      for (final Map<String, dynamic> r in investmentOtherAssets) {
        final int lcy = r['value_lcy_minor'] is int
            ? r['value_lcy_minor'] as int
            : int.tryParse('${r['value_lcy_minor']}') ?? 0;
        final String ec = '${r['entry_currency'] ?? 'lcy'}'.toLowerCase();
        final Object? rawE = r['entry_minor'];
        int ent = rawE is int
            ? rawE
            : (rawE is num ? rawE.toInt() : int.tryParse('$rawE') ?? 0);
        if (ent == 0 && lcy != 0) {
          ent = lcy;
        }
        final Map<String, Object?> row = <String, Object?>{
          'label': '${r['label'] ?? ''}'.trim().isEmpty
              ? 'Investment'
              : '${r['label']}'.trim(),
          'value_lcy_minor': lcy,
          'entry_currency': ec == 'fcy' ? 'fcy' : 'lcy',
          'entry_minor': ent,
          'sort_order': r['sort_order'] is int
              ? r['sort_order'] as int
              : int.tryParse('${r['sort_order']}') ?? 0,
          'updated_at_ms': r['updated_at_ms'] is int
              ? r['updated_at_ms'] as int
              : int.tryParse('${r['updated_at_ms']}') ??
                  DateTime.now().millisecondsSinceEpoch,
        };
        final Object? rid = r['id'];
        if (rid != null) {
          final int id = rid is int
              ? rid
              : (rid is num ? rid.toInt() : int.tryParse('$rid') ?? 0);
          if (id > 0) {
            row['id'] = id;
          }
        }
        await sqlTxn.insert(DBConstants.INVESTMENT_OTHER_ASSET, row);
        inserted++;
        await tickProgress('Restoring investments');
      }

      for (final Map<String, dynamic> r in investmentHoldings) {
        await sqlTxn.insert(DBConstants.INVESTMENT_HOLDING, <String, Object?>{
          'id': r['id'],
          'ticker': r['ticker'],
          'display_name': r['display_name'] ?? '',
          'sort_order': r['sort_order'] ?? 0,
          'created_at_ms': r['created_at_ms'],
        });
        inserted++;
        await tickProgress('Restoring investments');
      }
      for (final Map<String, dynamic> r in investmentLots) {
        final int lcyPs = r['purchase_price_minor_per_share'] is int
            ? r['purchase_price_minor_per_share'] as int
            : int.tryParse('${r['purchase_price_minor_per_share']}') ?? 0;
        final String ec =
            '${r['purchase_entry_currency'] ?? 'lcy'}'.toLowerCase();
        final Object? rawEntry = r['purchase_price_entry_minor'];
        int entryPs = rawEntry is int
            ? rawEntry
            : (rawEntry is num
                ? rawEntry.toInt()
                : int.tryParse('$rawEntry') ?? 0);
        if (entryPs == 0 && lcyPs != 0) {
          entryPs = lcyPs;
        }
        await sqlTxn.insert(DBConstants.INVESTMENT_LOT, <String, Object?>{
          'id': r['id'],
          'holding_id': r['holding_id'],
          'occurred_at_ms': r['occurred_at_ms'],
          'quantity_delta': r['quantity_delta'],
          'purchase_price_minor_per_share': lcyPs,
          'purchase_entry_currency': ec == 'fcy' ? 'fcy' : 'lcy',
          'purchase_price_entry_minor': entryPs,
          'note': r['note'] ?? '',
        });
        inserted++;
        await tickProgress('Restoring investments');
      }
      for (final Map<String, dynamic> r in investmentPrices) {
        final Object? rawDay = r['as_of_day'];
        int asOfDay = rawDay is int
            ? rawDay
            : (rawDay is num ? rawDay.toInt() : int.tryParse('$rawDay') ?? 0);
        final Object? rawMs = r['as_of_ms'];
        int asOfMs = rawMs is int
            ? rawMs
            : (rawMs is num ? rawMs.toInt() : int.tryParse('$rawMs') ?? 0);
        if (asOfDay <= 0 && asOfMs > 0) {
          final DateTime t = DateTime.fromMillisecondsSinceEpoch(asOfMs);
          asOfDay = t.year * 10000 + t.month * 100 + t.day;
        }
        if (asOfMs <= 0 && asOfDay > 0) {
          final int y = asOfDay ~/ 10000;
          final int m = (asOfDay % 10000) ~/ 100;
          final int d = asOfDay % 100;
          asOfMs = DateTime(y, m, d).millisecondsSinceEpoch;
        }
        final int lcyPrice = r['price_minor_per_share'] is int
            ? r['price_minor_per_share'] as int
            : int.tryParse('${r['price_minor_per_share']}') ?? 0;
        final String pEc = '${r['entry_currency'] ?? 'lcy'}'.toLowerCase();
        final Object? rawPe = r['price_entry_minor'];
        int entryPrice = rawPe is int
            ? rawPe
            : (rawPe is num ? rawPe.toInt() : int.tryParse('$rawPe') ?? 0);
        if (entryPrice == 0 && lcyPrice != 0) {
          entryPrice = lcyPrice;
        }
        await sqlTxn.insert(DBConstants.INVESTMENT_PRICE, <String, Object?>{
          'id': r['id'],
          'holding_id': r['holding_id'],
          'as_of_ms': asOfMs,
          'as_of_day': asOfDay,
          'price_minor_per_share': lcyPrice,
          'entry_currency': pEc == 'fcy' ? 'fcy' : 'lcy',
          'price_entry_minor': entryPrice,
        });
        inserted++;
        await tickProgress('Restoring investments');
      }
      if (investmentOtherAssets.isNotEmpty ||
          investmentHoldings.isNotEmpty ||
          investmentLots.isNotEmpty ||
          investmentPrices.isNotEmpty) {
        await tickProgress('Restoring investments', force: true);
      }
    });

    emit('Restoring preferences…');

    final GetStorage box = GetStorage();

    final Object? prefsRaw = map['preferences'];
    if (prefsRaw is Map) {
      final Map<String, dynamic> prefs = Map<String, dynamic>.from(prefsRaw);

      // Only overwrite a stored preference when the backup carries a non-null value for it.
      // A missing or null entry leaves the local setting untouched — a partial / empty
      // preferences block must not wipe an active theme, font, or currency choice.
      //
      // Security keys (PIN hash, PIN salt, legacy PIN, biometric flag) are deliberately NOT
      // restored from backups. PIN and fingerprint are device-local and can only be set or
      // changed through the app's Settings flow; importing a backup never alters them.
      void writeIfPresent(String key) {
        if (!prefs.containsKey(key)) return;
        final Object? value = prefs[key];
        if (value == null) return;
        box.write(key, value);
      }

      writeIfPresent(AppConstants.APP_FONT_KEY);
      writeIfPresent(AppConstants.APP_THEME_MODE_KEY);
      writeIfPresent(AppConstants.CURRENCY_LCY_KEY);
      writeIfPresent(AppConstants.CURRENCY_FCY_KEY);
      writeIfPresent(AppConstants.CURRENCY_RATE_KEY);
    }

    final Object? savedViewsRaw = map['savedViews'];
    if (savedViewsRaw != null && savedViewsRaw is Map) {
      box.write(
        SavedViewsStorage.rootKey,
        Map<String, dynamic>.from(
          savedViewsRaw
              .map((Object? k, Object? v) => MapEntry(k.toString(), v)),
        ),
      );
    } else {
      await box.remove(SavedViewsStorage.rootKey);
    }
  }

  /// Refreshes in-memory state from SQLite + [GetStorage] after a backup import or debug clear.
  ///
  /// Imports never change security state (PIN hash/salt + biometric flag stay device-local and
  /// are only mutated through the app's Settings flow), so this method does not relock the
  /// session — the existing unlock remains valid for the freshly restored data.
  ///
  /// When [onProgress] is supplied the service emits an indeterminate
  /// [BackupImportProgress] event before each controller refresh so the UI
  /// can keep the spinner alive between import-completed and screens being
  /// fully repopulated.
  static Future<void> refreshControllersAfterImport({
    BackupImportProgressCallback? onProgress,
  }) async {
    void emit(String message) {
      onProgress?.call(BackupImportProgress(message: message));
    }

    // Avoid mass GetX / DB-driven rebuilds during an in-flight frame (e.g. debug clear spinner),
    // which can trigger framework assertions around the element tree.
    await SchedulerBinding.instance.endOfFrame;

    emit('Refreshing app data…');
    final AppController app = Get.find<AppController>();
    app.syncFromStorage();

    if (Get.isRegistered<CurrencyController>()) {
      Get.find<CurrencyController>().syncFromStorage();
    }

    final SecurityController security = Get.find<SecurityController>();
    security.reloadFromStorage();

    emit('Refreshing transactions…');
    final TransactionController tx = Get.find<TransactionController>();
    await tx.loadHomeScreenData();
    tx.resetFieldValues();

    emit('Refreshing contacts…');
    final ContactController contacts = Get.find<ContactController>();
    await contacts.getContacts();
    contacts.resetNewContactDraft();

    if (Get.isRegistered<ReportController>()) {
      emit('Refreshing reports…');
      final ReportController report = Get.find<ReportController>();
      await report.getTransactions();
      await report.getTransactionTotal();
    }

    if (Get.isRegistered<InvestmentController>()) {
      emit('Refreshing investments…');
      final InvestmentController investments = Get.find<InvestmentController>();
      await investments.reload();
    }
  }
}
