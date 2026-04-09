import 'package:li_curriculum_table/features/timetable/domain/entities/teaching_week_baseline.dart';
import 'package:li_curriculum_table/features/timetable/data/datasources/secure_storage_store.dart';

class SecureTeachingWeekBaselineLocalDataSource {
  SecureTeachingWeekBaselineLocalDataSource(this._store);

  static const String _referenceDateKey =
      'timetable.teaching_week.reference_date';
  static const String _referenceWeekKey =
      'timetable.teaching_week.reference_week';

  final SecureStorageStore _store;

  Future<TeachingWeekBaseline?> readBaseline() async {
    final values = await _store.readAll([_referenceDateKey, _referenceWeekKey]);
    final dateValue = values[_referenceDateKey];
    final weekValue = values[_referenceWeekKey];
    if (dateValue == null || weekValue == null) {
      return null;
    }

    final date = DateTime.tryParse(dateValue);
    final week = int.tryParse(weekValue);
    if (date == null || week == null || week < 1) {
      return null;
    }

    return TeachingWeekBaseline(referenceDate: date, referenceWeek: week);
  }

  Future<void> saveBaseline(TeachingWeekBaseline baseline) async {
    final day = DateTime(
      baseline.referenceDate.year,
      baseline.referenceDate.month,
      baseline.referenceDate.day,
    );
    await _store.writeAll({
      _referenceDateKey: day.toIso8601String(),
      _referenceWeekKey: baseline.referenceWeek.toString(),
    });
  }

  Future<void> clearBaseline() async {
    await _store.deleteAll([_referenceDateKey, _referenceWeekKey]);
  }
}
