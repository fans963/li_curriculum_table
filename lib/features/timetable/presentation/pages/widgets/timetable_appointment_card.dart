import 'package:animations/animations.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/course_format.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/course_color_service.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/course_online_service.dart';

import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/course_occurrence.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/timetable_appointment_cupertino.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/course_details_sheet.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/dashed_border_painter.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/schedule_event_remover.dart';

export 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/course_details_sheet.dart'
    show CourseDetailsSheet;
export 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/timetable_appointment_cupertino.dart'
    show CupertinoTone, resolveCupertinoTone;

/// Open the course details dialog for the given [occurrence].
/// Callable from both the card's internal tap handler and external callers
/// (e.g. a Listener wrapper that bypasses the gesture arena).
Future<void> openCourseDetails(
  BuildContext context,
  CourseOccurrence occurrence,
) async {
  final isOngoing =
      !DateTime.now().isBefore(occurrence.start) &&
      DateTime.now().isBefore(occurrence.end);
  final timeLine = _formatOccurrenceTimeRange(occurrence);
  final designStyle = sl<SettingsController>().state.value.designStyle;
  final customColor = sl<CourseColorService>().getColor(occurrence.courseName);
  final tone = resolveAppointmentTone(
    context,
    seedText: occurrence.courseName,
    customColor: customColor,
  );

  await _showDetailsDialog(
    context,
    occurrence,
    tone,
    isOngoing,
    timeLine,
    designStyle,
  );
  if (context.mounted) {
    FocusManager.instance.primaryFocus?.unfocus();
  }
}

Widget buildTimetableAppointmentCard({
  required BuildContext context,
  required CourseOccurrence occurrence,
  required DateTime now,
  VoidCallback? onTap,
}) {
  return _AnimatedAppointmentCard(
    occurrence: occurrence,
    now: now,
    onTap: onTap,
  );
}

class _AnimatedAppointmentCard extends StatelessWidget {
  final CourseOccurrence occurrence;
  final DateTime now;

  /// When non-null, the card is rendered without its own tap gesture detector.
  /// The caller is responsible for detecting taps (e.g. via a Listener wrapper)
  /// to bypass the gesture arena and get instant tap response.
  final VoidCallback? onTap;

