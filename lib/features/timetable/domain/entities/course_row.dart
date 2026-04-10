import 'package:li_curriculum_table/core/rust/crawler/model.dart' as rust_model;

class CourseRow {
  const CourseRow({
    required this.courseId,
    required this.order,
    required this.courseName,
    required this.teacher,
    required this.timeText,
    required this.credit,
    required this.location,
    required this.courseType,
    required this.stage,
    required this.slots,
  });

  factory CourseRow.fromRust(rust_model.CourseRow row) {
    return CourseRow(
      courseId: row.courseId,
      order: row.order,
      courseName: row.courseName,
      teacher: row.teacher,
      timeText: row.timeText,
      credit: row.credit,
      location: row.location,
      courseType: row.courseType,
      stage: row.stage,
      slots: row.slots,
    );
  }

  final String courseId;
  final String order;
  final String courseName;
  final String teacher;
  final String timeText;
  final String credit;
  final String location;
  final String courseType;
  final String stage;
  final List<rust_model.TimeSlot> slots;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'courseId': courseId,
      'order': order,
      'courseName': courseName,
      'teacher': teacher,
      'timeText': timeText,
      'credit': credit,
      'location': location,
      'courseType': courseType,
      'stage': stage,
      'slots': slots.map((e) => {
        'weekday': e.weekday,
        'startSection': e.startSection,
        'endSection': e.endSection,
        'startWeek': e.startWeek,
        'endWeek': e.endWeek,
        'weekText': e.weekText,
      }).toList(),
    };
  }

  static CourseRow? fromJson(Map<String, dynamic> json) {
    final courseId = json['courseId'];
    final order = json['order'];
    final courseName = json['courseName'];
    final teacher = json['teacher'];
    final timeText = json['timeText'];
    final credit = json['credit'];
    final location = json['location'];
    final courseType = json['courseType'];
    final stage = json['stage'];
    final slotsJson = json['slots'] as List?;

    if (courseId is! String ||
        order is! String ||
        courseName is! String ||
        teacher is! String ||
        timeText is! String ||
        credit is! String ||
        location is! String ||
        courseType is! String ||
        stage is! String) {
      return null;
    }

    final slots = <rust_model.TimeSlot>[];
    if (slotsJson != null) {
      for (final s in slotsJson) {
        if (s is Map) {
          slots.add(rust_model.TimeSlot(
            weekday: s['weekday'] as int,
            startSection: s['startSection'] as int,
            endSection: s['endSection'] as int,
            startWeek: s['startWeek'] as int,
            endWeek: s['endWeek'] as int,
            weekText: s['weekText'] as String,
          ));
        }
      }
    }

    return CourseRow(
      courseId: courseId,
      order: order,
      courseName: courseName,
      teacher: teacher,
      timeText: timeText,
      credit: credit,
      location: location,
      courseType: courseType,
      stage: stage,
      slots: slots,
    );
  }
}
