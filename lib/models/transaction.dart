import 'package:balance_sheet/screens/enums.dart';

class Transaction {
  Transaction({this.id, this.description, this.type, this.amount, this.date});

  final int id;
  final String description;
  final TransactionType type;
  final int amount;
  final DateTime date;

  Map<String, dynamic> toJson() {
    return {
      "description": this.description,
      "type": this.type == TransactionType.income ? "income" : "expenditure",
      "amount": this.amount,
      "date": this.date.millisecondsSinceEpoch,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> data) {
    return Transaction(
      id: data['id'],
      amount: data['amount'],
      description: data['description'],
      type: data['type'] == "income" ? TransactionType.income : TransactionType.expenditure,
      date: DateTime.fromMillisecondsSinceEpoch(data['date'])
    );
  }
}
