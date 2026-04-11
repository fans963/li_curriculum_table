import 'package:freezed_annotation/freezed_annotation.dart';

part 'teaching_week_baseline.freezed.dart';
part 'teaching_week_baseline.g.dart';

@freezed
abstract class TeachingWeekBaseline with _$TeachingWeekBaseline {
  const factory TeachingWeekBaseline({
    required DateTime referenceDate,
    required int referenceWeek,
  }) = _TeachingWeekBaseline;

  const TeachingWeekBaseline._();

  factory TeachingWeekBaseline.fromJson(Map<String, dynamic> json) =>
      _$TeachingWeekBaselineFromJson(json);

  bool get isValid => referenceWeek >= 1;
}
