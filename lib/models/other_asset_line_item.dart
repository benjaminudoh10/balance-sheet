class OtherAssetLineItem {
  OtherAssetLineItem({
    required this.id,
    required this.assetId,
    required this.description,
    required this.amountMinor,
    required this.entryCurrency,
    required this.entryAmountMinor,
    required this.occurredAtMs,
    required this.createdAtMs,
  });

  final int id;
  final int assetId;
  final String description;
  final int amountMinor;
  final String entryCurrency;
  final int entryAmountMinor;
  final int occurredAtMs;
  final int createdAtMs;

  bool get entryIsFcy => entryCurrency.toLowerCase() == 'fcy';

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'asset_id': assetId,
      'description': description,
      'amount_minor': amountMinor,
      'entry_currency': entryCurrency,
      'entry_amount_minor': entryAmountMinor,
      'occurred_at_ms': occurredAtMs,
      'created_at_ms': createdAtMs,
    };
  }

  factory OtherAssetLineItem.fromMap(Map<String, Object?> m) {
    final String ec = '${m['entry_currency'] ?? 'lcy'}'.toLowerCase();
    final int amountMinor = _asInt(m['amount_minor']);
    int entryAmountMinor = _asInt(m['entry_amount_minor']);
    if (entryAmountMinor == 0 && amountMinor != 0) {
      entryAmountMinor = amountMinor;
    }
    return OtherAssetLineItem(
      id: _asInt(m['id']),
      assetId: _asInt(m['asset_id']),
      description: '${m['description'] ?? ''}'.trim(),
      amountMinor: amountMinor,
      entryCurrency: ec == 'fcy' ? 'fcy' : 'lcy',
      entryAmountMinor: entryAmountMinor,
      occurredAtMs: _asInt(m['occurred_at_ms']),
      createdAtMs: _asInt(m['created_at_ms']),
    );
  }

  static int _asInt(Object? v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}
