class BuildingEntity {
  final String id;
  final String name;

  const BuildingEntity({
    required this.id,
    required this.name,
  });

  factory BuildingEntity.fromJson(Map<String, dynamic> json) {
    return BuildingEntity(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}
