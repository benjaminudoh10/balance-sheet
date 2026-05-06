class InvestmentPricePoint {
  InvestmentPricePoint({
    required this.id,
    required this.holdingId,
    required this.asOfMs,
    required this.asOfDay,

    /// **LCY** minor per share (canonical for portfolio / net worth).
    required this.priceMinorPerShare,
    required this.entryCurrency,
    required this.priceEntryMinorPerShare,
  });

  final int id;
  final int holdingId;
  final int asOfMs;
  final int asOfDay;
  final int priceMinorPerShare;
  final String entryCurrency;
  final int priceEntryMinorPerShare;

  bool get entryIsFcy => entryCurrency.toLowerCase() == 'fcy';

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'holding_id': holdingId,
      'as_of_ms': asOfMs,
      'as_of_day': asOfDay,
      'price_minor_per_share': priceMinorPerShare,
      'entry_currency': entryCurrency,
      'price_entry_minor': priceEntryMinorPerShare,
    };
  }

  factory InvestmentPricePoint.fromMap(Map<String, Object?> m) {
    final int ms = _asInt(m['as_of_ms']);
    int day = _asInt(m['as_of_day']);
    if (day <= 0 && ms > 0) {
      final DateTime t = DateTime.fromMillisecondsSinceEpoch(ms);
      day = t.year * 10000 + t.month * 100 + t.day;
    }
    final int lcy = _asInt(m['price_minor_per_share']);
    final String ec = '${m['entry_currency'] ?? 'lcy'}'.toLowerCase();
    int entry = _asInt(m['price_entry_minor']);
    if (entry == 0 && lcy != 0) {
      entry = lcy;
    }
    return InvestmentPricePoint(
      id: _asInt(m['id']),
      holdingId: _asInt(m['holding_id']),
      asOfMs: ms,
      asOfDay: day,
      priceMinorPerShare: lcy,
      entryCurrency: ec == 'fcy' ? 'fcy' : 'lcy',
      priceEntryMinorPerShare: entry,
    );
  }

  static int _asInt(Object? v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}
