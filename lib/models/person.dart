class Person {
  final String id;
  final String name;
  final DateTime createdAt;

  Person({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Person.fromJson(Map<String, dynamic> json) => Person(
        id: json['id'],
        name: json['name'],
        createdAt: DateTime.parse(json['createdAt']),
      );

  Person copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
