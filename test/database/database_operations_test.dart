import 'package:balance_sheet/database/investment_operations.dart' as inv_ops;
import 'package:balance_sheet/database/operations.dart' as db_ops;
import 'package:balance_sheet/enums.dart';
import 'package:balance_sheet/models/budget_line.dart';
import 'package:balance_sheet/models/budget_month.dart';
import 'package:balance_sheet/models/contact.dart';
import 'package:balance_sheet/models/investment_lot_entry.dart';
import 'package:balance_sheet/models/investment_price_point.dart';
import 'package:balance_sheet/models/other_investment.dart';
import 'package:balance_sheet/models/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/database_test_setup.dart';

void main() {
  setUpAll(() {
    initializeSqfliteFfiForTests();
  });

  setUp(() async {
    await resetAppDatabaseFile();
  });

  group('transactions', () {
    test('addTransaction assigns id and getAllTransactions returns row',
        () async {
      final Transaction t = Transaction(
        description: 'Lunch',
        type: TransactionType.expenditure,
        amount: 2500,
        date: DateTime(2025, 3, 10, 14, 30),
        category: 'food',
        contactId: 0,
      );
      final int id = await db_ops.addTransaction(t);
      expect(id, greaterThan(0));

      final int start = DateTime(2025, 3, 1).millisecondsSinceEpoch;
      final int end =
          DateTime(2025, 3, 31, 23, 59, 59, 999).millisecondsSinceEpoch;
      final List<Transaction> list =
          await db_ops.getAllTransactions(start, end);
      expect(list.length, 1);
      expect(list.first.id, id);
      expect(list.first.category, 'food');
      expect(list.first.type, TransactionType.expenditure);
    });

    test('getBalances is income minus expenses', () async {
      await db_ops.addTransaction(Transaction(
        description: 'in',
        type: TransactionType.income,
        amount: 10000,
        date: DateTime(2025, 1, 1),
        category: 'salary',
        contactId: 0,
      ));
      await db_ops.addTransaction(Transaction(
        description: 'out',
        type: TransactionType.expenditure,
        amount: 3500,
        date: DateTime(2025, 1, 2),
        category: 'food',
        contactId: 0,
      ));
      expect(await db_ops.getBalances(), 6500);
    });

    test('getTodayBalances only counts current local day', () async {
      final DateTime now = DateTime.now();
      final DateTime todayNoon = DateTime(now.year, now.month, now.day, 12);
      final DateTime y = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 1));
      final DateTime yesterday = DateTime(y.year, y.month, y.day, 12);

      await db_ops.addTransaction(Transaction(
        description: 'today exp',
        type: TransactionType.expenditure,
        amount: 100,
        date: todayNoon,
        category: 'misc',
        contactId: 0,
      ));
      await db_ops.addTransaction(Transaction(
        description: 'old',
        type: TransactionType.expenditure,
        amount: 9999,
        date: yesterday,
        category: 'misc',
        contactId: 0,
      ));

      final Map<String, int> m = await db_ops.getTodayBalances();
      expect(m['expenses'], 100);
    });

    test('getAllTransactions filters by category when not Category', () async {
      final DateTime ts = DateTime(2025, 7, 1);
      await db_ops.addTransaction(Transaction(
        description: 'a',
        type: TransactionType.expenditure,
        amount: 1,
        date: ts,
        category: 'food',
        contactId: 0,
      ));
      await db_ops.addTransaction(Transaction(
        description: 'b',
        type: TransactionType.expenditure,
        amount: 2,
        date: ts,
        category: 'rent',
        contactId: 0,
      ));
      final int start = DateTime(2025, 7, 1).millisecondsSinceEpoch;
      final int end = DateTime(2025, 7, 31).millisecondsSinceEpoch;
      final List<Transaction> food =
          await db_ops.getAllTransactions(start, end, category: 'food');
      expect(food.length, 1);
      expect(food.first.category, 'food');
    });

    test('getAllTransactions paginates via limit and offset', () async {
      // Insert 5 rows on distinct days so the ORDER BY date DESC, id DESC
      // produces a deterministic newest-first ordering.
      final List<int> ids = <int>[];
      for (int i = 0; i < 5; i++) {
        final int id = await db_ops.addTransaction(Transaction(
          description: 'row $i',
          type: TransactionType.expenditure,
          amount: 100 + i,
          date: DateTime(2025, 6, 1 + i),
          category: 'misc',
          contactId: 0,
        ));
        ids.add(id);
      }
      final int start = DateTime(2025, 6, 1).millisecondsSinceEpoch;
      final int end =
          DateTime(2025, 6, 30, 23, 59, 59, 999).millisecondsSinceEpoch;

      final List<Transaction> page1 =
          await db_ops.getAllTransactions(start, end, limit: 2, offset: 0);
      final List<Transaction> page2 =
          await db_ops.getAllTransactions(start, end, limit: 2, offset: 2);
      final List<Transaction> page3 =
          await db_ops.getAllTransactions(start, end, limit: 2, offset: 4);

      expect(page1.length, 2);
      expect(page2.length, 2);
      expect(page3.length, 1);
      // Newest first: June 5 row id is last inserted.
      expect(page1.first.id, ids.last);
      expect(page1.last.id, ids[3]);
      expect(page2.first.id, ids[2]);
      expect(page2.last.id, ids[1]);
      expect(page3.first.id, ids.first);
    });

    test('getAllTransactions without limit still returns every row', () async {
      for (int i = 0; i < 4; i++) {
        await db_ops.addTransaction(Transaction(
          description: 'row $i',
          type: TransactionType.income,
          amount: 1,
          date: DateTime(2025, 5, 1 + i),
          category: 'salary',
          contactId: 0,
        ));
      }
      final int start = DateTime(2025, 5, 1).millisecondsSinceEpoch;
      final int end =
          DateTime(2025, 5, 30, 23, 59, 59, 999).millisecondsSinceEpoch;
      expect((await db_ops.getAllTransactions(start, end)).length, 4);
    });

    test('getAllTransactions filters by contactId when positive', () async {
      final int cid = await db_ops.addContact(Contact(name: 'Vendor'));
      final DateTime ts = DateTime(2025, 8, 1);
      await db_ops.addTransaction(Transaction(
        description: 'with contact',
        type: TransactionType.income,
        amount: 50,
        date: ts,
        category: 'salary',
        contactId: cid,
      ));
      await db_ops.addTransaction(Transaction(
        description: 'no contact',
        type: TransactionType.income,
        amount: 60,
        date: ts,
        category: 'salary',
        contactId: 0,
      ));
      final int start = DateTime(2025, 8, 1).millisecondsSinceEpoch;
      final int end = DateTime(2025, 8, 31).millisecondsSinceEpoch;
      final List<Transaction> filtered =
          await db_ops.getAllTransactions(start, end, contactId: cid);
      expect(filtered.length, 1);
      expect(filtered.first.contactId, cid);
    });

    test('updateTransaction mutates row', () async {
      final int id = await db_ops.addTransaction(Transaction(
        description: 'orig',
        type: TransactionType.expenditure,
        amount: 100,
        date: DateTime(2025, 9, 1),
        category: 'misc',
        contactId: 0,
      ));
      final Transaction updated = Transaction(
        id: id,
        description: 'new desc',
        type: TransactionType.expenditure,
        amount: 200,
        date: DateTime(2025, 9, 1),
        category: 'food',
        contactId: 0,
      );
      expect(await db_ops.updateTransaction(updated), 1);
      final int start = DateTime(2025, 9, 1).millisecondsSinceEpoch;
      final int end = DateTime(2025, 9, 30).millisecondsSinceEpoch;
      final List<Transaction> rows =
          await db_ops.getAllTransactions(start, end);
      expect(rows.first.description, 'new desc');
      expect(rows.first.amount, 200);
    });

    test('deleteTransaction removes row', () async {
      final int id = await db_ops.addTransaction(Transaction(
        description: 'del',
        type: TransactionType.income,
        amount: 1,
        date: DateTime(2025, 10, 1),
        category: 'savings',
        contactId: 0,
      ));
      expect(
        await db_ops.deleteTransaction(Transaction(
          id: id,
          description: 'del',
          type: TransactionType.income,
          amount: 1,
          date: DateTime(2025, 10, 1),
          category: 'savings',
          contactId: 0,
        )),
        1,
      );
      final int start = DateTime(2025, 10, 1).millisecondsSinceEpoch;
      final int end = DateTime(2025, 10, 31).millisecondsSinceEpoch;
      expect(await db_ops.getAllTransactions(start, end), isEmpty);
    });

    test('getExpenseForTimePeriod respects filters', () async {
      final int cid = await db_ops.addContact(Contact(name: 'P'));
      final DateTime ts = DateTime(2025, 11, 15);
      await db_ops.addTransaction(Transaction(
        description: 'e1',
        type: TransactionType.expenditure,
        amount: 40,
        date: ts,
        category: 'utilities',
        contactId: cid,
      ));
      await db_ops.addTransaction(Transaction(
        description: 'e2',
        type: TransactionType.expenditure,
        amount: 10,
        date: ts,
        category: 'food',
        contactId: cid,
      ));
      final int start = DateTime(2025, 11, 1).millisecondsSinceEpoch;
      final int end = DateTime(2025, 11, 30).millisecondsSinceEpoch;
      final Map<String, int> totals = await db_ops.getExpenseForTimePeriod(
          start, end,
          category: 'utilities', contactId: cid);
      expect(totals['expenses'], 40);
      expect(totals['income'], 0);
    });

    test('getExpenseTotalsByCategory sums only expenditures in range',
        () async {
      final DateTime ts = DateTime(2025, 12, 5);
      final int start = DateTime(2025, 12, 1).millisecondsSinceEpoch;
      final int end =
          DateTime(2025, 12, 31, 23, 59, 59, 999).millisecondsSinceEpoch;
      await db_ops.addTransaction(Transaction(
        description: 'food',
        type: TransactionType.expenditure,
        amount: 3000,
        date: ts,
        category: 'food',
        contactId: 0,
      ));
      await db_ops.addTransaction(Transaction(
        description: 'food2',
        type: TransactionType.expenditure,
        amount: 1000,
        date: ts,
        category: 'food',
        contactId: 0,
      ));
      await db_ops.addTransaction(Transaction(
        description: 'sal',
        type: TransactionType.income,
        amount: 50000,
        date: ts,
        category: 'salary',
        contactId: 0,
      ));
      final Map<String, int> byCat =
          await db_ops.getExpenseTotalsByCategory(start, end);
      expect(byCat['food'], 4000);
      expect(byCat.containsKey('salary'), isFalse);
    });

    test('getContactById returns contact by primary key', () async {
      final int id = await db_ops.addContact(Contact(name: 'Ada'));
      expect(id, greaterThan(0));
      final Contact? found = await db_ops.getContactById(id);
      expect(found, isNotNull);
      expect(found!.name, 'Ada');
      expect(await db_ops.getContactById(999999), isNull);
    });

    test('getTopExpenditures returns largest expense rows first', () async {
      final DateTime ts = DateTime(2025, 12, 8);
      final int start = DateTime(2025, 12, 1).millisecondsSinceEpoch;
      final int end =
          DateTime(2025, 12, 31, 23, 59, 59, 999).millisecondsSinceEpoch;
      await db_ops.addTransaction(Transaction(
        description: 'small',
        type: TransactionType.expenditure,
        amount: 100,
        date: ts,
        category: 'misc',
        contactId: 0,
      ));
      await db_ops.addTransaction(Transaction(
        description: 'big',
        type: TransactionType.expenditure,
        amount: 9999,
        date: ts,
        category: 'rent',
        contactId: 0,
      ));
      final List<Transaction> top =
          await db_ops.getTopExpenditures(start, end, 2);
      expect(top.length, 2);
      expect(top.first.amount, 9999);
      expect(top.first.description, 'big');
    });
  });

  group('contacts', () {
    test('addContact and getContacts ordered by name', () async {
      await db_ops.addContact(Contact(name: 'Zed'));
      await db_ops.addContact(Contact(name: 'Amy'));
      final List<Contact> list = await db_ops.getContacts();
      expect(list.map((c) => c.name).toList(), ['Amy', 'Zed']);
    });

    test('getContactWithName is case-insensitive', () async {
      await db_ops.addContact(Contact(name: 'Bob'));
      final List<Map<String, dynamic>> found =
          await db_ops.getContactWithName('bob');
      expect(found.length, 1);
    });

    test('deleteContact removes contact', () async {
      final int id = await db_ops.addContact(Contact(name: 'Temp'));
      await db_ops.deleteContact(Contact(id: id, name: 'Temp'));
      expect(await db_ops.getContacts(), isEmpty);
    });
  });

  group('budget', () {
    test('copyBudgetLinesToMonth copies lines to target month', () async {
      final BudgetMonth m1 = await db_ops.ensureBudgetMonth(2026, 5);
      final int cid = await db_ops.addContact(Contact(name: 'Store'));
      await db_ops.insertBudgetLine(
        budgetMonthId: m1.id,
        description: 'Groceries',
        plannedAmount: 50000,
        contactId: cid,
        categoryKey: 'food',
      );
      await db_ops.insertBudgetLine(
        budgetMonthId: m1.id,
        description: 'Rent',
        plannedAmount: 100000,
        contactId: 0,
        categoryKey: 'rent',
      );

      await db_ops.copyBudgetLinesToMonth(m1.id, 2026, 6);

      final BudgetMonth m2 = await db_ops.ensureBudgetMonth(2026, 6);
      final List<BudgetLine> lines = await db_ops.getBudgetLinesForMonth(m2.id);
      expect(lines.length, 2);
      expect(lines[0].description, 'Groceries');
      expect(lines[0].plannedAmount, 50000);
      expect(lines[0].contactId, cid);
      expect(lines[0].categoryKey, 'food');
      expect(lines[1].description, 'Rent');
      expect(lines[1].plannedAmount, 100000);
      expect(lines[1].contactId, 0);
      expect(lines[1].categoryKey, 'rent');
    });

    test('ensureBudgetMonth getOrCreate and budget lines CRUD', () async {
      final BudgetMonth m = await db_ops.ensureBudgetMonth(2026, 4);
      expect(m.year, 2026);
      expect(m.month, 4);
      expect(m.id, greaterThan(0));

      final BudgetMonth? again = await db_ops.getBudgetMonth(2026, 4);
      expect(again!.id, m.id);
      expect(await db_ops.getBudgetLinesForMonth(m.id), isEmpty);

      final int cid = await db_ops.addContact(Contact(name: 'Landlord'));
      final int lid = await db_ops.insertBudgetLine(
        budgetMonthId: m.id,
        description: 'Rent',
        plannedAmount: 150000,
        contactId: cid,
        categoryKey: 'rent',
      );
      expect(lid, greaterThan(0));

      final List<BudgetLine> lines = await db_ops.getBudgetLinesForMonth(m.id);
      expect(lines.length, 1);
      expect(lines.first.description, 'Rent');
      expect(lines.first.plannedAmount, 150000);
      expect(lines.first.contactId, cid);
      expect(lines.first.categoryKey, 'rent');

      await db_ops.updateBudgetLine(
        lines.first.copyWith(
            description: 'Rent updated',
            plannedAmount: 160000,
            categoryKey: 'utilities'),
      );
      final List<BudgetLine> after = await db_ops.getBudgetLinesForMonth(m.id);
      expect(after.single.description, 'Rent updated');
      expect(after.single.plannedAmount, 160000);
      expect(after.single.categoryKey, 'utilities');

      await db_ops.deleteBudgetLine(lid);
      expect(await db_ops.getBudgetLinesForMonth(m.id), isEmpty);
    });

    test('getExpenditureTotalsByContact sums expenditure in range', () async {
      final int cid = await db_ops.addContact(Contact(name: 'Shop'));
      final ({int startMs, int endMs}) r =
          db_ops.calendarMonthEpochRange(2026, 3);
      await db_ops.addTransaction(Transaction(
        description: 'a',
        type: TransactionType.expenditure,
        amount: 5000,
        date: DateTime(2026, 3, 15),
        category: 'food',
        contactId: cid,
      ));
      await db_ops.addTransaction(Transaction(
        description: 'b',
        type: TransactionType.income,
        amount: 100000,
        date: DateTime(2026, 3, 16),
        category: 'salary',
        contactId: cid,
      ));
      final Map<int, int> map =
          await db_ops.getExpenditureTotalsByContact(r.startMs, r.endMs);
      expect(map[cid], 5000);
    });

    test('getExpenditureTotalFiltered matches category and/or contact',
        () async {
      final int cid = await db_ops.addContact(Contact(name: 'Shop'));
      final ({int startMs, int endMs}) r =
          db_ops.calendarMonthEpochRange(2026, 5);
      await db_ops.addTransaction(Transaction(
        description: 'lunch',
        type: TransactionType.expenditure,
        amount: 1000,
        date: DateTime(2026, 5, 2),
        category: 'food',
        contactId: cid,
      ));
      await db_ops.addTransaction(Transaction(
        description: 'bus',
        type: TransactionType.expenditure,
        amount: 2500,
        date: DateTime(2026, 5, 3),
        category: 'transport',
        contactId: cid,
      ));
      // Food ∪ contact Shop: lunch (food+Shop) + bus (transport+Shop) — union, not intersection.
      expect(
        await db_ops.getExpenditureTotalFiltered(r.startMs, r.endMs,
            categoryKey: 'food', contactId: cid),
        3500,
      );
      expect(
          await db_ops.getExpenditureTotalFiltered(r.startMs, r.endMs,
              categoryKey: 'food'),
          1000);
      expect(
          await db_ops.getExpenditureTotalFiltered(r.startMs, r.endMs,
              contactId: cid),
          3500);
      expect(
          await db_ops.getExpenditureTotalFiltered(r.startMs, r.endMs,
              categoryKey: 'transport'),
          2500);
    });
  });

  group('investments', () {
    test('lots and manual prices value portfolio in minor units', () async {
      final int hid = await inv_ops.insertInvestmentHolding(
          ticker: 'TST', displayName: 'Test Co');
      final int t0 = DateTime(2026, 1, 5, 12).millisecondsSinceEpoch;
      await inv_ops.insertInvestmentLot(
        holdingId: hid,
        occurredAtMs: t0,
        quantityDelta: 2.5,
        purchasePriceMinorPerShare: 8000,
      );
      await inv_ops.insertInvestmentPricePoint(
        holdingId: hid,
        asOfDayYyyymmdd: 20260106,
        priceMinorPerShare: 10000,
      );
      expect(await inv_ops.totalQuantityForHolding(hid), 2.5);
      expect(
          await inv_ops.getInvestmentStocksTotalMinor(), (2.5 * 10000).round());
    });

    test('lot and price persist entry currency alongside LCY canonical',
        () async {
      final int hid =
          await inv_ops.insertInvestmentHolding(ticker: 'FCY', displayName: '');
      final int t0 = DateTime(2026, 2, 1).millisecondsSinceEpoch;
      await inv_ops.insertInvestmentLot(
        holdingId: hid,
        occurredAtMs: t0,
        quantityDelta: 1,
        purchasePriceMinorPerShare: 100000,
        purchaseEntryIsFcy: true,
        purchasePriceEntryMinorPerShare: 100,
      );
      await inv_ops.insertInvestmentPricePoint(
        holdingId: hid,
        asOfDayYyyymmdd: 20260202,
        priceMinorPerShare: 200000,
        entryIsFcy: true,
        priceEntryMinorPerShare: 200,
      );
      final List<InvestmentLotEntry> lots =
          await inv_ops.listLotsForHolding(hid);
      expect(lots.length, 1);
      expect(lots.first.purchasePriceMinorPerShare, 100000);
      expect(lots.first.purchaseEntryIsFcy, isTrue);
      expect(lots.first.purchasePriceEntryMinorPerShare, 100);
      final List<InvestmentPricePoint> pts =
          await inv_ops.listPricePointsForHolding(hid);
      expect(pts.length, 1);
      expect(pts.first.priceMinorPerShare, 200000);
      expect(pts.first.entryIsFcy, isTrue);
      expect(pts.first.priceEntryMinorPerShare, 200);
    });

    test('other investments list and sum LCY for net worth', () async {
      final int cashId = await inv_ops.insertOtherInvestment(
        label: 'Cash',
        entryCurrency: 'lcy',
      );
      await inv_ops.insertOtherAssetLineItem(
        assetId: cashId,
        description: 'Opening balance',
        amountMinor: 2000000,
        entryCurrency: 'lcy',
        entryAmountMinor: 2000000,
        occurredAtMs: DateTime(2026, 1, 10).millisecondsSinceEpoch,
      );
      final int goldId = await inv_ops.insertOtherInvestment(
        label: 'Gold',
        entryCurrency: 'fcy',
      );
      await inv_ops.insertOtherAssetLineItem(
        assetId: goldId,
        description: 'Opening balance',
        amountMinor: 1800000,
        entryCurrency: 'fcy',
        entryAmountMinor: 120000,
        occurredAtMs: DateTime(2026, 1, 11).millisecondsSinceEpoch,
      );
      expect(
          await inv_ops.getOtherInvestmentsTotalLcyMinor(), 2000000 + 1800000);
      final List<OtherInvestment> rows = await inv_ops.listOtherInvestments();
      expect(rows.length, 2);
      expect(rows.map((OtherInvestment e) => e.label).toSet(),
          <String>{'Cash', 'Gold'});
    });
  });
}
