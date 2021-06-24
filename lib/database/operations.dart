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

Future<List<Transaction>> getAllTransactions(int startTime, int endTime) async {
  var dbClient = await AppDb().db;
  final transactions = await dbClient.rawQuery("SELECT * FROM transactions WHERE date >= $startTime AND date <= $endTime");

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

Future<Map<String, int>> getExpenseForTimePeriod(int start, int end) async {
  var dbClient = await AppDb().db;
  final totalExpenses = await dbClient.rawQuery("SELECT SUM(amount) as total FROM transactions WHERE type = 'expenditure' AND date >= $start AND date <= $end");
  final totalIncome = await dbClient.rawQuery("SELECT SUM(amount) as total FROM transactions WHERE type = 'income' AND date >= $start AND date <= $end");

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
