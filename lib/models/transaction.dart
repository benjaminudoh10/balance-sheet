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
    this.entryIsFcy = false,
    this.entryAmountMinor = 0,
  });

  @override
  String toString() {
    return "${this.toJson()}";
  }

  int id;
  final String description;
  final TransactionType type;
  /// Canonical value in **LCY minor units** (for sums and balance).
  final int amount;
  final DateTime date;
  final String category;
  final int contactId;

  /// When true, the user entered [entryAmountMinor] in FCY; [amount] is the LCY equivalent.
  final bool entryIsFcy;

  /// Minor units in the **entry** currency (LCY or FCY) for display on line items.
  final int entryAmountMinor;

  Map<String, dynamic> toJson() {
    return {
      "id": this.id,
      "description": this.description,
      "type": this.type == TransactionType.income ? "income" : "expenditure",
      "amount": this.amount,
      "date": this.date.millisecondsSinceEpoch,
      "category": this.category,
      "contactId": this.contactId,
      "entryCurrency": entryIsFcy ? "fcy" : "lcy",
      "entryAmount": entryAmountMinor,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> data) {
    final dynamic rawContact = data['contactId'];
    final int contactId = rawContact is int
        ? rawContact
        : rawContact is num
            ? rawContact.toInt()
            : int.tryParse('$rawContact') ?? 0;
    final int amount = data['amount'] as int? ?? 0;
    final String? ec = data['entryCurrency'] as String?;
    final bool isFcy = ec == 'fcy';
    final int rawEntry = data['entryAmount'] as int? ?? 0;
    return Transaction(
      id: data['id'] as int? ?? 0,
      amount: amount,
      description: data['description'] as String? ?? '',
      type: data['type'] == "income" ? TransactionType.income : TransactionType.expenditure,
      date: DateTime.fromMillisecondsSinceEpoch(data['date'] as int? ?? 0),
      category: data['category'] as String? ?? '',
      contactId: contactId,
      entryIsFcy: isFcy,
      entryAmountMinor: isFcy ? rawEntry : amount,
    );
  }
}
