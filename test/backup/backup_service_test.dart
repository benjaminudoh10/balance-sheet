import 'package:balance_sheet/backup/backup_service.dart';
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
        () => BackupService.importFromJsonString('{"format":"other","version":2,"contacts":[],"transactions":[]}'),
        throwsA(predicate((Object e) => e.toString().contains('Balanced backup'))),
      );
    });

    test('throws on unsupported version', () async {
      final String raw = validBackupPayload(version: 999);
      expect(
        () => BackupService.importFromJsonString(raw),
        throwsA(predicate((Object e) => e.toString().contains('version'))),
      );
    });

    test('throws when transaction references missing contact', () async {
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
      expect(
        () => BackupService.importFromJsonString(raw),
        throwsA(predicate((Object e) => e.toString().contains('inconsistent'))),
      );
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

    test('includes saved view presets when present', () async {
      await SavedViewsStorage.add(SavedViewsStorage.featureReport, 'Work trips', <String, dynamic>{
        'type': 'month',
        'categoryKey': 'Category',
        'contactId': 0,
      });
      final String json = await BackupService.exportJsonString();
      expect(json, contains('"savedViews"'));
      expect(json, contains('"Work trips"'));
    });

    test('roundtrip preserves investment holdings, lots, prices, and other assets', () async {
      final int cid = await db_ops.addContact(Contact(name: 'Only'));
      await db_ops.addTransaction(Transaction(
        description: 'seed',
        type: TransactionType.income,
        amount: 100,
        date: DateTime(2026, 1, 1),
        category: 'salary',
        contactId: cid,
      ));
      final int hid = await inv_ops.insertInvestmentHolding(ticker: 'X', displayName: 'Y');
      await inv_ops.insertInvestmentLot(
        holdingId: hid,
        occurredAtMs: 1,
        quantityDelta: 3,
        purchasePriceMinorPerShare: 400,
      );
      await inv_ops.insertInvestmentPricePoint(holdingId: hid, asOfDayYyyymmdd: 19700101, priceMinorPerShare: 500);
      await inv_ops.insertOtherInvestment(
        label: 'Cash',
        valueLcyMinor: 9900,
        entryCurrency: 'lcy',
        entryMinor: 9900,
      );

      final String exported = await BackupService.exportJsonString();
      await resetAppDatabaseFile();
      await BackupService.importFromJsonString(exported);

      final List<InvestmentHolding> holdings = await inv_ops.listInvestmentHoldings();
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
      final List<BudgetLine> lines = await db_ops.getBudgetLinesForMonth(loaded!.id);
      expect(lines.length, 1);
      expect(lines.single.description, 'Supplies');
      expect(lines.single.plannedAmount, 4200);
      expect(lines.single.contactId, cid);
      expect(lines.single.categoryKey, 'misc');
    });

    test('roundtrip preserves saved views', () async {
      await SavedViewsStorage.add(SavedViewsStorage.featureInsights, 'Weekly', <String, dynamic>{
        'period': 'thisWeek',
      });
      final String exported = await BackupService.exportJsonString();
      await resetAppDatabaseFile();
      await GetStorage().erase();
      await BackupService.importFromJsonString(exported);

      final List<SavedViewRecord> rows = SavedViewsStorage.listFor(SavedViewsStorage.featureInsights);
      expect(rows.length, 1);
      expect(rows.single.name, 'Weekly');
      expect(rows.single.payload['period'], 'thisWeek');
    });

    test('legacy backup without savedViews clears stored presets', () async {
      await SavedViewsStorage.add(SavedViewsStorage.featureBudget, 'Jan', <String, dynamic>{
        'year': 2026,
        'month': 1,
      });
      await BackupService.importFromJsonString(validBackupPayload(version: 4));
      expect(SavedViewsStorage.listFor(SavedViewsStorage.featureBudget), isEmpty);
    });
  });
}
