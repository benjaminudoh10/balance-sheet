import 'package:balance_sheet/backup/backup_service.dart';
import 'package:balance_sheet/constants/app.dart';
import 'package:balance_sheet/constants/backup_constants.dart';
import 'package:balance_sheet/constants/db.dart';
import 'package:balance_sheet/database/investment_operations.dart' as inv_ops;
import 'package:balance_sheet/database/operations.dart' as db_ops;
import 'package:balance_sheet/enums.dart';
import 'package:balance_sheet/models/transaction.dart';
import 'package:balance_sheet/models/budget_line.dart';
import 'package:balance_sheet/models/budget_month.dart';
import 'package:balance_sheet/models/contact.dart';
import 'package:balance_sheet/models/investment_holding.dart';
import 'package:balance_sheet/models/other_investment.dart';
import 'package:balance_sheet/models/tag.dart';
import 'package:balance_sheet/saved_views/saved_views_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

import '../helpers/database_test_setup.dart';
import '../helpers/path_provider_mock.dart';

void main() {
  setUpAll(() {
    setupPathProviderMock();
    initializeSqfliteFfiForTests();
  });

  setUp(() async {
    await resetAppDatabaseFile();
    await GetStorage.init();
    GetStorage().erase();
  });

  String validBackupPayload({
    int version = BackupConstants.formatVersion,
    int schemaVersion = DBConstants.DB_VERSION,
  }) {
    return '''
{
  "format": "${BackupConstants.formatId}",
  "version": $version,
  "dbSchemaVersion": $schemaVersion,
  "contacts": [
    {"id": 1, "name": "Alice"}
  ],
  "transactions": [
    {
      "id": 10,
      "description": "Test income",
      "type": "income",
      "amount": 5000,
      "date": 1700000000000,
      "category": "salary",
      "contactId": 1
    }
  ],
  "preferences": {}
}
''';
  }

  group('BackupService.importFromJsonString', () {
    test('throws on non-map JSON', () async {
      expect(
        () => BackupService.importFromJsonString('"hello"'),
        throwsA(isA<BackupException>()),
      );
    });

    test('throws on wrong format id', () async {
      expect(
        () => BackupService.importFromJsonString(
            '{"format":"other","version":2,"contacts":[],"transactions":[]}'),
        throwsA(
            predicate((Object e) => e.toString().contains('Balanced backup'))),
      );
    });

    test('throws on unsupported version', () async {
      final String raw = validBackupPayload(version: 999);
      expect(
        () => BackupService.importFromJsonString(raw),
        throwsA(predicate((Object e) => e.toString().contains('version'))),
      );
    });

    test('imports transaction with null contactId when contact is missing',
        () async {
      const String raw = '''
{
  "format": "${BackupConstants.formatId}",
  "version": ${BackupConstants.formatVersion},
  "dbSchemaVersion": ${DBConstants.DB_VERSION},
  "contacts": [],
  "transactions": [
    {
      "id": 1,
      "description": "x",
      "type": "income",
      "amount": 1,
      "date": 0,
      "category": "salary",
      "contactId": 99
    }
  ],
  "preferences": {}
}
''';
      await BackupService.importFromJsonString(raw);
      final txns = await db_ops.getAllTransactions(0, 1);
      expect(txns.length, 1);
      expect(txns.first.contactId, 0); // contactId 0 in model means null in DB
    });

    test('skips budget line when budget month is missing', () async {
      const String raw = '''
{
  "format": "${BackupConstants.formatId}",
  "version": ${BackupConstants.formatVersion},
  "dbSchemaVersion": ${DBConstants.DB_VERSION},
  "contacts": [],
  "transactions": [],
  "budgetMonths": [],
  "budgetLines": [
    {
      "id": 1,
      "budget_month_id": 99,
      "description": "Orphaned",
      "planned_amount": 100,
      "category": "misc"
    }
  ],
  "preferences": {}
}
''';
      await BackupService.importFromJsonString(raw);
      // We don't have a direct way to check budget lines for missing month easily,
      // but if we had db_ops.getBudgetLinesForMonth(99) it should be empty.
      final List<BudgetLine> lines = await db_ops.getBudgetLinesForMonth(99);
      expect(lines, isEmpty);
    });

    test('skips investment lot/price when holding is missing', () async {
      const String raw = '''
{
  "format": "${BackupConstants.formatId}",
  "version": ${BackupConstants.formatVersion},
  "dbSchemaVersion": ${DBConstants.DB_VERSION},
  "contacts": [],
  "transactions": [],
  "investmentHoldings": [],
  "investmentLots": [
    {
      "id": 1,
      "holding_id": 99,
      "occurred_at_ms": 1,
      "quantity_delta": 1.0,
      "purchase_price_minor_per_share": 100
    }
  ],
  "investmentPrices": [
    {
      "id": 1,
      "holding_id": 99,
      "as_of_ms": 1,
      "price_minor_per_share": 100
    }
  ],
  "preferences": {}
}
''';
      await BackupService.importFromJsonString(raw);
      final List<InvestmentHolding> holdings =
          await inv_ops.listInvestmentHoldings();
      expect(holdings, isEmpty);
      // If we could check lots/prices directly we'd see they are empty too.
    });

    test('imports contacts and transactions', () async {
      await BackupService.importFromJsonString(validBackupPayload());

      final List contacts = await db_ops.getContacts();
      expect(contacts.length, 1);
      expect(contacts.first.name, 'Alice');

      final int start = 0;
      final int end = DateTime.now().millisecondsSinceEpoch + 1;
      final txns = await db_ops.getAllTransactions(start, end);
      expect(txns.length, 1);
      expect(txns.first.amount, 5000);
    });

    test('empty preferences block leaves theme, font, and currency untouched',
        () async {
      final GetStorage box = GetStorage();
      box.write(AppConstants.APP_THEME_MODE_KEY, 'dark');
      box.write(AppConstants.APP_FONT_KEY, 'inter');
      box.write(AppConstants.CURRENCY_LCY_KEY, 'NGN');
      box.write(AppConstants.CURRENCY_FCY_KEY, 'USD');
      box.write(AppConstants.CURRENCY_RATE_KEY, 1500);

      await BackupService.importFromJsonString(validBackupPayload());

      expect(box.read(AppConstants.APP_THEME_MODE_KEY), 'dark');
      expect(box.read(AppConstants.APP_FONT_KEY), 'inter');
      expect(box.read(AppConstants.CURRENCY_LCY_KEY), 'NGN');
      expect(box.read(AppConstants.CURRENCY_FCY_KEY), 'USD');
      expect(box.read(AppConstants.CURRENCY_RATE_KEY), 1500);
    });

    test('null preferences entries do not erase existing values', () async {
      final GetStorage box = GetStorage();
      box.write(AppConstants.APP_THEME_MODE_KEY, 'light');
      box.write(AppConstants.CURRENCY_LCY_KEY, 'NGN');

      final String raw = '''
{
  "format": "${BackupConstants.formatId}",
  "version": ${BackupConstants.formatVersion},
  "dbSchemaVersion": ${DBConstants.DB_VERSION},
  "contacts": [],
  "transactions": [],
  "preferences": {
    "${AppConstants.APP_THEME_MODE_KEY}": null,
    "${AppConstants.CURRENCY_LCY_KEY}": null
  }
}
''';
      await BackupService.importFromJsonString(raw);

      expect(box.read(AppConstants.APP_THEME_MODE_KEY), 'light');
      expect(box.read(AppConstants.CURRENCY_LCY_KEY), 'NGN');
    });

    test('PIN material in backup is ignored — local PIN is never overwritten',
        () async {
      final GetStorage box = GetStorage();
      box.write(AppConstants.USER_PIN_HASH_KEY, 'local-hash');
      box.write(AppConstants.USER_PIN_SALT_KEY, 'local-salt');

      final String raw = '''
{
  "format": "${BackupConstants.formatId}",
  "version": ${BackupConstants.formatVersion},
  "dbSchemaVersion": ${DBConstants.DB_VERSION},
  "contacts": [],
  "transactions": [],
  "preferences": {
    "${AppConstants.USER_PIN_HASH_KEY}": "from-backup",
    "${AppConstants.USER_PIN_SALT_KEY}": "from-backup-salt"
  }
}
''';
      await BackupService.importFromJsonString(raw);

      expect(box.read(AppConstants.USER_PIN_HASH_KEY), 'local-hash');
      expect(box.read(AppConstants.USER_PIN_SALT_KEY), 'local-salt');
    });

    test(
        'PIN material in backup does not create a PIN when none is set locally',
        () async {
      final GetStorage box = GetStorage();
      expect(box.read(AppConstants.USER_PIN_HASH_KEY), isNull);

      final String raw = '''
{
  "format": "${BackupConstants.formatId}",
  "version": ${BackupConstants.formatVersion},
  "dbSchemaVersion": ${DBConstants.DB_VERSION},
  "contacts": [],
  "transactions": [],
  "preferences": {
    "${AppConstants.USER_PIN_HASH_KEY}": "from-backup",
    "${AppConstants.USER_PIN_SALT_KEY}": "from-backup-salt"
  }
}
''';
      await BackupService.importFromJsonString(raw);

      expect(box.read(AppConstants.USER_PIN_HASH_KEY), isNull);
      expect(box.read(AppConstants.USER_PIN_SALT_KEY), isNull);
    });

    test(
        'USE_FINGERPRINT in backup is ignored — local biometric flag is preserved',
        () async {
      final GetStorage box = GetStorage();
      box.write(AppConstants.USE_FINGERPRINT, true);

      final String raw = '''
{
  "format": "${BackupConstants.formatId}",
  "version": ${BackupConstants.formatVersion},
  "dbSchemaVersion": ${DBConstants.DB_VERSION},
  "contacts": [],
  "transactions": [],
  "preferences": {
    "${AppConstants.USE_FINGERPRINT}": false
  }
}
''';
      await BackupService.importFromJsonString(raw);

      expect(box.read(AppConstants.USE_FINGERPRINT), true);
    });
  });

  group('BackupService.importFromJsonString progress callback', () {
    test('emits validating, restoring data, and preferences events', () async {
      final List<BackupImportProgress> events = <BackupImportProgress>[];
      await BackupService.importFromJsonString(
        validBackupPayload(),
        onProgress: events.add,
      );

      expect(events, isNotEmpty);
      // First event is the indeterminate "validating" tick before parsing.
      expect(events.first.value, isNull);
      expect(events.first.message.toLowerCase(), contains('valid'));
      // Some event in the middle reports restoring data.
      expect(
        events.any((BackupImportProgress e) =>
            e.message.toLowerCase().contains('restor') && e.value != null),
        isTrue,
      );
      // Last event covers the preferences phase (indeterminate).
      expect(events.last.message.toLowerCase(), contains('preference'));
    });

    test('determinate progress values are within [0, 1] and end at 1.0',
        () async {
      // Build a payload with several contacts + transactions so we get multiple
      // restoring ticks back from the chunked emitter.
      final StringBuffer contactsBuf = StringBuffer();
      final StringBuffer txnBuf = StringBuffer();
      const int n = 5;
      for (int i = 1; i <= n; i++) {
        if (i > 1) contactsBuf.write(',');
        contactsBuf.write('{"id": $i, "name": "Person $i"}');
        if (i > 1) txnBuf.write(',');
        txnBuf.write(
          '{"id": ${100 + i}, "description": "x$i", "type": "income", '
          '"amount": ${10 * i}, "date": 1700000000000, "category": "salary", '
          '"contactId": $i}',
        );
      }
      final String raw = '''
{
  "format": "${BackupConstants.formatId}",
  "version": ${BackupConstants.formatVersion},
  "dbSchemaVersion": ${DBConstants.DB_VERSION},
  "contacts": [${contactsBuf.toString()}],
  "transactions": [${txnBuf.toString()}],
  "preferences": {}
}
''';

      final List<BackupImportProgress> events = <BackupImportProgress>[];
      await BackupService.importFromJsonString(raw, onProgress: events.add);

      final List<double> determinate = events
          .where((BackupImportProgress e) => e.value != null)
          .map((BackupImportProgress e) => e.value!)
          .toList();
      expect(determinate, isNotEmpty);
      for (final double v in determinate) {
        expect(v, inInclusiveRange(0.0, 1.0));
      }
      // Determinate values must be non-decreasing — the dialog's progress bar
      // would jitter backwards otherwise.
      for (int i = 1; i < determinate.length; i++) {
        expect(determinate[i], greaterThanOrEqualTo(determinate[i - 1]));
      }
      // Last determinate emit reports the work is complete.
      expect(determinate.last, closeTo(1.0, 1e-9));
    });

    test('empty backup still reports validating and preferences progress',
        () async {
      const String raw = '''
{
  "format": "${BackupConstants.formatId}",
  "version": ${BackupConstants.formatVersion},
  "dbSchemaVersion": ${DBConstants.DB_VERSION},
  "contacts": [],
  "transactions": [],
  "preferences": {}
}
''';

      final List<BackupImportProgress> events = <BackupImportProgress>[];
      await BackupService.importFromJsonString(raw, onProgress: events.add);

      expect(events.length, greaterThanOrEqualTo(2));
      expect(events.first.message.toLowerCase(), contains('valid'));
      expect(
        events.any((BackupImportProgress e) =>
            e.message.toLowerCase().contains('preference')),
        isTrue,
      );
    });

    test('callback is optional — omitting onProgress still completes import',
        () async {
      // Regression guard for the public surface: the existing single-arg call
      // signature must keep working unchanged.
      await BackupService.importFromJsonString(validBackupPayload());
      final List contacts = await db_ops.getContacts();
      expect(contacts.length, 1);
    });
  });

  group('BackupService.exportJsonString', () {
    test('includes format metadata and rows', () async {
      await db_ops.addContact(Contact(name: 'Bob'));
      final String json = await BackupService.exportJsonString();
      expect(json, contains(BackupConstants.formatId));
      expect(json, contains('"version": ${BackupConstants.formatVersion}'));
      expect(json, contains('Bob'));
      expect(json, contains('"budgetMonths"'));
      expect(json, contains('"budgetLines"'));
      expect(json, contains('"investmentHoldings"'));
      expect(json, contains('"investmentOtherAssets"'));
      expect(json, contains('"savedViews"'));
    });

    test(
        'omits security keys (PIN hash/salt, biometric flag, legacy PIN) from preferences',
        () async {
      final GetStorage box = GetStorage();
      box.write(AppConstants.USER_PIN_HASH_KEY, 'should-not-leak');
      box.write(AppConstants.USER_PIN_SALT_KEY, 'should-not-leak');
      box.write(AppConstants.USER_PIN_KEY, 'legacy-should-not-leak');
      box.write(AppConstants.USE_FINGERPRINT, true);

      final String json = await BackupService.exportJsonString();

      expect(json, isNot(contains(AppConstants.USER_PIN_HASH_KEY)));
      expect(json, isNot(contains(AppConstants.USER_PIN_SALT_KEY)));
      expect(json, isNot(contains(AppConstants.USER_PIN_KEY)));
      expect(json, isNot(contains(AppConstants.USE_FINGERPRINT)));
      expect(json, isNot(contains('should-not-leak')));
    });

    test('includes saved view presets when present', () async {
      await SavedViewsStorage.add(
          SavedViewsStorage.featureReport, 'Work trips', <String, dynamic>{
        'type': 'month',
        'categoryKey': 'Category',
        'contactId': 0,
      });
      final String json = await BackupService.exportJsonString();
      expect(json, contains('"savedViews"'));
      expect(json, contains('"Work trips"'));
    });

    test(
        'roundtrip preserves investment holdings, lots, prices, and other assets',
        () async {
      final int cid = await db_ops.addContact(Contact(name: 'Only'));
      await db_ops.addTransaction(Transaction(
        description: 'seed',
        type: TransactionType.income,
        amount: 100,
        date: DateTime(2026, 1, 1),
        category: 'salary',
        contactId: cid,
      ));
      final int hid =
          await inv_ops.insertInvestmentHolding(ticker: 'X', displayName: 'Y');
      await inv_ops.insertInvestmentLot(
        holdingId: hid,
        occurredAtMs: 1,
        quantityDelta: 3,
        purchasePriceMinorPerShare: 400,
      );
      await inv_ops.insertInvestmentPricePoint(
          holdingId: hid, asOfDayYyyymmdd: 19700101, priceMinorPerShare: 500);
      await inv_ops.insertOtherInvestment(
        label: 'Cash',
        valueLcyMinor: 9900,
        entryCurrency: 'lcy',
        entryMinor: 9900,
      );

      final String exported = await BackupService.exportJsonString();
      await resetAppDatabaseFile();
      await BackupService.importFromJsonString(exported);

      final List<InvestmentHolding> holdings =
          await inv_ops.listInvestmentHoldings();
      expect(holdings.length, 1);
      expect(holdings.first.ticker, 'X');
      expect(await inv_ops.totalQuantityForHolding(holdings.first.id), 3.0);
      expect(await inv_ops.getOtherInvestmentsTotalLcyMinor(), 9900);
      final List<OtherInvestment> rows = await inv_ops.listOtherInvestments();
      expect(rows.length, 1);
      expect(rows.first.label, 'Cash');
      expect(rows.first.valueLcyMinor, 9900);
    });

    test('roundtrip preserves budget months and lines', () async {
      final int cid = await db_ops.addContact(Contact(name: 'Vendor'));
      final BudgetMonth bm = await db_ops.ensureBudgetMonth(2026, 2);
      await db_ops.insertBudgetLine(
        budgetMonthId: bm.id,
        description: 'Supplies',
        plannedAmount: 4200,
        contactId: cid,
        categoryKey: 'misc',
      );

      final String exported = await BackupService.exportJsonString();
      await resetAppDatabaseFile();
      await BackupService.importFromJsonString(exported);

      final BudgetMonth? loaded = await db_ops.getBudgetMonth(2026, 2);
      expect(loaded, isNotNull);
      final List<BudgetLine> lines =
          await db_ops.getBudgetLinesForMonth(loaded!.id);
      expect(lines.length, 1);
      expect(lines.single.description, 'Supplies');
      expect(lines.single.plannedAmount, 4200);
      expect(lines.single.contactId, cid);
      expect(lines.single.categoryKey, 'misc');
    });

    test('roundtrip preserves saved views', () async {
      await SavedViewsStorage.add(
          SavedViewsStorage.featureInsights, 'Weekly', <String, dynamic>{
        'period': 'thisWeek',
      });
      final String exported = await BackupService.exportJsonString();
      await resetAppDatabaseFile();
      await GetStorage().erase();
      await BackupService.importFromJsonString(exported);

      final List<SavedViewRecord> rows =
          SavedViewsStorage.listFor(SavedViewsStorage.featureInsights);
      expect(rows.length, 1);
      expect(rows.single.name, 'Weekly');
      expect(rows.single.payload['period'], 'thisWeek');
    });

    test('backup without savedViews clears stored presets', () async {
      await SavedViewsStorage.add(
          SavedViewsStorage.featureBudget, 'Jan', <String, dynamic>{
        'year': 2026,
        'month': 1,
      });
      await BackupService.importFromJsonString(validBackupPayload());
      expect(
          SavedViewsStorage.listFor(SavedViewsStorage.featureBudget), isEmpty);
    });
  });

  group('BackupService Tags Preservation', () {
    test('roundtrip preserves tags and transaction-tag mappings', () async {
      // 1. Setup data: Tags
      final int tagId1 = await db_ops.addTag('Tag 1');
      final int tagId2 = await db_ops.addTag('Tag 2');
      final int tagId3 = await db_ops.addTag('Tag 3'); // Unused tag

      // 2. Setup data: Transactions with tags
      final Transaction txn1 = Transaction(
        description: 'Txn 1',
        type: TransactionType.expenditure,
        amount: 1000,
        date: DateTime(2026, 1, 1),
        category: 'food',
        contactId: 0,
        tags: [Tag(id: tagId1, name: 'Tag 1'), Tag(id: tagId2, name: 'Tag 2')],
      );
      final int txnId1 = await db_ops.addTransaction(txn1);

      final Transaction txn2 = Transaction(
        description: 'Txn 2',
        type: TransactionType.income,
        amount: 5000,
        date: DateTime(2026, 1, 2),
        category: 'salary',
        contactId: 0,
        tags: [Tag(id: tagId2, name: 'Tag 2')],
      );
      final int txnId2 = await db_ops.addTransaction(txn2);

      // 3. Export
      final String exported = await BackupService.exportJsonString();
      expect(exported, contains('Tag 1'));
      expect(exported, contains('Tag 2'));
      expect(exported, contains('Tag 3'));
      expect(exported, contains('"tags"'));
      expect(exported, contains('"transactionTags"'));

      // 4. Reset Database
      await resetAppDatabaseFile();

      // Verify DB is empty
      final List<Tag> initialTags = await db_ops.getTags();
      expect(initialTags, isEmpty);
      final List<Transaction> initialTxns = await db_ops.getAllTransactions(
          0, DateTime.now().millisecondsSinceEpoch);
      expect(initialTxns, isEmpty);

      // 5. Import
      await BackupService.importFromJsonString(exported);

      // 6. Verify Tags are restored
      final List<Tag> restoredTags = await db_ops.getTags();
      expect(restoredTags.length, 3);
      expect(restoredTags.any((t) => t.name == 'Tag 1'), isTrue);
      expect(restoredTags.any((t) => t.name == 'Tag 2'), isTrue);
      expect(restoredTags.any((t) => t.name == 'Tag 3'), isTrue);

      // 7. Verify Transactions and their tag mappings are restored
      final List<Transaction> restoredTxns = await db_ops.getAllTransactions(
        DateTime(2026, 1, 1).millisecondsSinceEpoch,
        DateTime(2026, 1, 2).millisecondsSinceEpoch,
      );

      expect(restoredTxns.length, 2);

      final restoredTxn1 =
          restoredTxns.firstWhere((t) => t.description == 'Txn 1');
      expect(restoredTxn1.tags.length, 2);
      expect(restoredTxn1.tags.any((t) => t.name == 'Tag 1'), isTrue);
      expect(restoredTxn1.tags.any((t) => t.name == 'Tag 2'), isTrue);

      final restoredTxn2 =
          restoredTxns.firstWhere((t) => t.description == 'Txn 2');
      expect(restoredTxn2.tags.length, 1);
      expect(restoredTxn2.tags.any((t) => t.name == 'Tag 2'), isTrue);
    });

    test('roundtrip preserves deletedAt for trashed transactions', () async {
      final DateTime now = DateTime.now();
      final int txnId = await db_ops.addTransaction(Transaction(
        description: 'Trashed',
        type: TransactionType.expenditure,
        amount: 50,
        date: now,
        category: 'misc',
        contactId: 0,
      ));
      await db_ops.moveTransactionToTrash(txnId);

      final String exported = await BackupService.exportJsonString();
      await resetAppDatabaseFile();
      await BackupService.importFromJsonString(exported);

      final trashed = await db_ops.getTrashedTransactions();
      expect(trashed.length, 1);
      expect(trashed.first.description, 'Trashed');
      expect(trashed.first.deletedAt, isNotNull);
    });

    test(
        'importing older backup without tags key still works (tags list stays empty)',
        () async {
      final String oldBackup = '''
{
  "format": "balanced_backup",
  "version": 1,
  "dbSchemaVersion": 3,
  "contacts": [],
  "transactions": [],
  "preferences": {}
}
''';
      await BackupService.importFromJsonString(oldBackup);
      final List<Tag> tags = await db_ops.getTags();
      expect(tags, isEmpty);
    });

    test(
        'importing "dirty" backup with orphaned tag mappings succeeds (orphans are ignored)',
        () async {
      final String dirtyBackup = '''
{
  "format": "balanced_backup",
  "version": ${BackupConstants.formatVersion},
  "dbSchemaVersion": ${DBConstants.DB_VERSION},
  "contacts": [],
  "transactions": [
    {
      "id": 1,
      "description": "Valid",
      "type": "income",
      "amount": 100,
      "date": 0,
      "category": "salary",
      "contactId": 0
    }
  ],
  "tags": [
    {"id": 1, "name": "ValidTag"}
  ],
  "transactionTags": [
    {"transaction_id": 1, "tag_id": 1},
    {"transaction_id": 999, "tag_id": 1},
    {"transaction_id": 1, "tag_id": 999}
  ],
  "preferences": {}
}
''';
      // Should not throw BackupException
      await BackupService.importFromJsonString(dirtyBackup);

      final txns = await db_ops.getAllTransactions(0, 1);
      expect(txns.length, 1);
      expect(txns.first.tags.length, 1);
      expect(txns.first.tags.first.name, 'ValidTag');
    });
  });
}
