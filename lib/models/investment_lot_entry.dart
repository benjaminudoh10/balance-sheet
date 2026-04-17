class InvestmentLotEntry {
  InvestmentLotEntry({
    required this.id,
    required this.holdingId,
    required this.occurredAtMs,
    required this.quantityDelta,
    /// FIFO cost basis: **LCY** minor units per share (canonical).
    required this.purchasePriceMinorPerShare,
    required this.purchaseEntryCurrency,
    required this.purchasePriceEntryMinorPerShare,
    required this.note,
  });

  final int id;
  final int holdingId;
  final int occurredAtMs;
  final double quantityDelta;
  final int purchasePriceMinorPerShare;
  /// `lcy` or `fcy` — currency the user typed for [purchasePriceEntryMinorPerShare].
  final String purchaseEntryCurrency;
  /// Minor units in [purchaseEntryCurrency] per share (for display).
  final int purchasePriceEntryMinorPerShare;
  final String note;

  bool get purchaseEntryIsFcy => purchaseEntryCurrency.toLowerCase() == 'fcy';

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'holding_id': holdingId,
      'occurred_at_ms': occurredAtMs,
      'quantity_delta': quantityDelta,
      'purchase_price_minor_per_share': purchasePriceMinorPerShare,
      'purchase_entry_currency': purchaseEntryCurrency,
      'purchase_price_entry_minor': purchasePriceEntryMinorPerShare,
      'note': note,
    };
  }

  factory InvestmentLotEntry.fromMap(Map<String, Object?> m) {
    final Object? q = m['quantity_delta'];
    final double qty = q is num ? q.toDouble() : double.tryParse('$q') ?? 0.0;
    final int lcyPs = _asInt(m['purchase_price_minor_per_share']);
    final String ec = '${m['purchase_entry_currency'] ?? 'lcy'}'.toLowerCase();
    int entryPs = _asInt(m['purchase_price_entry_minor']);
    if (entryPs == 0 && lcyPs != 0) {
      entryPs = lcyPs;
    }
    return InvestmentLotEntry(
      id: _asInt(m['id']),
      holdingId: _asInt(m['holding_id']),
      occurredAtMs: _asInt(m['occurred_at_ms']),
      quantityDelta: qty,
      purchasePriceMinorPerShare: lcyPs,
      purchaseEntryCurrency: ec == 'fcy' ? 'fcy' : 'lcy',
      purchasePriceEntryMinorPerShare: entryPs,
      note: '${m['note'] ?? ''}',
    );
  }

  static int _asInt(Object? v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}
