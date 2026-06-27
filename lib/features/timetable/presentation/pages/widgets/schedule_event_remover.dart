import 'package:flutter/cupertino.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_helpers.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/course_occurrence.dart';
import 'package:li_curriculum_table/features/timetable/presentation/state/timetable_controller.dart';

/// Show a confirmation dialog and remove the schedule event.
Future<void> confirmRemoveScheduleEvent(
  BuildContext context,
  CourseOccurrence occurrence,
) async {
  final ds = sl<SettingsController>().designStyle.value;
  final confirmed = await showAdaptiveConfirmDialog(
    context,
    designStyle: ds,
    title: '删除日程',
    content: '确定删除「${occurrence.courseName}」吗？',
    confirmText: '删除',
    cancelText: '取消',
    isDestructive: true,
  );
  if (!confirmed || !context.mounted) return;
  final events = sl<TimetableController>().state.value.scheduleEvents;
  final match = events.where(
    (e) =>
        e.title == occurrence.courseName && e.location == occurrence.location,
  );
  if (match.isNotEmpty) {
    sl<TimetableController>().removeScheduleEvent(match.first.id);
    if (!context.mounted) return;
    showAdaptiveMessage(
      context,
      designStyle: ds,
      message: '已删除日程「${occurrence.courseName}」',
    );
  }
}
