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
