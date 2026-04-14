class Organization {
  Organization({
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

  factory Organization.fromJson(Map<String, dynamic> data) {
    return Organization(
      id: data['id'] as int? ?? 0,
      name: data['name'] as String? ?? '',
    );
  }
}
