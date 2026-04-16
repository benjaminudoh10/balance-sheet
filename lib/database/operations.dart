import 'package:balance_sheet/constants/db.dart';
import 'package:balance_sheet/database/db.dart';
import 'package:balance_sheet/models/contact.dart';
import 'package:balance_sheet/models/transaction.dart';

Future<int> addTransaction(Transaction transaction) async {
  Map<String, dynamic> data = transaction.toJson();
  data.remove('id');

  final dbClient = await AppDb().db;
  int res = await dbClient.insert("${DBConstants.TRANSACTION}", data);
  return res;
}

Future<int> deleteTransaction(Transaction transaction) async {
  final dbClient = await AppDb().db;
  int res = await dbClient.delete(
    "${DBConstants.TRANSACTION}",
    where: "id = ?",
    whereArgs: [transaction.id],
  );

  return res;
}

Future<int> updateTransaction(Transaction transaction) async {
  final dbClient = await AppDb().db;
  int res = await dbClient.update(
    "${DBConstants.TRANSACTION}",
    transaction.toJson(),
    where: "id = ?",
    whereArgs: [transaction.id],
  );

  return res;
}

Future<List<Transaction>> getAllTransactions(int startTime, int endTime, {String? category, int? contactId}) async {
  var dbClient = await AppDb().db;
  String query = "SELECT * FROM ${DBConstants.TRANSACTION} WHERE date >= $startTime AND date <= $endTime ";
  if (category != null && category != "Category") {
    query = "$query AND category = '$category' ";
  }
  if (contactId != null && contactId > 0) {
    query = "$query AND contactId = $contactId ";
  }

  query = "$query ORDER BY date DESC ";
  final transactions = await dbClient.rawQuery(query.trim());

  return transactions.map((transaction) => Transaction.fromJson(transaction)).toList();
}

Future<int> getBalances() async {
  var dbClient = await AppDb().db;
  final totalExpenses = await dbClient.rawQuery("SELECT SUM(amount) as total FROM ${DBConstants.TRANSACTION} WHERE type = 'expenditure'");
  final totalIncome = await dbClient.rawQuery("SELECT SUM(amount) as total FROM ${DBConstants.TRANSACTION} WHERE type = 'income'");
  int income = (totalIncome[0]['total'] as int?) ?? 0;
  int expenses = (totalExpenses[0]['total'] as int?) ?? 0;
  return income - expenses;
}

Future<Map<String, int>> getTodayBalances() async {
  DateTime today = DateTime.now();
  int start = DateTime(today.year, today.month, today.day).millisecondsSinceEpoch;
  int end = DateTime(today.year, today.month, today.day, 23, 59, 59, 999).millisecondsSinceEpoch;
  var dbClient = await AppDb().db;
  final totalExpenses = await dbClient.rawQuery("SELECT SUM(amount) as total FROM ${DBConstants.TRANSACTION} WHERE type = 'expenditure' AND date >= $start AND date <= $end");
  final totalIncome = await dbClient.rawQuery("SELECT SUM(amount) as total FROM ${DBConstants.TRANSACTION} WHERE type = 'income' AND date >= $start AND date <= $end");
  return {
    'expenses': (totalExpenses[0]['total'] as int?) ?? 0,
    'income': (totalIncome[0]['total'] as int?) ?? 0,
  };
}

Future<Map<String, int>> getExpenseForTimePeriod(int start, int end, {String? category, int? contactId}) async {
  var dbClient = await AppDb().db;
  String expenseQuery = "SELECT SUM(amount) as total FROM ${DBConstants.TRANSACTION} WHERE type = 'expenditure' AND date >= $start AND date <= $end ";
  String incomeQuery = "SELECT SUM(amount) as total FROM ${DBConstants.TRANSACTION} WHERE type = 'income' AND date >= $start AND date <= $end ";
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
  int res = await dbClient.insert("${DBConstants.CONTACT}", data);
  return res;
}

Future<List<Map<String, dynamic>>> getContactWithName(String name) async {
  final dbClient = await AppDb().db;
  return dbClient.query(
    "${DBConstants.CONTACT}",
    where: "LOWER(name) = ?",
    whereArgs: [name.toLowerCase()]
  );
}

Future<int> deleteContact(Contact contact) async {
  final dbClient = await AppDb().db;
  int res = await dbClient.delete(
    "${DBConstants.CONTACT}",
    where: "id = ?",
    whereArgs: [contact.id],
  );

  return res;
}

Future<List<Contact>> getContacts() async {
  var dbClient = await AppDb().db;
  final contacts = await dbClient.rawQuery("SELECT * FROM ${DBConstants.CONTACT} ORDER BY name ASC");

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
Future<Map<String, int>> getExpenseTotalsByCategory(int startMs, int endMs) async {
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

/// Largest single expense rows in the range (minor units), newest first on ties.
Future<List<Transaction>> getTopExpenditures(int startMs, int endMs, int limit) async {
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
