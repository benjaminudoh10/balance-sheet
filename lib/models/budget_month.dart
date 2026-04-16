class BudgetMonth {
  BudgetMonth({
    this.id = 0,
    required this.year,
    required this.month,
  });

  int id;
  final int year;
  final int month;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'year': year,
      'month': month,
    };
  }

  factory BudgetMonth.fromJson(Map<String, dynamic> data) {
    return BudgetMonth(
      id: _asInt(data['id']),
      year: _asInt(data['year']),
      month: _asInt(data['month']),
    );
  }

  static int _asInt(Object? v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}
