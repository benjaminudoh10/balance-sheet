# All transactions view — redesign proposal

This document proposes a visual and structural refresh for **All transactions** (`ReportView`) so it matches the **Midnight Mint** language used on Home (`MainView`): dark shell, subtle grid, frosted surfaces, mint/coral semantics, and the same transaction row componentry.

**Reference in repo:** `lib/screens/report.dart`, `lib/screens/main_screen.dart`, `lib/constants/midnight_theme.dart`, `lib/widgets/widgets.dart`, `lib/widgets/category_pill_label.dart`.

---

## Design principles (aligned with current app)

| Principle | How it shows up today (Home) | Apply on All transactions |
|-----------|------------------------------|---------------------------|
| Canvas | `MidnightTheme.background` + `MidnightGridPainter` full bleed | Same background + optional light grid behind scroll content |
| Surfaces | `surface` / `surfaceElevated` + `border`, radius **12–24** | Replace flat blocks and **7px** corners with **12–16** radius cards |
| Accent semantics | Mint = income / positive; Coral = expense / negative | Keep; avoid ad-hoc greens/reds |
| Typography | Section titles **18 / w600**; labels **12 / caps / letter-spacing** | Unify; drop mixed “INCOME” all-caps vs body styles where redundant |
| Transaction rows | `singleTransactionContainer` + slidable, category **CategoryPillLabel** | **Primary list = same rows** (no second “table” visual language) |
| Empty state | `EmptyState` + `EmptyStateIconFrame` / mint-tinted icon | Same component; copy tuned to filters + period |

---

## Problems with the current screen

1. **Two visual systems:** summary header + “table” day cards + modal with another list — feels like legacy Material, not Midnight.
2. **Radius inconsistency:** **7px** day cards vs **12px** rows elsewhere.
3. **Redundant hierarchy:** “Transactions” title + DATE/OUT/IN bar + day rows that duplicate what expanded rows already show.
4. **Filters:** default `Chip` + “Add Filter:” row competes with the period pill; category does not use **CategoryPillLabel** styling.
5. **Day drill-in:** full-screen Cupertino sheet for one day is heavy; optional inline expansion is more in line with “glanceable” home.

---

## Proposed layout

### 1. Scaffold & app bar

- **Background:** `MidnightTheme.background`.
- **App bar:** Transparent or same as background; **back** chevron (or close) with `textPrimary`; title **“All transactions”** — **22 / w700 / -0.4 tracking** to mirror the income sheet title rhythm (not the old plain `AppBar` default).
- Optional: **no** elevation shadow; bottom border `MidnightTheme.border` **1px** if separation is needed.

### 2. Full-bleed grid (optional but recommended)

- Stack: `MidnightGridPainter(heightFraction: 1.0)` under scroll content, same as `MainView`, so the screen reads as **the same product** as Home.

### 3. Summary strip (replaces the tall INCOME/EXPENSE block)

- **One** frosted card (same *idea* as `_GlassBalanceCard`, not necessarily identical metrics):
  - **ClipRRect** ~**20–24** radius, **BackdropFilter** blur, border `mint` or `coral` at **~0.35** opacity depending on net (or neutral border if you prefer calm).
  - **Net for period** as the hero number (`formatSignedNet` or period net from `income`/`expense`).
  - Secondary line: **Income** (mint) | **Expense** (coral) in a **single row** with smaller type — avoids two heavy columns.
- **Period control** sits **inside** or **flush under** this card:
  - Pill button: `MidnightTheme.surfaceElevated`, border `MidnightTheme.border`, label = current range (`ReportController.label`), trailing `Icons.keyboard_arrow_down_rounded`.
  - Tap opens existing `ReportTypeDialog` (behavior unchanged).

### 4. Filters row (compact)

- Single horizontal **scroll** row (or wrapped chips) — no “Add Filter:” label.
- **Category:** use **CategoryPillLabel** when a real category is selected; placeholder state = neutral pill “Category” with `textSecondary`.
- **Contact:** small pill with `Icons.person_outline_rounded` + name, or “Contact” placeholder; clear affordance matches Home patterns.
- **Clear all:** one text button **Clear filters** (`mint` or `textSecondary`) when anything active.

### 5. Main list — unified timeline

**Preferred (simpler, aligned with Home):**

- **Section headers by day:** sticky or spaced — **“Wed, Apr 15”** in `textSecondary` **13 / w600**; optional small subline **Net · +₦…** with mint/coral.
- **Rows:** `singleTransactionContainer(transaction)` only — same slidable edit/delete, same category pills.
- **Remove** the DATE / OUT / IN table header and the old **day summary cards** that only show aggregates + “View”. Aggregates move to section headers or disappear if redundant with row sum.

**Alternative (if daily totals stay important):**

- Keep one **compact day header row** (date + out + in) using **12px** radius and the same border/surface tokens — still no second modal by default; **tap** expands/collapses that day’s rows **inline** (Animation) instead of a full modal sheet.

### 6. Empty & loading

- **Empty:** `EmptyState` with `Icons.receipt_long_outlined` (match Home) or chart icon; primary line about **period + filters**; secondary **Change period** / **Clear filters**.
- **Loading:** subtle `LinearProgressIndicator` in mint under app bar or shimmer on 2–3 placeholder rows — only if `ReportController.fetchingTransaction` is wired for this route.

### 7. Modal sheet (if retained for day detail)

- If you **keep** `showCupertinoModalBottomSheet` for day breakdown:
  - Sheet **grabber**, **24** top radius, `MidnightTheme.background`.
  - Header row matches **new_income_form** sheet pattern (title + close in rounded icon container).
  - Reuse **`totalDayTransaction`** + **`singleTransactionContainer`** list — no white/coral legacy blocks.

---

## Spacing & metrics (concrete)

- Horizontal page padding: **20** (match `_horizontalPad` on Home).
- Section title to first row: **12** vertical.
- Between day sections: **20–24**.
- Card interior padding: **12–16** (match transaction card).

---

## What to reuse vs build

| Reuse as-is | Adapt / wrap |
|-------------|----------------|
| `ReportController` (time range, filters, `splitTransactions`) | Optional: map list to flat `List<Transaction>` + group in UI, or keep map |
| `ReportTypeDialog`, `CategoryDialog`, `ContactDialog` | Style dialogs to midnight if still Material 2 grey |
| `singleTransactionContainer`, `totalDayTransaction`, `EmptyState` | — |
| `MidnightGridPainter` | New thin wrapper or copy stack from `MainView` |
| `formatAmount`, `formatSignedNet` | Summary strip |

---

## Out of scope for this doc

- CSV export, charts, or new report types.
- Changing SQLite or `ReportController` business logic unless a flat list is required for performance.

---

## Summary

Bring **All transactions** in line with **Home**: same grid, one frosted summary + period pill, filter pills that use **CategoryPillLabel**, and a **single scroll** of **slidable transaction rows** grouped by day — replacing the old table header, small-radius day cards, and heavy day modal unless product explicitly needs the modal.
