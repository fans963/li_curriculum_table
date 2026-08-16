import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/course_occurrence.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/mark_online_sheet.dart';

/// Show the "Mark as Online" bottom sheet / modal for [occurrence].
void showMarkOnlineSheet(BuildContext context, CourseOccurrence occurrence) {
  final ds = sl<SettingsController>().designStyle.value;
  if (AdaptiveStyle.isCupertino(ds)) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => MarkOnlineSheet(occurrence: occurrence),
    );
  } else {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MarkOnlineSheet(occurrence: occurrence),
    );
  }
}
