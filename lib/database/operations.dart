import 'package:balance_sheet/database/db.dart';
import 'package:balance_sheet/models/transaction.dart';

Future addTransaction(Transaction transaction) async {
  Map<String, dynamic> data = transaction.toJson();

  final dbClient = await AppDb().db;
  int res = await dbClient.insert("transactions", data);
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
  return (totalIncome[0]['total'] - totalExpenses[0]['total']);
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
