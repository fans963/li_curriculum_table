import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/course_color_service.dart';

import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/course_occurrence.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/timetable_appointment_cupertino.dart';

export 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/timetable_appointment_cupertino.dart'
    show CourseDetailsSheet, CupertinoTone, resolveCupertinoTone;

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
  final tone = resolveAppointmentTone(context, seedText: occurrence.courseName, customColor: customColor);

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
    final locationLine = occurrence.location.trim();
    final designStyle = sl<SettingsController>().state.value.designStyle;
    final customColor = sl<CourseColorService>().getColor(title);
    final tone = resolveAppointmentTone(context, seedText: title, customColor: customColor);

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
      onTap: cardOnTap, // null when externally handled — GestureDetector skips tap
    );
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
            Container(
              decoration: BoxDecoration(
                color: isOngoing
                    ? Color.alphaBlend(
                        tone.accent.withValues(alpha: 0.08),
                        tone.background,
                      )
                    : tone.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isOngoing
                      ? tone.accent.withValues(alpha: 0.4)
                      : tone.border,
                  width: isOngoing ? 1.0 : 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: tone.accent.withValues(alpha: isOngoing ? 0.12 : 0.05),
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
                            Builder(builder: (context) {
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
                                style: baseStyle?.copyWith(fontSize: s.timetableTextFontSize),
                              );
                            }),
                            if (locationLine.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 10,
                                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Builder(builder: (context) {
                                      final s = sl<SettingsController>().state.value;
                                      final locStyle = Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
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
                                        style: locStyle?.copyWith(fontSize: s.timetableTextFontSize - 2),
                                      );
                                    }),
                                  ),
                                ],
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
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
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
  );

  if (AdaptiveStyle.isCupertino(designStyle)) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'course-detail',
      barrierColor: CupertinoColors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => sheet,
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final t = Curves.easeOutCubic.transform(animation.value);
        return Transform.scale(scale: 0.85 + 0.15 * t, child: Opacity(opacity: t, child: child));
      },
    );
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
  final cs = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  // Derive a per-course hue from the course name hash for visual variety,
  // or use the custom color's hue if overridden.
  final double courseHue;
  if (customColor != null) {
    courseHue = HSLColor.fromColor(customColor).hue;
  } else {
    int hash = 0;
    for (int i = 0; i < seedText.length; i++) {
      hash = seedText.codeUnitAt(i) + ((hash << 5) - hash);
    }
    courseHue = (hash.abs() % 360).toDouble();
  }

  Color tintSurface(Color base, double saturation, double lightness) {
    final baseHsl = HSLColor.fromColor(base);
    final tinted = HSLColor.fromAHSL(
      1.0,
      courseHue,
      (baseHsl.saturation + saturation).clamp(0.0, 1.0),
      (baseHsl.lightness + lightness).clamp(0.0, 1.0),
    ).toColor();
    return Color.alphaBlend(tinted.withValues(alpha: 0.35), base);
  }

  // Custom color: derive tones directly from the picked color, no blending with surface.
  if (customColor != null) {
    final hsl = HSLColor.fromColor(customColor);
    final accent = customColor;
    final bg = HSLColor.fromAHSL(1.0, hsl.hue, hsl.saturation * 0.7, isDark ? 0.20 : 0.92).toColor();
    final bgAlt = HSLColor.fromAHSL(1.0, hsl.hue, hsl.saturation * 0.6, isDark ? 0.24 : 0.88).toColor();
    final fg = HSLColor.fromAHSL(1.0, hsl.hue, hsl.saturation * 0.5, isDark ? 0.85 : 0.15).toColor();
    final border = HSLColor.fromAHSL(1.0, hsl.hue, hsl.saturation * 0.4, isDark ? 0.35 : 0.75).toColor();
    return AppointmentTone(
      background: bg,
      backgroundAlt: bgAlt,
      foreground: fg,
      border: border,
      accent: accent,
      shadow: accent.withValues(alpha: isDark ? 0.3 : 0.15),
    );
  }

  if (isDark) {
    return AppointmentTone(
      background: tintSurface(cs.surfaceContainerLow, 0.10, -0.04),
      backgroundAlt: tintSurface(cs.surfaceContainer, 0.10, -0.02),
      foreground: tintSurface(cs.onSurface, 0.20, 0.05),
      border: tintSurface(cs.outlineVariant, 0.08, 0.0),
      accent: tintSurface(cs.primary, 0.08, 0.0),
      shadow: Colors.black.withValues(alpha: 0.25),
    );
  } else {
    return AppointmentTone(
      background: tintSurface(cs.surfaceContainerLow, 0.10, 0.02),
      backgroundAlt: tintSurface(cs.surfaceContainerLow, 0.10, -0.01),
      foreground: tintSurface(cs.onSurface, 0.25, -0.10),
      border: tintSurface(cs.outlineVariant, 0.08, 0.04),
      accent: tintSurface(cs.primary, 0.05, -0.05),
      shadow: tintSurface(cs.primary, 0.05, -0.05).withValues(alpha: 0.08),
    );
  }
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
