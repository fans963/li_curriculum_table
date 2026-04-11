import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:li_curriculum_table/core/rust/crawler/model.dart' as rust_model;

part 'time_slot.freezed.dart';
part 'time_slot.g.dart';

@freezed
abstract class TimeSlot with _$TimeSlot {
  const factory TimeSlot({
    required int weekday,
    required int startSection,
    required int endSection,
    required int startWeek,
    required int endWeek,
    required String weekText,
  }) = _TimeSlot;

  factory TimeSlot.fromRust(rust_model.TimeSlot slot) {
    return TimeSlot(
      weekday: slot.weekday,
      startSection: slot.startSection,
      endSection: slot.endSection,
      startWeek: slot.startWeek,
      endWeek: slot.endWeek,
      weekText: slot.weekText,
    );
  }

  factory TimeSlot.fromJson(Map<String, dynamic> json) =>
      _$TimeSlotFromJson(json);
}
