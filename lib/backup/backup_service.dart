import 'dart:convert';
import 'dart:typed_data';

import 'package:balance_sheet/constants/app.dart';
import 'package:balance_sheet/constants/backup_constants.dart';
import 'package:balance_sheet/constants/db.dart';
import 'package:balance_sheet/controllers/appController.dart';
import 'package:balance_sheet/controllers/contactController.dart';
import 'package:balance_sheet/controllers/reportController.dart';
import 'package:balance_sheet/controllers/securityController.dart';
import 'package:balance_sheet/controllers/transactionController.dart';
import 'package:balance_sheet/database/db.dart';
import 'package:balance_sheet/models/contact.dart';
import 'package:balance_sheet/models/transaction.dart' as txn_model;
import 'package:file_picker/file_picker.dart';
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

/// JSON export/import for SQLite + [GetStorage] (option A backup).
class BackupService {
  BackupService._();

  static Future<String> exportJsonString() async {
    final Database dbClient = await AppDb().db;
    final List<Map<String, dynamic>> contactRows =
        await dbClient.query(DBConstants.CONTACT, orderBy: 'id ASC');
    final List<Map<String, dynamic>> txnRows =
        await dbClient.query(DBConstants.TRANSACTION, orderBy: 'date DESC');

    final GetStorage box = GetStorage();
    final Map<String, dynamic> preferences = <String, dynamic>{
      AppConstants.APP_FONT_KEY: box.read(AppConstants.APP_FONT_KEY),
      AppConstants.APP_THEME_MODE_KEY: box.read(AppConstants.APP_THEME_MODE_KEY),
      AppConstants.USE_FINGERPRINT: box.read(AppConstants.USE_FINGERPRINT) ?? false,
      AppConstants.USER_PIN_KEY: box.read(AppConstants.USER_PIN_KEY) ?? '',
    };

    final Map<String, Object?> payload = <String, Object?>{
      'format': BackupConstants.formatId,
      'version': BackupConstants.formatVersion,
      'dbSchemaVersion': DBConstants.DB_VERSION,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'contacts': contactRows.map((Map<String, dynamic> r) => Contact.fromJson(r).toJson()).toList(),
      'transactions': txnRows.map((Map<String, dynamic> r) => txn_model.Transaction.fromJson(r).toJson()).toList(),
      'preferences': preferences,
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

  /// Replaces all local transactions, contacts, and known preferences. Call [refreshControllersAfterImport] after.
  static Future<void> importFromJsonString(String raw) async {
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw BackupException('This file is not a valid JSON backup.');
    }
    final Map<String, dynamic> map = Map<String, dynamic>.from(decoded);

    if (map['format'] != BackupConstants.formatId) {
      throw BackupException('Not a Balanced backup file.');
    }
    final int? v = map['version'] is int ? map['version'] as int : int.tryParse('${map['version']}');
    if (v == null || v != BackupConstants.formatVersion) {
      throw BackupException('This backup version is not supported. Update the app and try again.');
    }

    final int? schemaV =
        map['dbSchemaVersion'] is int ? map['dbSchemaVersion'] as int : int.tryParse('${map['dbSchemaVersion']}');
    if (schemaV != null && schemaV > DBConstants.DB_VERSION) {
      throw BackupException('This backup needs a newer app version.');
    }

    final List<dynamic>? contactList = map['contacts'] as List<dynamic>?;
    final List<dynamic>? txnList = map['transactions'] as List<dynamic>?;
    if (contactList == null || txnList == null) {
      throw BackupException('Backup is missing contacts or transactions.');
    }

    final List<Contact> contacts = contactList
        .map((dynamic e) => Contact.fromJson(Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
        .toList();
    final List<txn_model.Transaction> transactions = txnList
        .map((dynamic e) => txn_model.Transaction.fromJson(Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
        .toList();

    final Set<int> contactIds = contacts.map((Contact c) => c.id).toSet();
    for (final txn_model.Transaction t in transactions) {
      final int cid = t.contactId;
      if (cid > 0 && !contactIds.contains(cid)) {
        throw BackupException(
          'Backup is inconsistent: a transaction references a missing contact (id $cid).',
        );
      }
    }

    final Database dbClient = await AppDb().db;
    await dbClient.transaction((Transaction sqlTxn) async {
      await sqlTxn.delete(DBConstants.TRANSACTION);
      await sqlTxn.delete(DBConstants.CONTACT);

      for (final Contact c in contacts) {
        await sqlTxn.insert(
          DBConstants.CONTACT,
          <String, Object?>{'id': c.id, 'name': c.name},
        );
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
        });
      }
    });

    final Object? prefsRaw = map['preferences'];
    if (prefsRaw is Map) {
      final Map<String, dynamic> prefs = Map<String, dynamic>.from(prefsRaw);
      final GetStorage box = GetStorage();
      Future<void> writeKey(String key, Object? value) async {
        if (value == null) {
          await box.remove(key);
        } else {
          box.write(key, value);
        }
      }

      await writeKey(AppConstants.APP_FONT_KEY, prefs[AppConstants.APP_FONT_KEY]);
      await writeKey(AppConstants.APP_THEME_MODE_KEY, prefs[AppConstants.APP_THEME_MODE_KEY]);
      await writeKey(AppConstants.USE_FINGERPRINT, prefs[AppConstants.USE_FINGERPRINT] ?? false);

      final Object? pin = prefs[AppConstants.USER_PIN_KEY];
      if (pin == null || pin == '') {
        await box.remove(AppConstants.USER_PIN_KEY);
      } else {
        box.write(AppConstants.USER_PIN_KEY, pin);
      }
    }
  }

  static Future<void> refreshControllersAfterImport() async {
    final AppController app = Get.find<AppController>();
    app.syncFromStorage();

    final SecurityController security = Get.find<SecurityController>();
    security.reloadFromStorage();

    final TransactionController tx = Get.find<TransactionController>();
    await tx.loadHomeScreenData();

    final ContactController contacts = Get.find<ContactController>();
    await contacts.getContacts();

    if (Get.isRegistered<ReportController>()) {
      final ReportController report = Get.find<ReportController>();
      await report.getTransactions();
      await report.getTransactionTotal();
    }
  }
}
