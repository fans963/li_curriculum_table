class TeachingWeekBaseline {
  const TeachingWeekBaseline({
    required this.referenceDate,
    required this.referenceWeek,
  });

  final DateTime referenceDate;
  final int referenceWeek;

  bool get isValid => referenceWeek >= 1;
}
