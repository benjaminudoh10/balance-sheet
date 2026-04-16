/// One planned spend row for a calendar month (minor units, same as ledger amounts).
///
/// Optional [categoryKey] and [contactId] align with transaction category and contact.
/// When both are set, “spent” sums expenditures that match **either** (union); with one
/// set, only that filter applies.
class BudgetLine {
  BudgetLine({
    this.id = 0,
    required this.budgetMonthId,
    required this.description,
    required this.plannedAmount,
    this.contactId = 0,
    this.categoryKey = '',
    this.sortOrder = 0,
  });

  int id;
  final int budgetMonthId;
  final String description;
  final int plannedAmount;
  final int contactId;
  /// Same string keys as transaction `category` in the ledger; empty = no category filter.
  final String categoryKey;
  final int sortOrder;

  bool get hasSpendTracker => categoryKey.isNotEmpty || contactId > 0;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'budgetMonthId': budgetMonthId,
      'description': description,
      'plannedAmount': plannedAmount,
      'contactId': contactId,
      'categoryKey': categoryKey,
      'sortOrder': sortOrder,
    };
  }

  factory BudgetLine.fromJson(Map<String, dynamic> data) {
    return BudgetLine(
      id: _asInt(data['id']),
      budgetMonthId: _asInt(data['budget_month_id'] ?? data['budgetMonthId']),
      description: data['description'] as String? ?? '',
      plannedAmount: _asInt(data['planned_amount'] ?? data['plannedAmount']),
      contactId: _asInt(data['contact_id'] ?? data['contactId']),
      categoryKey: data['category'] as String? ?? data['categoryKey'] as String? ?? '',
      sortOrder: _asInt(data['sort_order'] ?? data['sortOrder']),
    );
  }

  static int _asInt(Object? v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  BudgetLine copyWith({
    int? id,
    int? budgetMonthId,
    String? description,
    int? plannedAmount,
    int? contactId,
    String? categoryKey,
    int? sortOrder,
  }) {
    return BudgetLine(
      id: id ?? this.id,
      budgetMonthId: budgetMonthId ?? this.budgetMonthId,
      description: description ?? this.description,
      plannedAmount: plannedAmount ?? this.plannedAmount,
      contactId: contactId ?? this.contactId,
      categoryKey: categoryKey ?? this.categoryKey,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
