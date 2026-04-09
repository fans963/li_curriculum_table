int inferTeachingWeekFromBaseline({
  required DateTime referenceDate,
  required int referenceWeek,
  DateTime? today,
}) {
  final safeReferenceWeek = referenceWeek < 1 ? 1 : referenceWeek;
  final now = today ?? DateTime.now();

  final referenceDay = DateTime(
    referenceDate.year,
    referenceDate.month,
    referenceDate.day,
  );
  final targetDay = DateTime(now.year, now.month, now.day);

  final dayDelta = targetDay.difference(referenceDay).inDays;
  final weekDelta = dayDelta ~/ 7;
  final inferred = safeReferenceWeek + weekDelta;
  return inferred < 1 ? 1 : inferred;
}
