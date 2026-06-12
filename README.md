# Balanced

**Balanced** is a Flutter mobile app for recording **income** and **expenses**, seeing your running balance, and reviewing transactions over time. The project package name is `balance_sheet`; the in-app product name is **Balanced**, with the tagline *“…know where your money goes.”*

---

## What the app does

- **Home (main tab)** — Shows total balance, today’s net (income minus expense for the current day), and a **Recent transactions** list. Add entries via **Income** and **Expense** actions; open **All transactions** for the full report view.
- **Contacts** — Manage people or entities you attach to transactions (optional linkage from the transaction form).
- **Settings** — Theme (light / dark / system), font family, app lock (PIN and optional biometrics), and **backup** export/import.
- **Insights** — Period summary (today vs yesterday, this week, this month, last month): total expenses vs the comparison window, category donut + horizontal category bars, weekly income vs expense grouped bars, daily net line chart, and short takeaways. **Activity** remains a placeholder; the shell and bottom navigation are in place.

Money is stored and calculated in **minor units** (integer cents/kobo-style amounts). Display formatting in [`lib/utils.dart`](lib/utils.dart) uses **Nigerian Naira (NGN)** via `intl`; adjust there if you target another currency.

---

## Tech stack

| Area | Choice |
|------|--------|
| Framework | Flutter (Dart SDK `>=3.0.0 <4.0.0`) |
| State & navigation | [GetX](https://pub.dev/packages/get) (`GetMaterialApp`, `Obx`, controllers, `Get.to` / `Get.offAll`) |
| Local database | [sqflite](https://pub.dev/packages/sqflite) — SQLite file on device |
| Key-value preferences | [get_storage](https://pub.dev/packages/get_storage) — PIN metadata, theme, font, fingerprint flag |
| UI | Material 3 (`useMaterial3: true`), [google_fonts](https://pub.dev/packages/google_fonts), [modal_bottom_sheet](https://pub.dev/packages/modal_bottom_sheet), [pinput](https://pub.dev/packages/pinput), [flutter_slidable](https://pub.dev/packages/flutter_slidable), [fl_chart](https://pub.dev/packages/fl_chart) (Insights) |
| Security | [crypto](https://pub.dev/packages/crypto) (salted PIN hash), [local_auth](https://pub.dev/packages/local_auth) |
| Backup | JSON file via [file_picker](https://pub.dev/packages/file_picker) |

---

## Project structure

High-level layout of [`lib/`](lib/):

```
lib/
├── main.dart                 # App entry: GetStorage init, global GetX controllers, GetMaterialApp + themes
├── enums.dart                # TransactionType, ReportType
├── utils.dart                # Currency / signed net formatting
├── file_handler.dart         # Legacy / commented CSV helpers (not active)
│
├── constants/                # App-wide constants
│   ├── app.dart              # Storage keys (PIN, theme, font)
│   ├── db.dart               # DB name, table names, schema version
│   ├── category.dart         # Category keys, labels, icons, pill colors (keys are stable across releases)
│   ├── colors.dart           # Legacy snackbar / accent colors
│   └── backup_constants.dart # Backup JSON format id + version
│
├── theme/
│   ├── app_theme.dart        # Light/dark ThemeData, Google Font wiring, scaled text theme (“midnight” scale)
│   └── app_palette.dart      # AppPalette ThemeExtension — semantic colors for light/dark
│
├── controllers/              # GetX controllers (business + UI state)
│   ├── appController.dart    # Tab index, splash → lock vs home, theme mode & font persistence
│   ├── transactionController.dart
│   ├── contactController.dart
│   ├── reportController.dart # Period filters, report list state (scoped to report screen lifecycle)
│   ├── insights_controller.dart # Insights tab aggregates and period bounds
│   └── securityController.dart
│
├── models/
│   ├── transaction.dart
│   └── contact.dart
│
├── database/
│   ├── db.dart               # Singleton AppDb, openDatabase, onCreate / onUpgrade migrations
│   └── operations.dart       # CRUD and queries used by controllers
│
├── security/
│   └── pin_hash.dart         # Salted SHA-256 PIN; no plaintext PIN on disk
│
├── backup/
│   └── backup_service.dart   # JSON export/import of DB rows + GetStorage preferences
│
├── dialogs/                  # Modals for transaction actions, contacts
├── widgets/                  # Reusable UI (inputs, nav, pin, category pills, transaction rows, grid painter)
├── screens/                  # Full-screen routes (splash, home shell, tabs, lock, forms, report)
└── assets/                   # Images (e.g. launcher / splash source)
```

Platform folders (`android/`, `ios/`) contain standard Flutter embedding; launcher icon and native splash are configured in [`pubspec.yaml`](pubspec.yaml) (`flutter_launcher_icons`, `flutter_native_splash`).

---

## Architecture and decisions

### GetX as the app backbone

- **Controllers** are registered once in [`lib/main.dart`](lib/main.dart): `TransactionController`, `SecurityController`, `AppController`, `ContactController`.
- **Reactive UI** uses `Obx` / `.obs` where lists or settings must update without manual `setState` in parent widgets.
- **Default transition** is `Transition.downToUp` (GetX config) for a consistent sheet-like feel on pushes.
- **`ReportController`** is created with `Get.put` inside [`ReportView`](lib/screens/report.dart) and **deleted** in `dispose` so report-specific state does not leak globally.

### Single source of truth for data

- **Transactions and contacts** live in **SQLite** ([`lib/database/db.dart`](lib/database/db.dart)). Schema version and migrations are in `onUpgrade` (e.g. version 3 reworked the transactions table and removed legacy tables).
- **Preferences and secrets metadata** (not the raw PIN) live in **GetStorage**: theme mode, font id, fingerprint toggle, PIN hash + salt.

### Navigation model

1. **`Splash`** is the initial `home` route (branding + short delay).
2. **`AppController.onReady`** routes to **`LockScreen`** if a PIN is configured, otherwise **`Home`**.
3. **`Home`** is a **5-tab** scaffold: Main, Contacts, Budgets, Insights, Settings. [`PopScope`](lib/screens/home.dart) sends Android back to tab 0 when not on the first tab.

### Forms and sheets

- New transactions open as a **modal bottom sheet** with a transparent background and a wrapped form ([`showNewTransactionModal`](lib/screens/main_screen.dart)), using [`modal_bottom_sheet`](https://pub.dev/packages/modal_bottom_sheet) patterns and scroll-friendly layout.

---

## Data model

### Transaction (`transactions` table)

- Fields include: `description`, `type` (`income` / `expenditure`), `amount` (integer minor units), `date` (epoch ms), `category` (string key), optional `contactId`.
- The Dart model is [`Transaction`](lib/models/transaction.dart); JSON serialization matches backup and DB rows.

### Categories

- Defined in [`lib/constants/category.dart`](lib/constants/category.dart). **Keys are treated as stable API** once shipped (labels and styling may change). Icons and per-theme pill colors (`CategoryPillStyle`) keep lists scannable in both light and dark mode.

### Contacts

- Simple `id` + `name` table; transactions reference `contactId` where relevant.

---

## UI and design system

### “Midnight Mint” palette

- Semantic colors live in **`AppPalette`** ([`lib/theme/app_palette.dart`](lib/theme/app_palette.dart)), registered as a **`ThemeExtension`** on `ThemeData`. Screens resolve colors with `AppPalette.of(context)` so widgets stay theme-aware.
- **Dark** default is a deep blue-gray background with **mint** (positive / income) and **coral** (expense / loss) accents. **Light** mode keeps the same role structure with adjusted contrast.

### Typography

- [`app_theme.dart`](lib/theme/app_theme.dart) applies **Google Fonts** with a fixed **type scale** (`midnightScaledTextTheme`) so switching font family does not break hierarchy.
- Users can pick among several **sans** and **monospace** families (`AppFontIds`); the choice is persisted and applied when building `ThemeData`.

### Recurring visual motifs

- **`MidnightGridPainter`** — Subtle grid lines behind scrollable content for depth without clutter.
- **Glass-style balance card** — Backdrop blur, gradient, and accent tied to whether today’s net is positive or negative ([`MainView`](lib/screens/main_screen.dart)).
- **Bottom navigation** — Custom [`MidnightBottomNav`](lib/widgets/midnight_bottom_nav.dart) aligned with the same visual language.
- **Transaction rows** — Built in [`widgets.dart`](lib/widgets/widgets.dart) with [`flutter_slidable`](https://pub.dev/packages/flutter_slidable): swipe for edit/delete, category pills from `Categories`, and consistent typography.

Internal UX notes for the transaction list live under [`design/`](design/) (e.g. redesign markdown); treat them as product/design references, not runtime code.

---

## Security

- **PIN** — Four digits ([`AppConstants.PIN_CODE_LENGTH`](lib/constants/app.dart)). Stored as **salt + SHA-256 hash** ([`PinHash`](lib/security/pin_hash.dart)); plaintext PIN keys are cleared on upgrade path when setting a new PIN.
- **Biometrics** — Optional; [`local_auth`](https://pub.dev/packages/local_auth) integrates with `SecurityController` for unlock when enabled.
- **Lock flows** — [`LockScreen`](lib/screens/lock_screen.dart) for unlock / PIN removal confirmation; [`PinLock`](lib/screens/pin_lock.dart) for setup and change flows.

---

## Backup and restore

- [`BackupService`](lib/backup/backup_service.dart) exports a **JSON** document with:
  - Format id / version ([`BackupConstants`](lib/constants/backup_constants.dart))
  - DB schema version
  - Contacts and transactions
  - Selected **GetStorage** keys (theme, font, biometrics, PIN hash/salt — so restores preserve lock state if desired)
- Import replaces local DB content and preferences; controllers expose **refresh** paths after import (see backup service and `syncFromStorage`-style methods on `AppController` / `SecurityController`).

---

## Development

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) SDK compatible with the `environment` constraint in [`pubspec.yaml`](pubspec.yaml).
- Xcode (iOS) and/or Android Studio / SDK (Android) as usual for Flutter mobile builds.

### Run

```bash
cd balance_sheet
flutter pub get
flutter run
```

### Tests

```bash
flutter test
```

### Version and branding assets

- App version: **`pubspec.yaml`** → `version:` (e.g. `1.0.0+1`). The
  Settings screen reads this at runtime via [`package_info_plus`]
  (https://pub.dev/packages/package_info_plus) into
  [`AppController.appVersion`](lib/controllers/appController.dart) — no
  hand-maintained constant to keep in sync.
- Regenerate launcher icon / splash after asset changes:

```bash
pip3 install pillow   # once
python3 tool/render_launcher_icon.py
python3 tool/render_native_splash.py
dart run flutter_launcher_icons
dart run flutter_native_splash:create

python3 tool/render_debug_launcher_icon.py
```

The debug icon renderer writes a blue-tinted variant of the launcher
icon directly under `android/app/src/debug/res/...` — Android's
build-type resource overlay swaps it in for `flutter run` / debug
installs while release builds keep the mint icon. See
[`RELEASE.md`](RELEASE.md) for details.

---

## Contributing notes

- Prefer **small, focused changes**; match existing naming, GetX patterns, and `AppPalette` usage rather than introducing parallel styling systems.
- **Do not rename category keys** in [`category.dart`](lib/constants/category.dart) for existing categories without a migration strategy — comments in that file call this out explicitly.
- When changing the backup JSON shape, bump **`BackupConstants.formatVersion`** and document the migration expectation for older files.

---

## Release Workflow

When all changes on `dev` are complete and verified, follow these steps to release a new version:

1.  **Prepare Release Notes**: Add a new release note section for the version in [`RELEASE.md`](RELEASE.md).
2.  **Push `dev`**: Push the `dev` branch to origin.
3.  **Merge to `main`**: 
    - Checkout to `main` and pull the latest changes.
    - Merge `dev` into `main`.
4.  **Cut Release**: On the `main` branch, run the release script:
    ```bash
    ./tool/cut_release.sh <version_number>
    ```
    *(Note: Provide the version number without the 'v' prefix, e.g., `1.1.4`)*
5.  **Tag & Pipeline**: The script will create a git tag and push it to origin, which triggers the automated release pipeline.
6.  **Sync `dev`**: Go back to the `dev` branch and merge `main` into it to keep them synchronized.

---

## License / publishing

The package is marked `publish_to: 'none'` in [`pubspec.yaml`](pubspec.yaml) (private app). Adjust if you later open-source or publish tooling around it.
