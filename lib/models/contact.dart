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
    return Contact(
      id: data['id'] as int? ?? 0,
      name: data['name'] as String? ?? '',
    );
  }
}
