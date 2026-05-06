import 'package:balance_sheet/constants/db.dart';
import 'package:balance_sheet/database/db.dart';
import 'package:balance_sheet/models/budget_line.dart';
import 'package:balance_sheet/models/budget_month.dart';
import 'package:balance_sheet/models/contact.dart';
import 'package:balance_sheet/models/transaction.dart';

Future<int> addTransaction(Transaction transaction) async {
  Map<String, dynamic> data = transaction.toJson();
  data.remove('id');

  final dbClient = await AppDb().db;
  int res = await dbClient.insert(DBConstants.TRANSACTION, data);
  return res;
}

Future<int> deleteTransaction(Transaction transaction) async {
  final dbClient = await AppDb().db;
  int res = await dbClient.delete(
    DBConstants.TRANSACTION,
    where: "id = ?",
    whereArgs: [transaction.id],
  );

  return res;
}

Future<int> updateTransaction(Transaction transaction) async {
  final dbClient = await AppDb().db;
  int res = await dbClient.update(
    DBConstants.TRANSACTION,
    transaction.toJson(),
    where: "id = ?",
    whereArgs: [transaction.id],
  );

  return res;
}

/// Fetches transactions in [startTime]..[endTime] ordered newest-first.
///
/// Pass [limit] and [offset] to page through large ranges. A secondary sort
/// on `id DESC` keeps pagination stable when multiple rows share a date.
Future<List<Transaction>> getAllTransactions(
  int startTime,
  int endTime, {
  String? category,
  int? contactId,
  int? limit,
  int? offset,
}) async {
  var dbClient = await AppDb().db;
  String query =
      "SELECT * FROM ${DBConstants.TRANSACTION} WHERE date >= $startTime AND date <= $endTime ";
  if (category != null && category != "Category") {
    query = "$query AND category = '$category' ";
  }
  if (contactId != null && contactId > 0) {
    query = "$query AND contactId = $contactId ";
  }

  query = "$query ORDER BY date DESC, id DESC ";
  if (limit != null && limit > 0) {
    query = "$query LIMIT $limit ";
    if (offset != null && offset > 0) {
      query = "$query OFFSET $offset ";
    }
  }
  final transactions = await dbClient.rawQuery(query.trim());

  return transactions
      .map((transaction) => Transaction.fromJson(transaction))
      .toList();
}

Future<int> getBalances() async {
  var dbClient = await AppDb().db;
  final totalExpenses = await dbClient.rawQuery(
      "SELECT SUM(amount) as total FROM ${DBConstants.TRANSACTION} WHERE type = 'expenditure'");
  final totalIncome = await dbClient.rawQuery(
      "SELECT SUM(amount) as total FROM ${DBConstants.TRANSACTION} WHERE type = 'income'");
  int income = (totalIncome[0]['total'] as int?) ?? 0;
  int expenses = (totalExpenses[0]['total'] as int?) ?? 0;
  return income - expenses;
}

Future<Map<String, int>> getTodayBalances() async {
  DateTime today = DateTime.now();
  int start =
      DateTime(today.year, today.month, today.day).millisecondsSinceEpoch;
  int end = DateTime(today.year, today.month, today.day, 23, 59, 59, 999)
      .millisecondsSinceEpoch;
  var dbClient = await AppDb().db;
  final totalExpenses = await dbClient.rawQuery(
      "SELECT SUM(amount) as total FROM ${DBConstants.TRANSACTION} WHERE type = 'expenditure' AND date >= $start AND date <= $end");
  final totalIncome = await dbClient.rawQuery(
      "SELECT SUM(amount) as total FROM ${DBConstants.TRANSACTION} WHERE type = 'income' AND date >= $start AND date <= $end");
  return {
    'expenses': (totalExpenses[0]['total'] as int?) ?? 0,
    'income': (totalIncome[0]['total'] as int?) ?? 0,
  };
}

