import 'package:balance_sheet/constants/db.dart';
import 'package:balance_sheet/database/db.dart';
import 'package:balance_sheet/database/investment_operations.dart' as inv_ops;
import 'package:balance_sheet/models/other_asset_line_item.dart';
import 'package:balance_sheet/models/other_investment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../helpers/database_test_setup.dart';

void main() {
  setUpAll(() {
    initializeSqfliteFfiForTests();
  });

  setUp(() async {
    await resetAppDatabaseFile();
  });

  group('Other asset line items', () {
    test('insert line item recomputes parent value', () async {
      final int assetId = await inv_ops.insertOtherInvestment(
        label: 'Wallet',
        entryCurrency: 'lcy',
      );

      await inv_ops.insertOtherAssetLineItem(
        assetId: assetId,
        description: 'Initial funding',
        amountMinor: 12000,
        entryCurrency: 'lcy',
        entryAmountMinor: 12000,
        occurredAtMs: DateTime(2026, 1, 1).millisecondsSinceEpoch,
      );

      final OtherInvestment row = (await inv_ops.listOtherInvestments())
          .singleWhere((e) => e.id == assetId);
      expect(row.valueLcyMinor, 12000);
      expect(row.entryMinor, 12000);
    });

    test('multiple inflow and outflow items net correctly', () async {
      final int assetId = await inv_ops.insertOtherInvestment(
        label: 'Broker cash',
        entryCurrency: 'fcy',
      );

      await inv_ops.insertOtherAssetLineItem(
        assetId: assetId,
        description: 'Deposit',
        amountMinor: 20000,
        entryCurrency: 'fcy',
        entryAmountMinor: 1000,
        occurredAtMs: DateTime(2026, 1, 2).millisecondsSinceEpoch,
      );
      await inv_ops.insertOtherAssetLineItem(
        assetId: assetId,
        description: 'Fee',
        amountMinor: -3500,
        entryCurrency: 'fcy',
        entryAmountMinor: -175,
        occurredAtMs: DateTime(2026, 1, 3).millisecondsSinceEpoch,
      );

      final OtherInvestment row = (await inv_ops.listOtherInvestments())
          .singleWhere((e) => e.id == assetId);
      expect(row.valueLcyMinor, 16500);
      expect(row.entryMinor, 825);
    });

    test('update and delete line item recompute parent', () async {
      final int assetId = await inv_ops.insertOtherInvestment(
        label: 'Cash',
        entryCurrency: 'lcy',
      );

      final int itemId = await inv_ops.insertOtherAssetLineItem(
        assetId: assetId,
        description: 'Opening',
        amountMinor: 9000,
        entryCurrency: 'lcy',
        entryAmountMinor: 9000,
        occurredAtMs: DateTime(2026, 1, 4).millisecondsSinceEpoch,
      );

      await inv_ops.updateOtherAssetLineItem(
        OtherAssetLineItem(
          id: itemId,
          assetId: assetId,
          description: 'Opening adjusted',
          amountMinor: 7000,
          entryCurrency: 'lcy',
          entryAmountMinor: 7000,
          occurredAtMs: DateTime(2026, 1, 4).millisecondsSinceEpoch,
          createdAtMs: DateTime(2026, 1, 4).millisecondsSinceEpoch,
        ),
      );

      OtherInvestment row = (await inv_ops.listOtherInvestments())
          .singleWhere((e) => e.id == assetId);
      expect(row.valueLcyMinor, 7000);

      await inv_ops.deleteOtherAssetLineItem(itemId, assetId);
      row = (await inv_ops.listOtherInvestments())
          .singleWhere((e) => e.id == assetId);
      expect(row.valueLcyMinor, 0);
      expect(row.entryMinor, 0);
    });

    test('deleting parent cascades line items', () async {
      final int assetId = await inv_ops.insertOtherInvestment(
        label: 'Land',
        entryCurrency: 'lcy',
      );

      await inv_ops.insertOtherAssetLineItem(
        assetId: assetId,
        description: 'Purchase',
        amountMinor: 500000,
        entryCurrency: 'lcy',
        entryAmountMinor: 500000,
        occurredAtMs: DateTime(2026, 1, 5).millisecondsSinceEpoch,
      );
      expect(await inv_ops.listOtherAssetLineItems(assetId), isNotEmpty);

      await inv_ops.deleteOtherInvestment(assetId);
      expect(await inv_ops.listOtherAssetLineItems(assetId), isEmpty);
    });

    test('v5 migration seeds opening balance line item for legacy rows',
        () async {
      await AppDb().closeForTesting();
      final String path = p.join(await getDatabasesPath(), DBConstants.DB_NAME);

      final Database legacyDb = await openDatabase(
        path,
        version: 4,
        onConfigure: (Database db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (Database db, int version) async {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS ${DBConstants.INVESTMENT_OTHER_ASSET}(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              label TEXT NOT NULL,
              value_lcy_minor INTEGER NOT NULL DEFAULT 0,
              entry_currency TEXT NOT NULL DEFAULT 'lcy',
              entry_minor INTEGER NOT NULL DEFAULT 0,
              sort_order INTEGER NOT NULL DEFAULT 0,
              updated_at_ms INTEGER NOT NULL
            )
          ''');
        },
      );

      const int updatedAtMs = 1700000000000;
      final int assetId = await legacyDb
          .insert(DBConstants.INVESTMENT_OTHER_ASSET, <String, Object?>{
        'label': 'Legacy cash',
        'value_lcy_minor': 12345,
        'entry_currency': 'fcy',
        'entry_minor': 345,
        'sort_order': 0,
        'updated_at_ms': updatedAtMs,
      });
      await legacyDb.close();

      await AppDb().closeForTesting();
      await AppDb().db;

      final List<OtherAssetLineItem> items =
          await inv_ops.listOtherAssetLineItems(assetId);
      expect(items.length, 1);
      expect(items.single.description, 'Opening balance');
      expect(items.single.amountMinor, 12345);
      expect(items.single.entryCurrency, 'fcy');
      expect(items.single.entryAmountMinor, 345);
      expect(items.single.occurredAtMs, updatedAtMs);
    });
  });
}
