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
  });

  final String courseId;
  final String order;
  final String courseName;
  final String teacher;
  final String timeText;
  final String credit;
  final String location;
  final String courseType;
  final String stage;

  Map<String, String> toJson() {
    return <String, String>{
      'courseId': courseId,
      'order': order,
      'courseName': courseName,
      'teacher': teacher,
      'timeText': timeText,
      'credit': credit,
      'location': location,
      'courseType': courseType,
      'stage': stage,
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
    );
  }

  static CourseRow? fromParsed(List<String> row) {
    if (row.length < 10) {
      return null;
    }

    return CourseRow(
      courseId: row[1],
      order: row[2],
      courseName: row[3],
      teacher: row[4],
      timeText: row[5],
      credit: row[6],
      location: row[7],
      courseType: row[8],
      stage: row[9],
    );
  }
}