Future<Map<String, int>> getExpenseForTimePeriod(int start, int end,
    {String? category, int? contactId}) async {
  var dbClient = await AppDb().db;
  String expenseQuery =
      "SELECT SUM(amount) as total FROM ${DBConstants.TRANSACTION} WHERE type = 'expenditure' AND date >= $start AND date <= $end ";
  String incomeQuery =
      "SELECT SUM(amount) as total FROM ${DBConstants.TRANSACTION} WHERE type = 'income' AND date >= $start AND date <= $end ";
  if (category != null && category != "Category") {
    expenseQuery = "$expenseQuery AND category = '$category' ";
    incomeQuery = "$incomeQuery AND category = '$category' ";
  }
  if (contactId != null && contactId > 0) {
    expenseQuery = "$expenseQuery AND contactId = $contactId ";
    incomeQuery = "$incomeQuery AND contactId = $contactId ";
  }
  final totalExpenses = await dbClient.rawQuery(expenseQuery.trim());
  final totalIncome = await dbClient.rawQuery(incomeQuery.trim());

  return {
    'expenses': (totalExpenses[0]['total'] as int?) ?? 0,
    'income': (totalIncome[0]['total'] as int?) ?? 0,
  };
}

Future<int> addContact(Contact contact) async {
  Map<String, dynamic> data = contact.toJson();
  data.remove('id');

  final dbClient = await AppDb().db;
  int res = await dbClient.insert(DBConstants.CONTACT, data);
  return res;
}

Future<List<Map<String, dynamic>>> getContactWithName(String name) async {
  final dbClient = await AppDb().db;
  return dbClient.query(DBConstants.CONTACT,
      where: "LOWER(name) = ?", whereArgs: [name.toLowerCase()]);
}

Future<int> deleteContact(Contact contact) async {
  final dbClient = await AppDb().db;
  int res = await dbClient.delete(
    DBConstants.CONTACT,
    where: "id = ?",
    whereArgs: [contact.id],
  );

  return res;
}

Future<int> updateContact(Contact contact) async {
  if (contact.id <= 0) {
    return 0;
  }
  final dbClient = await AppDb().db;
  return dbClient.update(
    DBConstants.CONTACT,
    <String, dynamic>{'name': contact.name},
    where: 'id = ?',
    whereArgs: <dynamic>[contact.id],
  );
}

Future<List<Contact>> getContacts() async {
  var dbClient = await AppDb().db;
  final contacts = await dbClient
      .rawQuery("SELECT * FROM ${DBConstants.CONTACT} ORDER BY name ASC");

  return contacts.map((contact) => Contact.fromJson(contact)).toList();
}

/// Single contact by primary key (for lookups when only an id is known, e.g. insights).
Future<Contact?> getContactById(int id) async {
  if (id <= 0) {
    return null;
  }
  final dbClient = await AppDb().db;
  final List<Map<String, dynamic>> rows = await dbClient.query(
    DBConstants.CONTACT,
    where: 'id = ?',
    whereArgs: <Object>[id],
    limit: 1,
  );
  if (rows.isEmpty) {
    return null;
  }
  return Contact.fromJson(rows.first);
}

/// Sum of expenditure amounts per category for the inclusive date range (ms).
Future<Map<String, int>> getExpenseTotalsByCategory(
    int startMs, int endMs) async {
  final dbClient = await AppDb().db;
  final rows = await dbClient.rawQuery(
    '''
    SELECT category, SUM(amount) AS total
    FROM ${DBConstants.TRANSACTION}
    WHERE type = 'expenditure' AND date >= ? AND date <= ?
    GROUP BY category
    ORDER BY total DESC
    ''',
    [startMs, endMs],
  );
  final Map<String, int> out = {};
  for (final row in rows) {
    final String key = row['category'] as String? ?? 'misc';
    out[key] = (row['total'] as int?) ?? 0;
  }
  return out;
}

