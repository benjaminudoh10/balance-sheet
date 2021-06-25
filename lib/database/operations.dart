import 'package:balance_sheet/database/db.dart';
import 'package:balance_sheet/models/contact.dart';
import 'package:balance_sheet/models/transaction.dart';

Future<int> addTransaction(Transaction transaction) async {
  Map<String, dynamic> data = transaction.toJson();

  final dbClient = await AppDb().db;
  int res = await dbClient.insert("transactions", data);
  return res;
}

Future<int> deleteTransaction(Transaction transaction) async {
  final dbClient = await AppDb().db;
  int res = await dbClient.delete(
    "transactions",
    where: "id = ?",
    whereArgs: [transaction.id],
  );

  return res;
}

Future<int> updateTransaction(Transaction transaction) async {
  final dbClient = await AppDb().db;
  int res = await dbClient.update(
    "transactions",
    transaction.toJson(),
    where: "id = ?",
    whereArgs: [transaction.id],
  );

  return res;
}

Future<List<Transaction>> getAllTransactions(int startTime, int endTime, {String category, int contactId}) async {
  var dbClient = await AppDb().db;
  String query = "SELECT * FROM transactions WHERE date >= $startTime AND date <= $endTime ";
  if (category != "Category" && category != null) {
    query = "$query AND category = '$category' ";
  }
  if (contactId != null) {
    query = "$query AND contactId = $contactId ";
  }

  final transactions = await dbClient.rawQuery(query.trim());

  return transactions.map((transaction) => Transaction.fromJson(transaction)).toList();
}

Future<int> getBalances() async {
  var dbClient = await AppDb().db;
  final totalExpenses = await dbClient.rawQuery("SELECT SUM(amount) as total FROM transactions WHERE type = 'expenditure'");
  final totalIncome = await dbClient.rawQuery("SELECT SUM(amount) as total FROM transactions WHERE type = 'income'");
  return ((totalIncome[0]['total'] ?? 0) - (totalExpenses[0]['total'] ?? 0));
}

Future<Map<String, int>> getTodayBalances() async {
  DateTime today = DateTime.now();
  int start = DateTime(today.year, today.month, today.day).millisecondsSinceEpoch;
  int end = DateTime(today.year, today.month, today.day, 23, 59, 59, 999).millisecondsSinceEpoch;
  var dbClient = await AppDb().db;
  final totalExpenses = await dbClient.rawQuery("SELECT SUM(amount) as total FROM transactions WHERE type = 'expenditure' AND date >= $start AND date <= $end");
  final totalIncome = await dbClient.rawQuery("SELECT SUM(amount) as total FROM transactions WHERE type = 'income' AND date >= $start AND date <= $end");
  return {
    'expenses': totalExpenses[0]['total'],
    'income': totalIncome[0]['total'],
  };
}

Future<Map<String, int>> getExpenseForTimePeriod(int start, int end, {String category, int contactId}) async {
  var dbClient = await AppDb().db;
  String expenseQuery = "SELECT SUM(amount) as total FROM transactions WHERE type = 'expenditure' AND date >= $start AND date <= $end ";
  String incomeQuery = "SELECT SUM(amount) as total FROM transactions WHERE type = 'income' AND date >= $start AND date <= $end ";
  if (category != "Category" && category != null) {
    expenseQuery = "$expenseQuery AND category = '$category' ";
    incomeQuery = "$incomeQuery AND category = '$category' ";
  }
  if (contactId != null) {
    expenseQuery = "$expenseQuery AND contactId = $contactId ";
    incomeQuery = "$incomeQuery AND contactId = $contactId ";
  }
  final totalExpenses = await dbClient.rawQuery(expenseQuery.trim());
  final totalIncome = await dbClient.rawQuery(incomeQuery.trim());

  return {
    'expenses': totalExpenses[0]['total'],
    'income': totalIncome[0]['total'],
  };
}

Future<int> addContact(Contact contact) async {
  Map<String, dynamic> data = contact.toJson();

  final dbClient = await AppDb().db;
  int res = await dbClient.insert("contacts", data);
  return res;
}

Future<List<Map<String, dynamic>>> getContactWithName(String name) async {
  final dbClient = await AppDb().db;
  return dbClient.query(
    "contacts",
    where: "LOWER(name) = ?",
    whereArgs: [name.toLowerCase()]
  );
}

Future<int> deleteContact(Contact contact) async {
  final dbClient = await AppDb().db;
  int res = await dbClient.delete(
    "contacts",
    where: "id = ?",
    whereArgs: [contact.id],
  );

  return res;
}

Future<int> updateContact(Contact contact) async {
  final dbClient = await AppDb().db;
  int res = await dbClient.update(
    "contacts",
    contact.toJson(),
    where: "id = ?",
    whereArgs: [contact.id],
  );

  return res;
}

Future<List<Contact>> getContacts() async {
  var dbClient = await AppDb().db;
  final contacts = await dbClient.rawQuery("SELECT * FROM contacts ORDER BY name ASC");

  return contacts.map((contact) => Contact.fromJson(contact)).toList();
}

Future<Contact> getContact(int id) async {
  var dbClient = await AppDb().db;
  final contact = await dbClient.query(
    'contacts',
    where: 'id = ?',
    whereArgs: [id],
  );

  if (contact.length == 0) {
    return Contact(name: '');
  } else {
    return Contact.fromJson(contact[0]);
  }
}
