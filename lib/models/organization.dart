class Organization {
  Organization({
    this.id,
    this.name,
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
      id: data['id'],
      name: data['name'],
    );
  }
}