/// Sum of expenditures in [startMs]..[endMs] (inclusive) matching optional [categoryKey] and/or [contactId].
/// Omit a filter by passing null or empty category / non-positive contact.
///
/// When **both** are set, matches the **union**: transactions with that category **or** that contact
/// (each row counted once in the sum).
Future<int> getExpenditureTotalFiltered(
  int startMs,
  int endMs, {
  String? categoryKey,
  int? contactId,
}) async {
  final String catTrim = categoryKey?.trim() ?? '';
  final bool useCat = catTrim.isNotEmpty;
  final bool useContact = contactId != null && contactId > 0;
  if (!useCat && !useContact) {
    return 0;
  }
  final dbClient = await AppDb().db;
  final StringBuffer where =
      StringBuffer("type = 'expenditure' AND date >= ? AND date <= ?");
  final List<Object?> args = <Object?>[startMs, endMs];
  if (useCat && useContact) {
    where.write(' AND (category = ? OR contactId = ?)');
    args.add(catTrim);
    args.add(contactId);
  } else if (useCat) {
    where.write(' AND category = ?');
    args.add(catTrim);
  } else {
    where.write(' AND contactId = ?');
    args.add(contactId);
  }
  final List<Map<String, dynamic>> rows = await dbClient.rawQuery(
    'SELECT COALESCE(SUM(amount), 0) AS total FROM ${DBConstants.TRANSACTION} WHERE ${where.toString()}',
    args,
  );
  final Object? t = rows.first['total'];
  if (t is int) return t;
  if (t is num) return t.toInt();
  return int.tryParse('$t') ?? 0;
}

/// Largest single expense rows in the range (minor units), newest first on ties.
Future<List<Transaction>> getTopExpenditures(
    int startMs, int endMs, int limit) async {
  final dbClient = await AppDb().db;
  final rows = await dbClient.rawQuery(
    '''
    SELECT * FROM ${DBConstants.TRANSACTION}
    WHERE type = 'expenditure' AND date >= ? AND date <= ?
    ORDER BY amount DESC, date DESC
    LIMIT ?
    ''',
    [startMs, endMs, limit],
  );
  return rows.map((e) => Transaction.fromJson(e)).toList();
}

/// Local calendar month bounds in epoch milliseconds (inclusive).
({int startMs, int endMs}) calendarMonthEpochRange(int year, int month) {
  final int startMs = DateTime(year, month, 1).millisecondsSinceEpoch;
  final int endMs =
      DateTime(year, month + 1, 0, 23, 59, 59, 999).millisecondsSinceEpoch;
  return (startMs: startMs, endMs: endMs);
}

Future<BudgetMonth?> getBudgetMonth(int year, int month) async {
  final dbClient = await AppDb().db;
  final List<Map<String, dynamic>> rows = await dbClient.query(
    DBConstants.BUDGET_MONTH,
    where: 'year = ? AND month = ?',
    whereArgs: <Object>[year, month],
    limit: 1,
  );
  if (rows.isEmpty) {
    return null;
  }
  return BudgetMonth.fromJson(rows.first);
}

Future<BudgetMonth> ensureBudgetMonth(int year, int month) async {
  final BudgetMonth? existing = await getBudgetMonth(year, month);
  if (existing != null) {
    return existing;
  }
  final dbClient = await AppDb().db;
  final int id =
      await dbClient.insert(DBConstants.BUDGET_MONTH, <String, Object?>{
    'year': year,
    'month': month,
  });
  return BudgetMonth(id: id, year: year, month: month);
}

Future<List<BudgetMonth>> getAllBudgetMonths() async {
  final dbClient = await AppDb().db;
  final List<Map<String, dynamic>> rows = await dbClient.query(
    DBConstants.BUDGET_MONTH,
    orderBy: 'year DESC, month DESC',
  );
  return rows.map(BudgetMonth.fromJson).toList();
}

Future<List<BudgetLine>> getBudgetLinesForMonth(int budgetMonthId) async {
  final dbClient = await AppDb().db;
  final List<Map<String, dynamic>> rows = await dbClient.query(
    DBConstants.BUDGET_LINE,
    where: 'budget_month_id = ?',
    whereArgs: <Object>[budgetMonthId],
    orderBy: 'sort_order ASC, id ASC',
  );
  return rows.map(BudgetLine.fromJson).toList();
}

