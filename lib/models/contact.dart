class Contact {
  Contact({
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

  factory Contact.fromJson(Map<String, dynamic> data) {
    return Contact(
      id: data['id'],
      name: data['name'],
    );
  }
}
