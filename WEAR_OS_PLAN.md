# Plan: Wear OS Integration for Balanced

This plan outlines the steps to implement a Wear OS widget (Tile) for the Balanced app, providing users with a quick glance at their financial status (Balance, Investments, and Net Worth) directly from their watch.

## Objective
Implement a native Wear OS Tile that displays:
1. Current Ledger Balance
2. Total Investment Value
3. Net Worth (Balance + Investments)

The design will follow the app's "Midnight Mint" aesthetic.

## Proposed Solution

### 1. Data Flow & Synchronization
Since Flutter UI doesn't run on Wear OS Tiles directly, we will use a "Push" model:
- **Flutter Side:** Whenever financial data changes (transactions added/deleted, investments updated), the app will calculate the totals and push them to the native side via a `MethodChannel`.
- **Native Side:** The values will be stored in `SharedPreferences`. This ensures the Tile can display data instantly without waiting for the Flutter engine to initialize.

### 2. Design System (Midnight Mint)
- **Background:** `#0D1117` (Midnight)
- **Primary Accent (Income/Net Worth):** `#3EE6B5` (Mint)
- **Secondary Accent (Expense/Labels):** `#8B949E` (Grey/Secondary Text)
- **Typography:** Clean, sans-serif (Roboto).

### 3. Key Components

#### A. Flutter Changes
- **`WearService` (new):** A Dart class to manage the `MethodChannel` and trigger syncs.
- **Controller Hooks:** Update `TransactionController` and `InvestmentController` to call `WearService.sync()` after data modifications.

#### B. Android Native Changes
- **`WearStorage` (new):** Kotlin helper to read/write shared preferences.
- **`BalancedTileService` (new):** Extends `TileService` (Jetpack Tiles). Responsible for building the Tile layout.
- **`MainActivity`:** Update to handle the `syncWearData` method call.
- **`AndroidManifest.xml`:** Register the Tile service and required features.

## Implementation Steps

### Phase 1: Android Configuration
1. Add Wear OS dependencies to `android/app/build.gradle.kts`:
   - `androidx.wear.tiles:tiles:1.2.0`
   - `androidx.wear.tiles:tiles-material:1.2.0`
   - `androidx.wear.watchface:watchface-complications-data-source:1.2.1`
2. Add `<uses-feature android:name="android.hardware.type.watch" android:required="false" />` to `AndroidManifest.xml`.
3. Register the `BalancedTileService` in the manifest.

### Phase 2: Native Data Layer
1. Create `WearStorage.kt` to manage `SharedPreferences` (keys: `balance`, `investments`, `net_worth`, `currency`).
2. Update `MainActivity.kt` with a `MethodChannel` handler to receive data and update storage.

### Phase 3: Wear OS Tile UI
1. Implement `BalancedTileService.kt`.
2. Use `LayoutElementBuilders` to create a vertical list layout.
3. Apply the "Midnight Mint" color palette.
4. Add a click action to the Tile to launch the main app.

### Phase 4: Flutter Integration
1. Create `lib/services/wear_service.dart`.
2. Implement `sync()` logic that fetches data from `TransactionController` and `InvestmentController`.
3. Add hooks to `loadHomeScreenData` in `TransactionController`.

## Verification & Testing
1. **Unit Tests:** Verify `WearService` triggers the `MethodChannel` with correct values.
2. **Manual Testing (Instructions):** 
    - Deploy to Wear OS Emulator via ADB.
    - Add a transaction in the app.
    - Swipe to Tiles on the watch and verify the update.
    - Ensure the "Midnight" theme matches the mobile app.

## Migration & Rollback
- No database migrations required.
- The feature is additive and doesn't affect existing app functionality.
- Rollback: Remove the `TileService` from manifest and dependencies.