  const _AnimatedAppointmentCard({
    required this.occurrence,
    required this.now,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOngoing =
        !now.isBefore(occurrence.start) && now.isBefore(occurrence.end);
    final title = occurrence.courseName;
    final timeLine = _formatOccurrenceTimeRange(occurrence);
    final designStyle = sl<SettingsController>().state.value.designStyle;
    final customColor = sl<CourseColorService>().getColor(title);
    final tone = resolveAppointmentTone(
      context,
      seedText: title,
      customColor: customColor,
    );

    // Check online status: manual override takes priority, then auto-detect
    // from location field (academic system uses "线上" for online courses).
    final onlineService = sl<CourseOnlineService>();
    final override = onlineService.getOverride(title);
    final isAutoOnline = occurrence.location.trim() == '线上';
    final isOnline = (override != null && override.isOnline) || isAutoOnline;
    final isLiveOnline =
        (override?.format == CourseFormat.liveOnline) ||
        (isAutoOnline && override?.format != CourseFormat.asyncOnline);

    // For online courses, show platform info instead of classroom.
    final locationLine = _buildLocationLine(occurrence, override);

    // Internal tap handler — used only when no external onTap is provided.
    void handleTap() => openCourseDetails(context, occurrence);

    // When onTap is externally provided (via Listener bypassing the gesture
    // arena), the card's own GestureDetector must NOT handle taps — otherwise
    // the callback fires twice. Only use the internal handler as fallback.
    final cardOnTap = onTap == null ? handleTap : null;

    if (AdaptiveStyle.isCupertino(designStyle)) {
      return buildCupertinoAppointmentCard(
        context: context,
        occurrence: occurrence,
        title: title,
        locationLine: locationLine,
        isOngoing: isOngoing,
        isOnline: isOnline,
        isLiveOnline: isLiveOnline,
        // When externally handled, provide a no-op — Cupertino requires non-null.
        onTap: cardOnTap ?? () {},
      );
    }
    return _buildMaterialCard(
      context,
      occurrence,
      title,
      locationLine,
      timeLine,
      isOngoing,
      tone,
      designStyle,
      isOnline: isOnline,
      isLiveOnline: isLiveOnline,
      onTap:
          cardOnTap, // null when externally handled — GestureDetector skips tap
    );
  }

  String _buildLocationLine(
    CourseOccurrence occurrence,
    CourseFormatOverride? override,
  ) {
    // Manual override: show platform + meeting ID
    if (override != null && override.isOnline) {
      final parts = <String>[];
      if (override.platform != null && override.platform!.isNotEmpty) {
        parts.add(override.platform!);
      }
      if (override.meetingId != null && override.meetingId!.isNotEmpty) {
        parts.add(override.meetingId!);
      }
      if (parts.isNotEmpty) return parts.join(' · ');
      return '🌐 线上课程';
    }
    // Auto-detected: academic system location field is "线上"
    if (occurrence.location.trim() == '线上') {
      return '🌐 线上课程';
    }
    return occurrence.location.trim();
  }

  Widget _buildMaterialCard(
    BuildContext context,
    CourseOccurrence occurrence,
    String title,
    String locationLine,
    String timeLine,
    bool isOngoing,
    AppointmentTone tone,
    DesignStyle designStyle, {
    VoidCallback? onTap,
    bool isOnline = false,
    bool isLiveOnline = false,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(1.5),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: occurrence.courseType == '日程'
            ? () => confirmRemoveScheduleEvent(context, occurrence)
            : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Dashed border overlay for live online courses
            if (isLiveOnline && !isOngoing)
              Positioned.fill(
                child: CustomPaint(
                  painter: DashedBorderPainter(
                    color: tone.accent.withValues(alpha: 0.6),
                    strokeWidth: 1.0,
                    borderRadius: 16,
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: isOngoing
                    ? Color.alphaBlend(
                        tone.accent.withValues(alpha: 0.08),
                        tone.background,
                      )
                    : tone.background,
                borderRadius: BorderRadius.circular(16),
                border: isLiveOnline && !isOngoing
                    ? null // dashed border drawn by CustomPaint above
                    : Border.all(
                        color: isOngoing
                            ? tone.accent.withValues(alpha: 0.4)
                            : tone.border,
                        width: isOngoing ? 1.0 : 0.5,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: tone.accent.withValues(
                      alpha: isOngoing ? 0.12 : 0.05,
                    ),
                    blurRadius: isOngoing ? 8 : 4,
                    offset: Offset(0, isOngoing ? 3 : 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      color: isOngoing
                          ? tone.accent
                          : tone.accent.withValues(alpha: 0.4),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Builder(
                              builder: (context) {
                                final s = sl<SettingsController>().state.value;
                                final baseStyle = Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: tone.foreground,
                                      fontWeight: FontWeight.w700,
                                      height: 1.2,
                                    );
                                if (s.autoSizeText) {
                                  return AutoSizeText(
                                    title,
                                    maxLines: s.timetableTextMaxLines,
                                    minFontSize: s.autoSizeMinFontSize,
                                    overflow: TextOverflow.ellipsis,
                                    style: baseStyle,
                                  );
                                }
                                return Text(
                                  title,
                                  maxLines: s.timetableTextMaxLines,
                                  overflow: TextOverflow.ellipsis,
                                  style: baseStyle?.copyWith(
                                    fontSize: s.timetableTextFontSize,
                                  ),
                                );
                              },
                            ),
                            if (locationLine.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Builder(
                                builder: (context) {
                                  final s =
                                      sl<SettingsController>().state.value;
                                  final locStyle = Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: cs.onSurfaceVariant.withValues(
                                          alpha: 0.6,
                                        ),
                                        fontWeight: FontWeight.w500,
                                        height: 1.15,
                                      );
                                  if (s.autoSizeText) {
                                    return AutoSizeText(
                                      locationLine,
                                      maxLines: s.timetableTextMaxLines,
                                      minFontSize: s.autoSizeMinFontSize,
                                      overflow: TextOverflow.ellipsis,
                                      style: locStyle,
                                    );
                                  }
                                  return Text(
                                    locationLine,
                                    maxLines: s.timetableTextMaxLines,
                                    overflow: TextOverflow.ellipsis,
                                    style: locStyle?.copyWith(
                                      fontSize: s.timetableTextFontSize - 2,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isOngoing)
              Positioned(
                top: -6,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: tone.accent.withValues(alpha: 0.20),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: cs.onPrimaryContainer,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '进行中',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showDetailsDialog(
  BuildContext context,
  CourseOccurrence occurrence,
  AppointmentTone tone,
  bool isOngoing,
  String timeLine,
  DesignStyle designStyle,
) {
  final sheet = CourseDetailsSheet(
    occurrence: occurrence,
    tone: tone,
    timeLine: timeLine,
    isOngoing: isOngoing,
    designStyle: designStyle,
    onClose: () => Navigator.of(context).pop(),
  );

  if (AdaptiveStyle.isCupertino(designStyle)) {
    return showCupertinoModalPopup(context: context, builder: (_) => sheet);
  }

  return Navigator.of(context).push(
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      pageBuilder: (context, animation, secondaryAnimation) => sheet,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeScaleTransition(animation: animation, child: child);
      },
    ),
  );
}

AppointmentTone resolveAppointmentTone(
  BuildContext context, {
  required String seedText,
  Color? customColor,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  // Resolve the accent color for this course.
  // Custom color: use directly. Default: pick from a high-contrast palette.
  final Color accent;
  if (customColor != null) {
    accent = customColor;
  } else {
    accent = _courseAccentFromPalette(seedText);
  }

  final hsl = HSLColor.fromColor(accent);

  if (isDark) {
    return AppointmentTone(
      background: HSLColor.fromAHSL(1.0, hsl.hue, 0.35, 0.16).toColor(),
      backgroundAlt: HSLColor.fromAHSL(1.0, hsl.hue, 0.30, 0.20).toColor(),
      foreground: HSLColor.fromAHSL(1.0, hsl.hue, 0.25, 0.88).toColor(),
      border: HSLColor.fromAHSL(1.0, hsl.hue, 0.25, 0.30).toColor(),
      accent: accent,
      shadow: accent.withValues(alpha: 0.3),
    );
  } else {
    return AppointmentTone(
      background: HSLColor.fromAHSL(1.0, hsl.hue, 0.40, 0.93).toColor(),
      backgroundAlt: HSLColor.fromAHSL(1.0, hsl.hue, 0.35, 0.90).toColor(),
      foreground: HSLColor.fromAHSL(1.0, hsl.hue, 0.45, 0.22).toColor(),
      border: HSLColor.fromAHSL(1.0, hsl.hue, 0.30, 0.78).toColor(),
      accent: accent,
      shadow: accent.withValues(alpha: 0.12),
    );
  }
}

/// 12 well-separated hues (30° apart) at high saturation for maximum
/// visual distinction between courses. Each course name is hashed to
/// pick one entry.
const _coursePalette = [
  Color(0xFFD32F2F), // red         0°
  Color(0xFFEF6C00), // orange     30°
  Color(0xFFF9A825), // amber      45°
  Color(0xFF558B2F), // green      90°
  Color(0xFF00897B), // teal      170°
  Color(0xFF0097A7), // cyan      185°
  Color(0xFF1565C0), // blue      215°
  Color(0xFF5E35B1), // deep purple 270°
  Color(0xFF8E24AA), // purple    290°
  Color(0xFFD81B60), // pink      340°
  Color(0xFF6D4C41), // brown      20°
  Color(0xFF546E7A), // blue grey 200°
];

Color _courseAccentFromPalette(String name) {
  int hash = 0;
  for (int i = 0; i < name.length; i++) {
    hash = name.codeUnitAt(i) + ((hash << 5) - hash);
  }
  return _coursePalette[hash.abs() % _coursePalette.length];
}

class AppointmentTone {
  const AppointmentTone({
    required this.background,
    required this.backgroundAlt,
    required this.foreground,
    required this.border,
    required this.accent,
    required this.shadow,
  });

  final Color background;
  final Color backgroundAlt;
  final Color foreground;
  final Color border;
  final Color accent;
  final Color shadow;
}

String _formatOccurrenceTimeRange(CourseOccurrence occurrence) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  final start =
      '${twoDigits(occurrence.start.hour)}:${twoDigits(occurrence.start.minute)}';
  final end =
      '${twoDigits(occurrence.end.hour)}:${twoDigits(occurrence.end.minute)}';
  return '$start-$end';
}

// _showMarkOnlineSheet → show_mark_online_sheet.dart
// _DashedBorderPainter + dashPath → dashed_border_painter.dart
