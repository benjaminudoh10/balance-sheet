class Tag {
  Tag({
    this.id = 0,
    required this.name,
  });

  @override
  String toString() {
    return "${toJson()}";
  }

  int id;
  final String name;

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
    };
  }

  factory Tag.fromJson(Map<String, dynamic> data) {
    final dynamic rawId = data['id'];
    final int id = rawId is int
        ? rawId
        : rawId is num
            ? rawId.toInt()
            : int.tryParse('$rawId') ?? 0;
    return Tag(
      id: id,
      name: data['name'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tag && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
