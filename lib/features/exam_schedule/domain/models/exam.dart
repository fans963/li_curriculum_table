class ExamEntity {
  final String session;
  final String courseCode;
  final String courseName;
  final String examTime;
  final String location;
  final String seatNumber;

  const ExamEntity({
    required this.session,
    required this.courseCode,
    required this.courseName,
    required this.examTime,
    required this.location,
    required this.seatNumber,
  });

  factory ExamEntity.fromJson(Map<String, dynamic> json) {
    return ExamEntity(
      session: json['session'] as String,
      courseCode: json['courseCode'] as String,
      courseName: json['courseName'] as String,
      examTime: json['examTime'] as String,
      location: json['location'] as String,
      seatNumber: json['seatNumber'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'session': session,
    'courseCode': courseCode,
    'courseName': courseName,
    'examTime': examTime,
    'location': location,
    'seatNumber': seatNumber,
  };

  /// Parse the start DateTime from examTime text.
  /// Format: "2026-05-16 08:30~10:30"
  DateTime? get startTime {
    try {
      final datePart = examTime.split(' ').first;
      final startTimePart = examTime.split(' ').last.split('~').first.trim();
      return DateTime.parse('$datePart $startTimePart');
    } catch (_) {
      return null;
    }
  }

  /// Parse the end DateTime from examTime text.
  DateTime? get endTime {
    try {
      final datePart = examTime.split(' ').first;
      final endTimePart = examTime.split('~').last.trim();
      return DateTime.parse('$datePart $endTimePart');
    } catch (_) {
      return null;
    }
  }

  /// Whether this exam has already passed.
  bool get isExpired {
    final end = endTime;
    if (end == null) return false;
    return DateTime.now().isAfter(end);
  }

  /// Whether this exam is happening today.
  bool get isToday {
    final start = startTime;
    if (start == null) return false;
    final now = DateTime.now();
    return now.year == start.year &&
        now.month == start.month &&
        now.day == start.day;
  }

  /// Days remaining until the exam. Negative if already passed.
  /// Returns null if time cannot be parsed.
  int? get daysRemaining {
    final start = startTime;
    if (start == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final examDay = DateTime(start.year, start.month, start.day);
    return examDay.difference(today).inDays;
  }

  /// Human-readable countdown text.
  String get countdownText {
    final days = daysRemaining;
    if (days == null) return '';
    if (days < 0) return '已结束';
    if (days == 0) return '今天';
    if (days == 1) return '明天';
    if (days == 2) return '后天';
    return '$days天后';
  }

  /// Extract just the time range portion. "08:30~10:30"
  String get timeRange {
    try {
      final parts = examTime.split(' ');
      if (parts.length >= 2) return parts.last;
      return examTime;
    } catch (_) {
      return examTime;
    }
  }

  /// Extract just the date portion. "2026-05-16"
  String get dateText {
    try {
      return examTime.split(' ').first;
    } catch (_) {
      return examTime;
    }
  }

  /// Short weekday name for the exam date.
  String get weekdayName {
    final start = startTime;
    if (start == null) return '';
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[start.weekday - 1];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamEntity &&
          runtimeType == other.runtimeType &&
          session == other.session &&
          courseCode == other.courseCode &&
          courseName == other.courseName &&
          examTime == other.examTime &&
          location == other.location &&
          seatNumber == other.seatNumber;

  @override
  int get hashCode =>
      session.hashCode ^
      courseCode.hashCode ^
      courseName.hashCode ^
      examTime.hashCode ^
      location.hashCode ^
      seatNumber.hashCode;
}
