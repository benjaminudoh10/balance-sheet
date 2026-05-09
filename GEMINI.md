# Balanced (Project Guidance)

Welcome to the **Balanced** project (internal package name: `balance_sheet`). This document provides architectural context, development standards, and operational workflows for AI agents and developers working on this codebase.

## Project Overview

**Balanced** is a Flutter mobile application for tracking personal finances (income, expenses, budgets, and investments). It emphasizes privacy, offline-first data persistence, and a custom "Midnight Mint" design system.

- **Primary Product Name:** Balanced
- **Tagline:** "...know where your money goes."
- **Platforms:** Android, iOS (Primary targets).

## Tech Stack & Architecture

### Core Frameworks
- **Flutter:** UI and application shell.
- **GetX (`get`):** Primary state management, dependency injection, and navigation.
- **sqflite:** Relational data persistence (SQLite).
- **get_storage:** Persistent key-value store for settings and preferences.

### Project Structure
- `lib/controllers/`: Business logic and reactive state management (GetX).
- `lib/database/`: SQLite initialization (`db.dart`) and CRUD operations (`operations.dart`).
- `lib/models/`: Data models and JSON serialization.
- `lib/screens/`: Top-level page widgets.
- `lib/widgets/`: Reusable, atomic UI components.
- `lib/theme/`: Custom design system implementation (`AppPalette`, `AppTheme`).
- `lib/constants/`: App-wide constants, database keys, and category definitions.

### State Management Patterns
- **Global Controllers:** Long-lived controllers (e.g., `AppController`, `TransactionController`) are initialized in `lib/main.dart` using `Get.put()`.
- **Scoped Controllers:** Ephemeral controllers (e.g., `ReportController`) are typically initialized within the view and disposed of with it.
- **Reactivity:** Use `.obs` for state variables and `Obx()` widgets for reactive UI updates.

## Development Conventions

### Coding Standards
- **Linting:** Follow rules in `analysis_options.yaml` (includes `flutter_lints`).
- **Haptics:** Always use `AppHaptics` (in `lib/utils/app_haptics.dart`) for tactile feedback on user interactions (buttons, slidable actions).
- **Constants:** Never hardcode database table names, storage keys, or category keys. Always use `DBConstants`, `AppConstants`, or `Categories`.

### Data Integrity
- **Category Stability:** Category keys in `lib/constants/category.dart` are **stable APIs**. Do not rename existing keys, as they are used in persistent storage.
- **Minor Units:** Currency is stored and calculated in **minor units** (integers/cents) to avoid floating-point errors. Formatting for display is handled in `lib/utils.dart`.

### Design System: "Midnight Mint"
- **Colors:** Access semantic colors via `AppPalette.of(context)`. 
    - `mint`: Positive/Income/Success.
    - `coral`: Negative/Expense/Danger.
- **UI Elements:** Use `MidnightGridPainter` for background grids and "Glass-style" cards for balance displays.

## Building and Running

### Prerequisites
- Flutter SDK (>=3.0.0 <4.0.0)
- Python 3 (for asset generation scripts)

### Commands
- **Install Dependencies:** `flutter pub get`
- **Run App:** `flutter run`
- **Run Tests:** `flutter test --concurrency=1`
- **Analyze Code:** `dart analyze`
- **Generate Assets:**
  ```bash
  python3 tool/render_launcher_icon.py
  python3 tool/render_native_splash.py
  dart run flutter_launcher_icons
  dart run flutter_native_splash:create
  ```

## Agent Instructions

- **Surgical Edits:** When modifying database logic, ensure changes are reflected in both `lib/database/db.dart` (for schema) and `lib/database/operations.dart`.
- **Testing:** Every bug fix or feature addition must include a corresponding test case in `test/`. Mirror the directory structure of `lib/` in the `test/` folder.
- Run the tests using flutter test --concurrency=1.
- Ensure the code is DRY compliant.
- **Privacy:** Do not log or print sensitive user data. The app is designed for local-only storage.
- **UI Consistency:** Before creating new widgets, check `lib/widgets/widgets.dart` for existing patterns to maintain the "Midnight" aesthetic.
