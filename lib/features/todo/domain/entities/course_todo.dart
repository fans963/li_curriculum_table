class CourseTodo {
  final String id;
  final String title;
  final String? courseName;
  final DateTime deadline;
  final String? note;
  final bool isCompleted;
  final DateTime? completedAt;
  final int reminderMinutes;

  const CourseTodo({
    required this.id,
    required this.title,
    this.courseName,
    required this.deadline,
    this.note,
    this.isCompleted = false,
    this.completedAt,
    this.reminderMinutes = 120, // default 2 hours before
  });

  CourseTodo copyWith({
    String? id,
    String? title,
    String? courseName,
    DateTime? deadline,
    String? note,
    bool? isCompleted,
    DateTime? completedAt,
    int? reminderMinutes,
  }) {
    return CourseTodo(
      id: id ?? this.id,
      title: title ?? this.title,
      courseName: courseName ?? this.courseName,
      deadline: deadline ?? this.deadline,
      note: note ?? this.note,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'courseName': courseName,
        'deadline': deadline.toIso8601String(),
        'note': note,
        'isCompleted': isCompleted,
        'completedAt': completedAt?.toIso8601String(),
        'reminderMinutes': reminderMinutes,
      };

  factory CourseTodo.fromJson(Map<String, dynamic> json) {
    return CourseTodo(
      id: json['id'] as String,
      title: json['title'] as String,
      courseName: json['courseName'] as String?,
      deadline: DateTime.parse(json['deadline'] as String),
      note: json['note'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      reminderMinutes: json['reminderMinutes'] as int? ?? 120,
    );
  }

  /// Whether the deadline has passed while remaining uncompleted.
  bool get isOverdue => !isCompleted && DateTime.now().isAfter(deadline);

  /// Whether the deadline is today.
  bool get isDueToday {
    final now = DateTime.now();
    return deadline.year == now.year &&
        deadline.month == now.month &&
        deadline.day == now.day;
  }

  /// Human readable remaining time text.
  String get remainingTimeText {
    if (isCompleted) return '已完成';
    final now = DateTime.now();
    final diff = deadline.difference(now);
    if (diff.isNegative) {
      final past = now.difference(deadline);
      if (past.inDays > 0) return '已逾期 ${past.inDays} 天';
      if (past.inHours > 0) return '已逾期 ${past.inHours} 小时';
      return '已逾期 ${past.inMinutes} 分钟';
    }
    if (diff.inDays > 0) return '剩余 ${diff.inDays} 天';
    if (diff.inHours > 0) return '剩余 ${diff.inHours} 小时';
    if (diff.inMinutes > 0) return '剩余 ${diff.inMinutes} 分钟';
    return '即将截止';
  }
}
