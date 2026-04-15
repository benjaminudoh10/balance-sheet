import 'package:balance_sheet/enums.dart';

class Transaction {
  Transaction({
    this.id = 0,
    required this.description,
    required this.type,
    required this.amount,
    required this.date,
    required this.category,
    required this.contactId,
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
  final int contactId;

  Map<String, dynamic> toJson() {
    return {
      "id": this.id,
      "description": this.description,
      "type": this.type == TransactionType.income ? "income" : "expenditure",
      "amount": this.amount,
      "date": this.date.millisecondsSinceEpoch,
      "category": this.category,
      "contactId": this.contactId,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> data) {
    return Transaction(
      id: data['id'] as int? ?? 0,
      amount: data['amount'] as int? ?? 0,
      description: data['description'] as String? ?? '',
      type: data['type'] == "income" ? TransactionType.income : TransactionType.expenditure,
      date: DateTime.fromMillisecondsSinceEpoch(data['date'] as int? ?? 0),
      category: data['category'] as String? ?? '',
      contactId: data['contactId'] as int? ?? 0,
    );
  }
}
