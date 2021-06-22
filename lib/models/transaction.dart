import 'package:balance_sheet/enums.dart';

class Transaction {
  Transaction({
    this.id,
    this.description,
    this.type,
    this.amount,
    this.date,
    this.category,
  });

  @override
  String toString() {
    return "${this.toJson()}";
  }

  int id;
  final String description;
  final TransactionType type;
  final int amount;
  final DateTime date;
  final String category;

  Map<String, dynamic> toJson() {
    return {
      "id": this.id,
      "description": this.description,
      "type": this.type == TransactionType.income ? "income" : "expenditure",
      "amount": this.amount,
      "date": this.date.millisecondsSinceEpoch,
      "category": this.category,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> data) {
    return Transaction(
      id: data['id'],
      amount: data['amount'],
      description: data['description'],
      type: data['type'] == "income" ? TransactionType.income : TransactionType.expenditure,
      date: DateTime.fromMillisecondsSinceEpoch(data['date']),
      category: data['category'],
    );
  }
}
