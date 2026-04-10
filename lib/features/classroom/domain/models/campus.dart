class CampusEntity {
  final String id;
  final String name;

  const CampusEntity({
    required this.id,
    required this.name,
  });

  factory CampusEntity.fromJson(Map<String, dynamic> json) {
    return CampusEntity(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CampusEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
