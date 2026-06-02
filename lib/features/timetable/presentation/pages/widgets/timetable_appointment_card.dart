import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/course_occurrence.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/timetable_appointment_cupertino.dart';
import 'package:li_curriculum_table/util/util.dart';

export 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/timetable_appointment_cupertino.dart'
    show CourseDetailsSheet, CupertinoTone, resolveCupertinoTone;

Widget buildTimetableAppointmentCard({
  required BuildContext context,
  required CourseOccurrence occurrence,
  required DateTime now,
}) {
  return _AnimatedAppointmentCard(
    occurrence: occurrence,
    now: now,
  );
}

class _AnimatedAppointmentCard extends StatefulWidget {
  final CourseOccurrence occurrence;
  final DateTime now;

  const _AnimatedAppointmentCard({
    required this.occurrence,
    required this.now,
  });

  @override
  State<_AnimatedAppointmentCard> createState() =>
      _AnimatedAppointmentCardState();
}

class _AnimatedAppointmentCardState extends State<_AnimatedAppointmentCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final occurrence = widget.occurrence;
    final now = widget.now;
    final isOngoing =
        !now.isBefore(occurrence.start) && now.isBefore(occurrence.end);
    final title = occurrence.courseName;
    final timeLine = _formatOccurrenceTimeRange(occurrence);
    final locationLine = occurrence.location.trim();
    final designStyle = sl<SettingsController>().state.value.designStyle;

    if (AdaptiveStyle.isCupertino(designStyle)) {
      return buildCupertinoAppointmentCard(
        context: context,
        occurrence: occurrence,
        title: title,
        locationLine: locationLine,
        isOngoing: isOngoing,
        onTap: () {
          final tone = resolveAppointmentTone(
            Theme.of(context).colorScheme,
            seedText: title,
          );
          _showDetailsBottomSheet(
            context,
            occurrence,
            tone,
            isOngoing,
            timeLine,
            designStyle,
          );
        },
      );
    }
    return _buildMaterialCard(
      context,
      occurrence,
      title,
      locationLine,
      timeLine,
      isOngoing,
    );
  }

  Widget _buildMaterialCard(
    BuildContext context,
    CourseOccurrence occurrence,
    String title,
    String locationLine,
    String timeLine,
    bool isOngoing,
  ) {
    final tone = resolveAppointmentTone(
      Theme.of(context).colorScheme,
      seedText: title,
    );

    return Padding(
      padding: const EdgeInsets.all(1.5),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          final designStyle = sl<SettingsController>().state.value.designStyle;
          _showDetailsBottomSheet(
            context,
            occurrence,
            tone,
            isOngoing,
            timeLine,
            designStyle,
          );
        },
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: kDefaultAnimationDuration,
                curve: kDefaultAnimationCurve,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      if (isOngoing)
                        Color.alphaBlend(
                          tone.accent.withValues(alpha: 0.14),
                          tone.background,
                        )
                      else
                        tone.background,
                      if (isOngoing)
                        Color.alphaBlend(
                          tone.accent.withValues(alpha: 0.08),
                          tone.backgroundAlt,
                        )
                      else
                        tone.backgroundAlt,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isOngoing ? tone.accent : tone.border,
                    width: isOngoing ? 1.4 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isOngoing
                          ? tone.accent.withValues(alpha: 0.22)
                          : tone.shadow.withValues(
                              alpha: _isPressed ? 0.05 : 0.08,
                            ),
                      blurRadius: isOngoing ? 14 : (_isPressed ? 6 : 10),
                      offset: isOngoing
                          ? const Offset(0, 4)
                          : (_isPressed
                              ? const Offset(0, 1)
                              : const Offset(0, 3)),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: kDefaultAnimationDuration,
                      curve: kDefaultAnimationCurve,
                      width: isOngoing ? 5 : 4,
                      decoration: BoxDecoration(
                        color: tone.accent,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AutoSizeText(
                              title,
                              maxLines: 2,
                              minFontSize: 8,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: tone.foreground,
                                    fontWeight: FontWeight.w700,
                                    height: 1.15,
                                  ),
                            ),
                            if (locationLine.isNotEmpty) ...[
                              const SizedBox(height: 1),
                              AutoSizeText(
                                locationLine,
                                maxLines: 1,
                                minFontSize: 8,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: tone.foreground.withValues(
                                        alpha: 0.84,
                                      ),
                                      fontWeight: FontWeight.w500,
                                      height: 1.15,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isOngoing)
                Positioned(
                  top: -7,
                  right: 6,
                  child: AnimatedOpacity(
                    duration: kDefaultAnimationDuration,
                    opacity: 1.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: tone.accent,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: tone.accent.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '进行中',
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: tone.foreground,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showDetailsBottomSheet(
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
    showCupertinoModalPopup(context: context, builder: (_) => sheet);
  } else {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => sheet,
    );
  }
}

AppointmentTone resolveAppointmentTone(
  ColorScheme scheme, {
  required String seedText,
}) {
  final baseSurface = scheme.surfaceContainerHighest;
  final shadowBase = scheme.shadow;

  Color tint(Color tintColor, double alpha) {
    return Color.alphaBlend(tintColor.withValues(alpha: alpha), baseSurface);
  }

  final tones = <AppointmentTone>[
    AppointmentTone(
      background: tint(scheme.primary, 0.16),
      backgroundAlt: tint(scheme.primaryContainer, 0.26),
      foreground: scheme.onPrimaryContainer,
      border: scheme.primary.withValues(alpha: 0.36),
      accent: scheme.primary,
      shadow: shadowBase.withValues(alpha: 0.08),
    ),
    AppointmentTone(
      background: tint(scheme.secondary, 0.16),
      backgroundAlt: tint(scheme.secondaryContainer, 0.26),
      foreground: scheme.onSecondaryContainer,
      border: scheme.secondary.withValues(alpha: 0.36),
      accent: scheme.secondary,
      shadow: shadowBase.withValues(alpha: 0.08),
    ),
    AppointmentTone(
      background: tint(scheme.tertiary, 0.15),
      backgroundAlt: tint(scheme.tertiaryContainer, 0.24),
      foreground: scheme.onTertiaryContainer,
      border: scheme.tertiary.withValues(alpha: 0.34),
      accent: scheme.tertiary,
      shadow: shadowBase.withValues(alpha: 0.08),
    ),
    AppointmentTone(
      background: tint(scheme.error, 0.12),
      backgroundAlt: tint(scheme.errorContainer, 0.2),
      foreground: scheme.onSurface,
      border: scheme.error.withValues(alpha: 0.26),
      accent: scheme.error,
      shadow: shadowBase.withValues(alpha: 0.08),
    ),
    AppointmentTone(
      background: tint(scheme.primary, 0.08),
      backgroundAlt: tint(scheme.surfaceTint, 0.12),
      foreground: scheme.onSurface,
      border: scheme.outlineVariant,
      accent: scheme.outline,
      shadow: shadowBase.withValues(alpha: 0.06),
    ),
  ];

  final index = seedText.hashCode.abs() % tones.length;
  return tones[index];
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