Future<int> nextBudgetLineSortOrder(int budgetMonthId) async {
  final dbClient = await AppDb().db;
  final List<Map<String, dynamic>> rows = await dbClient.rawQuery(
    'SELECT COALESCE(MAX(sort_order), -1) + 1 AS n FROM ${DBConstants.BUDGET_LINE} WHERE budget_month_id = ?',
    <Object>[budgetMonthId],
  );
  final Object? n = rows.first['n'];
  if (n is int) return n;
  if (n is num) return n.toInt();
  return 0;
}

Future<int> insertBudgetLine({
  required int budgetMonthId,
  required String description,
  required int plannedAmount,
  int contactId = 0,
  String categoryKey = '',
  bool planEntryIsFcy = false,
  int planEntryAmountMinor = 0,
}) async {
  final dbClient = await AppDb().db;
  final int sortOrder = await nextBudgetLineSortOrder(budgetMonthId);
  final int entryAmt =
      planEntryAmountMinor > 0 ? planEntryAmountMinor : plannedAmount;
  return dbClient.insert(DBConstants.BUDGET_LINE, <String, Object?>{
    'budget_month_id': budgetMonthId,
    'description': description,
    'planned_amount': plannedAmount,
    'contact_id': contactId <= 0 ? null : contactId,
    'category': categoryKey,
    'sort_order': sortOrder,
    'entryCurrency': planEntryIsFcy ? 'fcy' : 'lcy',
    'entryAmount': entryAmt,
  });
}

Future<void> updateBudgetLine(BudgetLine line) async {
  final dbClient = await AppDb().db;
  await dbClient.update(
    DBConstants.BUDGET_LINE,
    <String, Object?>{
      'description': line.description,
      'planned_amount': line.plannedAmount,
      'contact_id': line.contactId <= 0 ? null : line.contactId,
      'category': line.categoryKey,
      'sort_order': line.sortOrder,
      'entryCurrency': line.planEntryIsFcy ? 'fcy' : 'lcy',
      'entryAmount': line.planEntryAmountMinor > 0
          ? line.planEntryAmountMinor
          : line.plannedAmount,
    },
    where: 'id = ?',
    whereArgs: <Object>[line.id],
  );
}

Future<void> deleteBudgetLine(int lineId) async {
  final dbClient = await AppDb().db;
  await dbClient.delete(
    DBConstants.BUDGET_LINE,
    where: 'id = ?',
    whereArgs: <Object>[lineId],
  );
}

/// Sum of expenditure amounts per contact for the inclusive date range (minor units).
Future<Map<int, int>> getExpenditureTotalsByContact(
    int startMs, int endMs) async {
  final dbClient = await AppDb().db;
  final List<Map<String, dynamic>> rows = await dbClient.rawQuery(
    '''
    SELECT contactId AS cid, SUM(amount) AS total
    FROM ${DBConstants.TRANSACTION}
    WHERE type = 'expenditure' AND date >= ? AND date <= ?
      AND contactId IS NOT NULL AND contactId > 0
    GROUP BY contactId
    ''',
    <Object>[startMs, endMs],
  );
  final Map<int, int> out = <int, int>{};
  for (final Map<String, dynamic> row in rows) {
    final Object? rawCid = row['cid'];
    final int cid = rawCid is int
        ? rawCid
        : (rawCid is num ? rawCid.toInt() : int.tryParse('$rawCid') ?? 0);
    final Object? t = row['total'];
    final int total =
        t is int ? t : (t is num ? t.toInt() : int.tryParse('$t') ?? 0);
    if (cid > 0) {
      out[cid] = total;
    }
  }
  return out;
}

Future<List<Map<String, dynamic>>> queryAllBudgetMonthRows() async {
  final dbClient = await AppDb().db;
  return dbClient.query(DBConstants.BUDGET_MONTH, orderBy: 'id ASC');
}

Future<List<Map<String, dynamic>>> queryAllBudgetLineRows() async {
  final dbClient = await AppDb().db;
  return dbClient.query(DBConstants.BUDGET_LINE, orderBy: 'id ASC');
}
