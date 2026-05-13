import 'package:balance_sheet/enums.dart';
import 'package:balance_sheet/models/tag.dart';

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
    this.deletedAt,
    this.tags = const [],
  });

  @override
  String toString() {
    return "${toJson()}";
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

  /// Timestamp in milliseconds when the transaction was moved to trash.
  /// Null if the transaction is active.
  final DateTime? deletedAt;

  final List<Tag> tags;

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "description": description,
      "type": type == TransactionType.income ? "income" : "expenditure",
      "amount": amount,
      "date": date.millisecondsSinceEpoch,
      "category": category,
      "contactId": contactId,
      "entryCurrency": entryIsFcy ? "fcy" : "lcy",
      "entryAmount": entryAmountMinor,
      "deletedAt": deletedAt?.millisecondsSinceEpoch,
      "tags": tags.map((t) => t.toJson()).toList(),
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

    final int? rawDeletedAt = data['deletedAt'] as int?;

    final List<dynamic>? rawTags = data['tags'] as List<dynamic>?;
    final List<Tag> tags = rawTags != null
        ? rawTags.map((t) => Tag.fromJson(t as Map<String, dynamic>)).toList()
        : [];

    return Transaction(
      id: data['id'] as int? ?? 0,
      amount: amount,
      description: data['description'] as String? ?? '',
      type: data['type'] == "income"
          ? TransactionType.income
          : TransactionType.expenditure,
      date: DateTime.fromMillisecondsSinceEpoch(data['date'] as int? ?? 0),
      category: data['category'] as String? ?? '',
      contactId: contactId,
      entryIsFcy: isFcy,
      entryAmountMinor: isFcy ? rawEntry : amount,
      deletedAt: rawDeletedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(rawDeletedAt)
          : null,
      tags: tags,
    );
  }
}
