# Plan: Other Investment Line Items (v2)

## Overview

Add the ability for each "Other Investment" entry (e.g., a USD cash wallet) to have a list of manually-entered child items representing individual inflows/outflows. **Line items are authoritative** — their sum determines the parent asset's value. Tapping an Other Investment row opens a detail view showing its line items, similar to how tapping a stock holding opens lots & prices.

---

## Data Model

### New Table: `other_asset_line_items`

| Column | Type | Notes |
|---|---|---|
| `id` | `INTEGER PRIMARY KEY AUTOINCREMENT` | |
| `asset_id` | `INTEGER NOT NULL` | FK → [`investment_other_assets`](file:///Users/ben/Code/mobile-apps/balance_sheet/lib/database/db.dart#L168-L178)(id) `ON DELETE CASCADE` |
| `description` | `TEXT NOT NULL` | e.g. "Freelance payment", "Withdrawal" |
| `amount_minor` | `INTEGER NOT NULL` | Signed: positive = inflow, negative = outflow |
| `entry_currency` | `TEXT NOT NULL DEFAULT 'lcy'` | `'lcy'` or `'fcy'` — which currency the user typed |
| `entry_amount_minor` | `INTEGER NOT NULL DEFAULT 0` | Amount in the entry currency (for display) |
| `occurred_at_ms` | `INTEGER NOT NULL` | Timestamp of the line item |
| `created_at_ms` | `INTEGER NOT NULL` | When the record was created |

> [!IMPORTANT]
> Line items are the **source of truth**. The parent asset's `value_lcy_minor` is recomputed as `SUM(amount_minor)` of its children after every insert, update, or delete. Similarly, the parent's `entry_minor` is recomputed as `SUM(entry_amount_minor)` so the dual-currency display stays consistent.

### New Model: `OtherAssetLineItem`

**File:** `lib/models/other_asset_line_item.dart`

A POJO mirroring the table schema with `toMap()` / `fromMap()` factory, following the same pattern as [`InvestmentLotEntry`](file:///Users/ben/Code/mobile-apps/balance_sheet/lib/models/investment_lot_entry.dart).

---

## Database Changes

### Schema — [`lib/database/db.dart`](file:///Users/ben/Code/mobile-apps/balance_sheet/lib/database/db.dart)

```diff
- static const int DB_VERSION = 4;
+ static const int DB_VERSION = 5;
```

```diff
+ // In lib/constants/db.dart:
+ static const OTHER_ASSET_LINE_ITEM = "other_asset_line_items";
```

Add a new `_sqlCreateOtherAssetLineItems` constant and call it in `onCreate`. Add a migration block:

```dart
if (oldVersion < 5) {
  await db.execute(_sqlCreateOtherAssetLineItems);
  // Seed a legacy line item for every existing other asset
  final List<Map<String, Object?>> existing = await db.query(
    DBConstants.INVESTMENT_OTHER_ASSET,
  );
  final int now = DateTime.now().millisecondsSinceEpoch;
  for (final Map<String, Object?> row in existing) {
    final int id = row['id'] as int;
    final int lcy = row['value_lcy_minor'] as int? ?? 0;
    final String ec = '${row['entry_currency'] ?? 'lcy'}';
    final int entry = row['entry_minor'] as int? ?? lcy;
    if (lcy == 0 && entry == 0) continue; // skip zero-value assets
    await db.insert(DBConstants.OTHER_ASSET_LINE_ITEM, <String, Object?>{
      'asset_id': id,
      'description': 'Opening balance',
      'amount_minor': lcy,
      'entry_currency': ec,
      'entry_amount_minor': entry,
      'occurred_at_ms': row['updated_at_ms'] as int? ?? now,
      'created_at_ms': now,
    });
  }
}
```

> [!NOTE]
> The migration creates an "Opening balance" child entry for every existing other asset, carrying over its current `value_lcy_minor` and `entry_minor`. This ensures no data loss — the parent's value stays identical after the upgrade, and users see the initial entry in the new detail view.

### Recompute Helper — [`lib/database/investment_operations.dart`](file:///Users/ben/Code/mobile-apps/balance_sheet/lib/database/investment_operations.dart)

A new private helper that recalculates the parent from its children:

```dart
/// Recomputes the parent asset's value_lcy_minor and entry_minor
/// from the SUM of its line items. Called after every line item mutation.
Future<void> _recomputeOtherAssetValue(int assetId) async {
  final Database dbClient = await AppDb().db;
  final List<Map<String, Object?>> rows = await dbClient.rawQuery('''
    SELECT
      COALESCE(SUM(amount_minor), 0) AS total_lcy,
      COALESCE(SUM(entry_amount_minor), 0) AS total_entry
    FROM ${DBConstants.OTHER_ASSET_LINE_ITEM}
    WHERE asset_id = ?
  ''', [assetId]);
  final int totalLcy = _asInt(rows.first['total_lcy']);
  final int totalEntry = _asInt(rows.first['total_entry']);
  await dbClient.update(
    DBConstants.INVESTMENT_OTHER_ASSET,
    <String, Object?>{
      'value_lcy_minor': totalLcy,
      'entry_minor': totalEntry,
      'updated_at_ms': DateTime.now().millisecondsSinceEpoch,
    },
    where: 'id = ?',
    whereArgs: <Object>[assetId],
  );
}
```

### Operations — [`lib/database/investment_operations.dart`](file:///Users/ben/Code/mobile-apps/balance_sheet/lib/database/investment_operations.dart)

Add the following functions:

| Function | Purpose |
|---|---|
| `listLineItemsForAsset(int assetId)` | Returns `List<OtherAssetLineItem>` ordered by `occurred_at_ms DESC` |
| `insertOtherAssetLineItem({assetId, description, amountMinor, entryCurrency, entryAmountMinor, occurredAtMs})` | Insert + call `_recomputeOtherAssetValue(assetId)` |
| `updateOtherAssetLineItem(OtherAssetLineItem item)` | Update + recompute |
| `deleteOtherAssetLineItem(int id, int assetId)` | Delete + recompute |
| `queryAllOtherAssetLineItemRows()` | Raw row dump for backup export |

### Changes to existing operations

- **`updateOtherInvestment`**: Remove direct edits to `value_lcy_minor` / `entry_minor` — these are now derived fields. The update method should only allow editing `label` (and `entry_currency` if the user switches the display currency).
- **`insertOtherInvestment`**: Still creates the parent row, but sets `value_lcy_minor = 0` and `entry_minor = 0`. The value comes from subsequently added line items.

---

## Controller Changes — [`lib/controllers/investment_controller.dart`](file:///Users/ben/Code/mobile-apps/balance_sheet/lib/controllers/investment_controller.dart)

Add thin wrappers that call the new DB operations and reload state:

```dart
Future<List<OtherAssetLineItem>> getLineItemsForAsset(int assetId) async { ... }
Future<void> addOtherAssetLineItem({...}) async { ... ; await reload(); }
Future<void> updateOtherAssetLineItem(OtherAssetLineItem item) async { ... ; await reload(); }
Future<void> deleteOtherAssetLineItem(int id, int assetId) async { ... ; await reload(); }
```

---

## UI Changes — [`lib/screens/plan_stocks_screen.dart`](file:///Users/ben/Code/mobile-apps/balance_sheet/lib/screens/plan_stocks_screen.dart)

### 1. Tap on Other Investment Row → Detail Modal

Currently, tapping an [`_OtherInvestmentRow`](file:///Users/ben/Code/mobile-apps/balance_sheet/lib/screens/plan_stocks_screen.dart#L1843-L1955) opens the editor bottom sheet. Change this to open a **detail modal** (full-screen bottom sheet) that shows:

- **Header:** Asset label, current value (dual currency)
- **Action buttons:** Edit label (opens a simplified editor — label only), Add line item
- **Line items list:** Scrollable list of items, each showing:
  - Description
  - Amount (formatted, color-coded: mint for inflows, coral for outflows)
  - Date
  - Swipe-to-delete, swipe-to-edit (following the existing Slidable pattern)

### 2. Simplified Parent Editor

The existing [`_OtherInvestmentEditorContent`](file:///Users/ben/Code/mobile-apps/balance_sheet/lib/screens/plan_stocks_screen.dart#L74-L88) is simplified — it now only edits:
- **Label** (text)
- **Display currency preference** (LCY/FCY toggle)

The amount field is removed from the parent editor since value is now derived from line items.

### 3. Add/Edit Line Item Bottom Sheet

A new `_OtherAssetLineItemEditorContent` StatefulWidget (following the pattern of [`_OtherInvestmentEditorContent`](file:///Users/ben/Code/mobile-apps/balance_sheet/lib/screens/plan_stocks_screen.dart#L74-L88)):

- **Fields:**
  - Description (text)
  - Amount (currency input, using existing input widgets)
  - LCY/FCY toggle
  - Date picker
  - Type toggle or sign: inflow (+) / outflow (−)
- **Validation:** Description required, amount > 0
- **Save:** Calls `addOtherAssetLineItem()` or `updateOtherAssetLineItem()`, which triggers parent value recompute

### 4. Line Item Row Widget

A new `_OtherAssetLineItemRow` widget showing:
- Description text
- Formatted amount with +/− prefix and color coding
- Date subtitle
- Slidable actions (edit / delete)

### 5. FAB Change

The FAB on the "Other investments" tab currently opens the parent editor sheet. It should continue to create a new parent asset (label + display currency only). The user then taps into it to add line items.

---

## Backup & Restore — [`lib/backup/backup_service.dart`](file:///Users/ben/Code/mobile-apps/balance_sheet/lib/backup/backup_service.dart)

### Export

Add `otherAssetLineItems` key to the backup payload (alongside `investmentOtherAssets`):

```dart
'otherAssetLineItems': await inv_db.queryAllOtherAssetLineItemRows(),
```

### Import

- Delete existing `other_asset_line_items` rows (already covered by CASCADE if the parent table is cleared first, but add explicit delete for safety).
- Parse and insert each line item row, mapping `asset_id` to the imported parent's new ID.
- Skip orphaned line items (where `asset_id` references a missing parent) following the same resilience pattern used for [`investment_lot_entries`](file:///Users/ben/Code/mobile-apps/balance_sheet/lib/backup/backup_service.dart#L522-L530).
- After all line items are inserted, recompute every parent asset's value via `_recomputeOtherAssetValue`.

### Backward Compatibility

- **Importing older backups** (without `otherAssetLineItems`): After inserting other asset rows, generate an "Opening balance" seed line item for each asset (same logic as the v5 migration), then recompute.
- **Newer backups imported into older app versions**: The unrecognised `otherAssetLineItems` key is ignored by the JSON parser; the parent's `value_lcy_minor` is already written directly so older versions read it correctly.

---

## Tests — `test/database/`

### New file: `test/database/other_asset_line_items_test.dart`

| Test case | Verifies |
|---|---|
| Insert line item → parent value recomputed | `value_lcy_minor` = sum of children |
| Multiple line items sum correctly | Inflows + outflows net to correct total |
| Delete line item → parent value recomputed | Sum adjusts after deletion |
| Update line item → parent value recomputed | Changed amount reflected in parent |
| Line items cascade-deleted with parent | Delete parent asset → no orphaned line items |
| Migration seeds opening balance | Existing asset gets child with matching value |

### Update: `test/backup/`

- Add line items to the seed data in the backup round-trip test.
- Verify line items survive export → import and parent values are correctly recomputed.
- Verify importing older backups (no `otherAssetLineItems` key) generates seed entries.

---

## Task Order

| # | Task | Files |
|---|---|---|
| 1 | Add `OTHER_ASSET_LINE_ITEM` constant | [`lib/constants/db.dart`](file:///Users/ben/Code/mobile-apps/balance_sheet/lib/constants/db.dart) |
| 2 | Create `OtherAssetLineItem` model | `lib/models/other_asset_line_item.dart` (new) |
| 3 | Add table schema + v5 migration with seed logic | [`lib/database/db.dart`](file:///Users/ben/Code/mobile-apps/balance_sheet/lib/database/db.dart) |
| 4 | Add DB operations + `_recomputeOtherAssetValue` | [`lib/database/investment_operations.dart`](file:///Users/ben/Code/mobile-apps/balance_sheet/lib/database/investment_operations.dart) |
| 5 | Simplify `insertOtherInvestment` / `updateOtherInvestment` | [`lib/database/investment_operations.dart`](file:///Users/ben/Code/mobile-apps/balance_sheet/lib/database/investment_operations.dart) |
| 6 | Add controller methods | [`lib/controllers/investment_controller.dart`](file:///Users/ben/Code/mobile-apps/balance_sheet/lib/controllers/investment_controller.dart) |
| 7 | Build detail view + line item editor UI | [`lib/screens/plan_stocks_screen.dart`](file:///Users/ben/Code/mobile-apps/balance_sheet/lib/screens/plan_stocks_screen.dart) |
| 8 | Simplify parent editor (label only) | [`lib/screens/plan_stocks_screen.dart`](file:///Users/ben/Code/mobile-apps/balance_sheet/lib/screens/plan_stocks_screen.dart) |
| 9 | Update backup export/import + seed logic | [`lib/backup/backup_service.dart`](file:///Users/ben/Code/mobile-apps/balance_sheet/lib/backup/backup_service.dart) |
| 10 | Write DB tests | `test/database/other_asset_line_items_test.dart` (new) |
| 11 | Update backup round-trip tests | `test/backup/` |
| 12 | Run `dart analyze` + `flutter test --concurrency=1` | — |

---

## Design Decisions

> [!NOTE]
> **Line items are authoritative.** The parent's `value_lcy_minor` is always `SUM(amount_minor)` of its children. This ensures the value displayed on the parent row and used for net worth exactly matches the logged activity. Direct editing of the parent's amount is removed.

> [!NOTE]
> **Backward compatibility via seeding.** The v5 migration creates an "Opening balance" child entry for each pre-existing other asset. This preserves existing values while making every asset's history visible in the new detail view. The same seed logic runs during backup import of older files that lack the `otherAssetLineItems` key.

> [!WARNING]
> **Currency mixing.** If a user adds line items in both LCY and FCY under the same parent, the `entry_minor` sum may not be meaningful (summing different currencies). The `value_lcy_minor` sum is always valid since `amount_minor` is canonical LCY. The UI should display the parent value using LCY as the authoritative total, with FCY derived via the exchange rate.
