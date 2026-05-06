class InvestmentHolding {
  InvestmentHolding({
    required this.id,
    required this.ticker,
    required this.displayName,
    required this.sortOrder,
    required this.createdAtMs,
  });

  final int id;
  final String ticker;
  final String displayName;
  final int sortOrder;
  final int createdAtMs;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'ticker': ticker,
      'display_name': displayName,
      'sort_order': sortOrder,
      'created_at_ms': createdAtMs,
    };
  }

  factory InvestmentHolding.fromMap(Map<String, Object?> m) {
    return InvestmentHolding(
      id: _asInt(m['id']),
      ticker: '${m['ticker'] ?? ''}',
      displayName: '${m['display_name'] ?? ''}',
      sortOrder: _asInt(m['sort_order']),
      createdAtMs: _asInt(m['created_at_ms']),
    );
  }

  InvestmentHolding copyWith({
    int? id,
    String? ticker,
    String? displayName,
    int? sortOrder,
    int? createdAtMs,
  }) {
    return InvestmentHolding(
      id: id ?? this.id,
      ticker: ticker ?? this.ticker,
      displayName: displayName ?? this.displayName,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAtMs: createdAtMs ?? this.createdAtMs,
    );
  }

  static int _asInt(Object? v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}
