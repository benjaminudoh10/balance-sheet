# Plan: Copy Budget Items to Next Month

## Goal
Implement a feature to copy all budget items from one budget month to the next calendar month.

## Implementation Steps

1.  **UI/UX (TBD - Needs investigation)**:
    *   Add a "Copy to Next Month" button in the budget view for a specific month.
    *   Confirm if the target month already has items. If yes, warn or ask to append/replace.

2.  **Database Logic (lib/database/operations.dart)**:
    *   Determine target `BudgetMonth` (the next calendar month, e.g., current month M, next is M+1).
    *   Call `ensureBudgetMonth(nextYear, nextMonth)` to get the target `budgetMonthId`.
    *   Fetch current `BudgetLines` for the source `budgetMonthId` using `getBudgetLinesForMonth`.
    *   Iterate through `BudgetLines`:
        *   Create new `BudgetLine` entries for the target month.
        *   Copy `description`, `plannedAmount`, `contactId`, `categoryKey`, `planEntryIsFcy`, `planEntryAmountMinor`.
        *   The `sortOrder` should naturally follow the list order, or just re-insert.
        *   *Note:* `id` must be 0 for auto-increment in SQLite.
    *   Execute these insertions within a transaction to ensure atomicity.

3.  **Verification**:
    *   Verify the copy works correctly for items with/without categories/contacts.
    *   Verify the items appear in the target month's view.

## Open Questions
*   How to handle the case where the next month already has items?
*   Where to place the "Copy" action (e.g., in a menu, as a button on the UI)?

## Tasks
- [ ] Implement `copyBudgetLinesToMonth(int sourceBudgetMonthId, int targetYear, int targetMonth)` in `lib/database/operations.dart`.
- [ ] Add unit/integration tests for the new function.
- [ ] Integrate into the UI (needs investigation into which file handles the UI).
