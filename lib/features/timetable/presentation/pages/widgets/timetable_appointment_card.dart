import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart' as sf;

Widget buildTimetableAppointmentCard({
  required BuildContext context,
  required sf.CalendarAppointmentDetails details,
  required DateTime now,
}) {
  final appointment = details.appointments.first as sf.Appointment;
  final isOngoing =
      !now.isBefore(appointment.startTime) && now.isBefore(appointment.endTime);
  final lines = appointment.subject
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
  final title = lines.isNotEmpty ? lines.first : '课程';
  final timeLine = lines.length > 1 ? lines[1] : '';
  final teacherLine = lines.length > 2 ? lines[2] : '';
  final locationLine = lines.length > 3 ? lines[3] : '';
  final tone = resolveAppointmentTone(
    Theme.of(context).colorScheme,
    seedText: title,
  );

  return Padding(
    padding: const EdgeInsets.all(1.5),
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
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
                    : tone.shadow,
                blurRadius: isOngoing ? 14 : 10,
                offset: isOngoing ? const Offset(0, 4) : const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
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
                  padding: const EdgeInsets.fromLTRB(9, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: tone.foreground,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                      if (timeLine.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          timeLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: tone.foreground.withValues(alpha: 0.92),
                                fontWeight: FontWeight.w600,
                                height: 1.15,
                              ),
                        ),
                      ],
                      if (teacherLine.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          teacherLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: tone.foreground.withValues(alpha: 0.84),
                                fontWeight: FontWeight.w500,
                                height: 1.15,
                              ),
                        ),
                      ],
                      if (locationLine.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          locationLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: tone.foreground.withValues(alpha: 0.84),
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: tone.foreground,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
      ],
    ),
  );
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
