# Agents

This file provides context and instructions for AI agents (like Gemini CLI) working on the **Balance Sheet** project.

## Project Overview

**Balance Sheet** (Product name: **Balanced**) is a Flutter-based personal finance application designed for tracking income, expenses, budgets, and investments with a strong focus on privacy and a custom "Midnight" aesthetic.

### Tech Stack

- **Framework:** Flutter (Targeting iOS & Android)
- **State Management:** [GetX](https://pub.dev/packages/get)
- **Database:** [sqflite](https://pub.dev/packages/sqflite) (Relational data)
- **Key-Value Store:** [get_storage](https://pub.dev/packages/get_storage) (Settings & Preferences)
- **UI & Theme:** Custom implementation in `lib/theme/`, utilizing `google_fonts`.
- **Visual Style:** "Midnight" theme, characterized by dark backgrounds, grid patterns (`MidnightGridPainter`), and specific color palettes (`AppPalette`).

## Architectural Patterns

### State Management (GetX)

- **Controllers:** Located in `lib/controllers/`. Most controllers are long-lived and initialized in `lib/main.dart` using `Get.put()`.
- **Observables:** Use `.obs` for reactive state variables and `Obx` or `GetX` widgets in the UI for updates.
- **Dependency Injection:** Access controllers using `Get.find<ControllerName>()`.

### Data Layer

- **Models:** POJO classes in `lib/models/` for data structure.
- **Database Operations:** Abstracted in `lib/database/operations.dart` and `lib/database/investment_operations.dart`. Direct SQL queries are used via `sqflite`.
- **Category Stability:** Category keys in `lib/constants/category.dart` are considered a **stable API**. Labels and icons can change, but keys must remain constant to avoid breaking existing data.

### Directory Structure

- `lib/controllers/`: Business logic and state management.
- `lib/models/`: Data models and serialization.
- `lib/screens/`: High-level page widgets.
- `lib/widgets/`: Reusable, atomic UI components.
- `lib/theme/`: Centralized styling (colors, fonts, themes).
- `lib/constants/`: App-wide constants, database keys, and enums.
- `lib/database/`: Database initialization and CRUD operations.
- `lib/utils/`: Generic utility functions (haptics, date formatting, etc.).

## Design System: Midnight Mint

- **Palette:** Semantic colors are defined in `AppPalette` (as a `ThemeExtension`). Use `AppPalette.of(context)` to access colors like `mint` (income) and `coral` (expenses).
- **Typography:** Uses a fixed type scale (`midnightScaledTextTheme`) applied via `app_theme.dart`.
- **Motifs:**
    - `MidnightGridPainter`: Subtle background grids.
    - `Glass-style cards`: Used for balance displays with backdrop blur and gradients.

## Development Workflows

### Asset Generation

The project uses Python scripts in `tool/` to render branding assets:
- `python3 tool/render_launcher_icon.py`
- `python3 tool/render_native_splash.py`
- `python3 tool/render_debug_launcher_icon.py` (for Android debug variant)

Followed by standard Flutter commands:
- `dart run flutter_launcher_icons`
- `dart run flutter_native_splash:create`

### Testing

- Maintain high test coverage. Test files are located in `test/` and should mirror the structure of `lib/`.
- Run tests with `flutter test`.

## Agent Instructions

- **Context Preservation:** Always check `lib/constants/` before hardcoding strings or keys.
- **State management:** When adding features, prefer extending existing GetX controllers or creating new ones if the logic is distinct.
- **Database:** Ensure all database changes are reflected in `lib/database/db.dart` (schema versions) and relevant operation files.
- **UI Consistency:** Adhere strictly to the `AppPalette` and `AppTheme`. Use `AppHaptics` for interactive feedback.
- **No Key Renaming:** Never rename existing category keys in `lib/constants/category.dart`.
