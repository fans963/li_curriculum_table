import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/course_occurrence.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/course_color_service.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/schedule_event_remover.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/mark_online_sheet.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/ongoing_badge.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/timetable_appointment_card.dart';

class CupertinoTone {
  const CupertinoTone({
    required this.accent,
    required this.background,
    required this.foreground,
  });
  final Color accent;
  final Color background;
  final Color foreground;
}

Widget buildCupertinoAppointmentCard({
  required BuildContext context,
  required CourseOccurrence occurrence,
  required String title,
  required String locationLine,
  required bool isOngoing,
  required VoidCallback onTap,
  bool isOnline = false,
  bool isLiveOnline = false,
}) {
  final customColor = sl<CourseColorService>().getColor(title);
  final tone = resolveCupertinoTone(context, title, customColor: customColor);
  final bgColor = isOngoing
      ? tone.accent.withValues(alpha: 0.15)
      : tone.background;
  final borderColor = isOngoing
      ? tone.accent.withValues(alpha: 0.4)
      : isLiveOnline
      ? tone.accent.withValues(alpha: 0.5)
      : CupertinoColors.separator.resolveFrom(context).withValues(alpha: 0.2);

  // Show 🌐 indicator for online courses
  final displayLocation = isOnline ? '🌐 $locationLine' : locationLine;

  return Padding(
    padding: const EdgeInsets.all(2.0),
    child: GestureDetector(
      onTap: onTap,
      onLongPress: occurrence.courseType == '日程'
          ? () => confirmRemoveScheduleEvent(context, occurrence)
          : () => _showMarkOnlineSheetCupertino(context, occurrence),
      child: Stack(
        children: [
          // Dashed border overlay for live online courses
          if (isLiveOnline && !isOngoing)
            Positioned.fill(
              child: CustomPaint(
                painter: _buildCupertinoDashedPainter(
                  tone.accent.withValues(alpha: 0.5),
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: isLiveOnline && !isOngoing
                  ? null
                  : Border.all(color: borderColor, width: 0.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                Container(
                  width: 3.5,
                  color: isOngoing
                      ? tone.accent
                      : tone.accent.withValues(alpha: 0.5),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: _CardContent(
                      title: title,
                      locationLine: displayLocation,
                      isOngoing: isOngoing,
                      tone: tone,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Card inner content — extracted to reduce nesting depth.
class _CardContent extends StatelessWidget {
  final String title;
  final String locationLine;
  final bool isOngoing;
  final CupertinoTone tone;

  const _CardContent({
    required this.title,
    required this.locationLine,
    required this.isOngoing,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final s = sl<SettingsController>().state.value;
    final maxLines = s.timetableTextMaxLines;
    final minFontSize = s.autoSizeMinFontSize;
    final fontSize = s.timetableTextFontSize;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: s.autoSizeText
                  ? AutoSizeText(
                      title,
                      maxLines: maxLines,
                      minFontSize: minFontSize,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: tone.foreground,
                        letterSpacing: -0.2,
                        height: 1.15,
                      ),
                    )
                  : Text(
                      title,
                      maxLines: maxLines,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: tone.foreground,
                        letterSpacing: -0.2,
                        height: 1.15,
                      ),
                    ),
            ),
            if (isOngoing) ...[
              const SizedBox(width: 6),
              ongoingBadge(tone.accent, fontSize: 9, hPad: 5, vPad: 1.5),
            ],
          ],
        ),
        if (locationLine.isNotEmpty) ...[
          const SizedBox(height: 2),
          s.autoSizeText
              ? AutoSizeText(
                  locationLine,
                  maxLines: maxLines,
                  minFontSize: minFontSize,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: tone.foreground.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.1,
                    height: 1.2,
                  ),
                )
              : Text(
                  locationLine,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: fontSize - 2,
                    color: tone.foreground.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.1,
                    height: 1.2,
                  ),
                ),
        ],
      ],
    );
  }
}

CupertinoTone resolveCupertinoTone(
  BuildContext context,
  String seedText, {
  Color? customColor,
}) {
  final tone = resolveAppointmentTone(
    context,
    seedText: seedText,
    customColor: customColor,
  );
  return CupertinoTone(
    accent: tone.accent,
    background: tone.background,
    foreground: tone.foreground,
  );
}

// _ongoingBadge extracted to ongoing_badge.dart
// CourseDetailsSheet extracted to course_details_sheet.dart
// confirmRemoveScheduleEvent extracted to course_details_sheet.dart

// ─── Mark as Online (Cupertino) ─────────────────────────────────────────

void _showMarkOnlineSheetCupertino(
  BuildContext context,
  CourseOccurrence occurrence,
) {
  showCupertinoModalPopup(
    context: context,
    builder: (_) => MarkOnlineSheet(occurrence: occurrence),
  );
}

// ─── Cupertino Dashed Border Painter ────────────────────────────────────

_CupertinoDashedBorderPainter _buildCupertinoDashedPainter(Color color) {
  return _CupertinoDashedBorderPainter(color: color);
}

class _CupertinoDashedBorderPainter extends CustomPainter {
  final Color color;
  const _CupertinoDashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(8),
    );

    final path = Path()..addRRect(rrect);
    canvas.drawPath(_dashPath(path, dashWidth: 5, dashGap: 3), paint);
  }

  Path _dashPath(
    Path source, {
    required double dashWidth,
    required double dashGap,
  }) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final len = draw ? dashWidth : dashGap;
        final end = (distance + len).clamp(0.0, metric.length).toDouble();
        if (draw) dest.addPath(metric.extractPath(distance, end), Offset.zero);
        distance += len;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant _CupertinoDashedBorderPainter oldDelegate) =>
      false;
}
