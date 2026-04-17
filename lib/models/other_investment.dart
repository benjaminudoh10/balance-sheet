/// A manual line item (cash, land, gold, etc.) counted toward net worth.
/// [valueLcyMinor] is canonical in local currency; entry fields mirror what the user typed.
class OtherInvestment {
  OtherInvestment({
    required this.id,
    required this.label,
    required this.valueLcyMinor,
    required this.entryCurrency,
    required this.entryMinor,
    required this.sortOrder,
    required this.updatedAtMs,
  });

  final int id;
  final String label;
  final int valueLcyMinor;
  final String entryCurrency;
  final int entryMinor;
  final int sortOrder;
  final int updatedAtMs;

  bool get entryIsFcy => entryCurrency.toLowerCase() == 'fcy';

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'label': label,
      'value_lcy_minor': valueLcyMinor,
      'entry_currency': entryCurrency,
      'entry_minor': entryMinor,
      'sort_order': sortOrder,
      'updated_at_ms': updatedAtMs,
    };
  }

  factory OtherInvestment.fromMap(Map<String, Object?> m) {
    final String ec = '${m['entry_currency'] ?? 'lcy'}'.toLowerCase();
    final int lcy = _asInt(m['value_lcy_minor']);
    int entry = _asInt(m['entry_minor']);
    if (entry == 0 && lcy != 0) {
      entry = lcy;
    }
    return OtherInvestment(
      id: _asInt(m['id']),
      label: '${m['label'] ?? ''}'.trim(),
      valueLcyMinor: lcy,
      entryCurrency: ec == 'fcy' ? 'fcy' : 'lcy',
      entryMinor: entry,
      sortOrder: _asInt(m['sort_order']),
      updatedAtMs: _asInt(m['updated_at_ms']),
    );
  }

  static int _asInt(Object? v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}
