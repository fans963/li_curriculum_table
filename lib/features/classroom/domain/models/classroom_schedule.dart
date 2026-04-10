class OccupiedSlotEntity {
  final int startWeek;
  final int endWeek;
  final int weekday;
  final int slotIndex;

  const OccupiedSlotEntity({
    required this.startWeek,
    required this.endWeek,
    required this.weekday,
    required this.slotIndex,
  });

  factory OccupiedSlotEntity.fromJson(Map<String, dynamic> json) {
    return OccupiedSlotEntity(
      startWeek: json['startWeek'] as int,
      endWeek: json['endWeek'] as int,
      weekday: json['weekday'] as int,
      slotIndex: json['slotIndex'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'startWeek': startWeek,
        'endWeek': endWeek,
        'weekday': weekday,
        'slotIndex': slotIndex,
      };
}

class ClassroomScheduleEntity {
  final String classroomName;
  final List<OccupiedSlotEntity> occupiedSlots;

  const ClassroomScheduleEntity({
    required this.classroomName,
    required this.occupiedSlots,
  });

  factory ClassroomScheduleEntity.fromJson(Map<String, dynamic> json) {
    return ClassroomScheduleEntity(
      classroomName: json['classroomName'] as String,
      occupiedSlots: (json['occupiedSlots'] as List)
          .map((e) => OccupiedSlotEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'classroomName': classroomName,
        'occupiedSlots': occupiedSlots.map((e) => e.toJson()).toList(),
      };
}
