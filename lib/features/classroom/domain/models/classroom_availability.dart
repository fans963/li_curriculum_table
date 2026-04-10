class ClassroomAvailabilityEntity {
  final String classroomName;
  final List<bool> availability; // List of 5 bools for the sessions
  final bool hasNoClassesThisTerm;

  const ClassroomAvailabilityEntity({
    required this.classroomName,
    required this.availability,
    this.hasNoClassesThisTerm = false,
  });

  factory ClassroomAvailabilityEntity.fromJson(Map<String, dynamic> json) {
    return ClassroomAvailabilityEntity(
      classroomName: json['classroomName'] as String,
      availability: (json['availability'] as List).cast<bool>(),
      hasNoClassesThisTerm: json['hasNoClassesThisTerm'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'classroomName': classroomName,
        'availability': availability,
        'hasNoClassesThisTerm': hasNoClassesThisTerm,
      };

  bool isFreeInSession(int sessionIndex) {
    if (sessionIndex < 0 || sessionIndex >= availability.length) return false;
    return availability[sessionIndex];
  }
}
