class Contact {
  Contact({
    this.id = 0,
    required this.name,
  });

  @override
  String toString() {
    return "${this.toJson()}";
  }

  int id;
  final String name;

  Map<String, dynamic> toJson() {
    return {
      "id": this.id,
      "name": this.name,
    };
  }

  factory Contact.fromJson(Map<String, dynamic> data) {
    final dynamic rawId = data['id'];
    final int id = rawId is int
        ? rawId
        : rawId is num
            ? rawId.toInt()
            : int.tryParse('$rawId') ?? 0;
    return Contact(
      id: id,
      name: data['name'] as String? ?? '',
    );
  }
}
