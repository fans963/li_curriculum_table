import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/course_occurrence.dart';
import 'package:li_curriculum_table/util/util.dart';

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
  State<_AnimatedAppointmentCard> createState() => _AnimatedAppointmentCardState();
}

class _AnimatedAppointmentCardState extends State<_AnimatedAppointmentCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final occurrence = widget.occurrence;
    final now = widget.now;
    final isOngoing = !now.isBefore(occurrence.start) && now.isBefore(occurrence.end);
    final title = occurrence.courseName;
    final timeLine = _formatOccurrenceTimeRange(occurrence);
    final locationLine = occurrence.location.trim();
    final designStyle = ProviderScope.containerOf(context).read(settingsControllerProvider).designStyle;

    if (AdaptiveStyle.isCupertino(designStyle)) {
      return _buildCupertinoCard(context, occurrence, title, locationLine, timeLine, isOngoing, designStyle);
    }
    return _buildMaterialCard(context, occurrence, title, locationLine, timeLine, isOngoing);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Cupertino: flat iOS style
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCupertinoCard(
    BuildContext context,
    CourseOccurrence occurrence,
    String title,
    String locationLine,
    String timeLine,
    bool isOngoing,
    DesignStyle designStyle,
  ) {
    final cupertinoTone = _resolveCupertinoTone(context, title);
    final bgColor = isOngoing
        ? cupertinoTone.accent.withValues(alpha: 0.12)
        : cupertinoTone.background;
    final borderColor = isOngoing
        ? cupertinoTone.accent.withValues(alpha: 0.4)
        : CupertinoColors.separator.resolveFrom(context).withValues(alpha: 0.3);

    return Padding(
      padding: const EdgeInsets.all(1.5),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          final tone = resolveAppointmentTone(
            Theme.of(context).colorScheme,
            seedText: title,
          );
          _showDetailsBottomSheet(context, occurrence, tone, isOngoing, timeLine, designStyle);
        },
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 0.5),
            ),
            child: Row(
              children: [
                // Left accent bar — thin iOS style
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: cupertinoTone.accent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: cupertinoTone.foreground,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            if (isOngoing) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: cupertinoTone.accent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '进行中',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: CupertinoColors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (locationLine.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            locationLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: cupertinoTone.foreground.withValues(alpha: 0.65),
                              fontWeight: FontWeight.w400,
                              height: 1.2,
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
        ),
      ),
    );
  }

  /// iOS-style color tone — flat, using CupertinoColors.
  _CupertinoTone _resolveCupertinoTone(BuildContext context, String seedText) {
    final accentColors = [
      CupertinoColors.systemBlue,
      CupertinoColors.systemTeal,
      CupertinoColors.systemGreen,
      CupertinoColors.systemIndigo,
      CupertinoColors.systemPurple,
      CupertinoColors.systemPink,
      CupertinoColors.systemOrange,
      CupertinoColors.systemBrown,
    ];
    final accent = accentColors[seedText.hashCode.abs() % accentColors.length];
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return _CupertinoTone(
      accent: accent.resolveFrom(context),
      background: isDark
          ? CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context)
          : CupertinoColors.white,
      foreground: CupertinoColors.label.resolveFrom(context),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Material: gradient + shadow style
  // ═══════════════════════════════════════════════════════════════════════════

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
          final designStyle = ProviderScope.containerOf(context).read(settingsControllerProvider).designStyle;
          _showDetailsBottomSheet(context, occurrence, tone, isOngoing, timeLine, designStyle);
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
                        Color.alphaBlend(tone.accent.withValues(alpha: 0.14), tone.background)
                      else
                        tone.background,
                      if (isOngoing)
                        Color.alphaBlend(tone.accent.withValues(alpha: 0.08), tone.backgroundAlt)
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
                          : tone.shadow.withValues(alpha: _isPressed ? 0.05 : 0.08),
                      blurRadius: isOngoing ? 14 : (_isPressed ? 6 : 10),
                      offset: isOngoing ? const Offset(0, 4) : (_isPressed ? const Offset(0, 1) : const Offset(0, 3)),
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
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                  child: AnimatedOpacity(
                    duration: kDefaultAnimationDuration,
                    opacity: 1.0,
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
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _CourseDetailsSheet(
      occurrence: occurrence,
      tone: tone,
      timeLine: timeLine,
      isOngoing: isOngoing,
      designStyle: designStyle,
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

/// Simplified tone for Cupertino cards — flat, no gradients or heavy shadows.
class _CupertinoTone {
  const _CupertinoTone({
    required this.accent,
    required this.background,
    required this.foreground,
  });

  final Color accent;
  final Color background;
  final Color foreground;
}

String _formatOccurrenceTimeRange(CourseOccurrence occurrence) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  final start = '${twoDigits(occurrence.start.hour)}:${twoDigits(occurrence.start.minute)}';
  final end = '${twoDigits(occurrence.end.hour)}:${twoDigits(occurrence.end.minute)}';
  return '$start-$end';
}

class _CourseDetailsSheet extends StatelessWidget {
  final CourseOccurrence occurrence;
  final AppointmentTone tone;
  final String timeLine;
  final bool isOngoing;
  final DesignStyle designStyle;

  const _CourseDetailsSheet({
    required this.occurrence,
    required this.tone,
    required this.designStyle,
    required this.timeLine,
    required this.isOngoing,
  });

  @override
  Widget build(BuildContext context) {
    if (AdaptiveStyle.isCupertino(designStyle)) {
      return _buildCupertino(context);
    }
    return _buildMaterial(context);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Cupertino: iOS-style sheet
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCupertino(BuildContext context) {
    final accent = _cupertinoAccent(context);
    final bgColor = CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryLabel = CupertinoColors.secondaryLabel.resolveFrom(context);
    final separatorColor = CupertinoColors.separator.resolveFrom(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle — iOS standard
                  Center(
                    child: Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        color: separatorColor,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          occurrence.courseName,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: labelColor,
                            height: 1.2,
                          ),
                        ),
                      ),
                      if (isOngoing) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '进行中',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: CupertinoColors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Week info
                  Text(
                    occurrence.weekText,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Divider
                  Container(
                    height: 0.5,
                    color: separatorColor,
                  ),
                  const SizedBox(height: 16),
                  // Info rows — iOS style
                  _buildCupertinoInfoRow(context, CupertinoIcons.clock, '时间', timeLine, accent, secondaryLabel),
                  _buildCupertinoInfoRow(context, CupertinoIcons.location, '地点', occurrence.location, accent, secondaryLabel),
                  _buildCupertinoInfoRow(context, CupertinoIcons.person, '教师', occurrence.teacher, accent, secondaryLabel),
                  _buildCupertinoInfoRow(
                    context,
                    CupertinoIcons.book,
                    '其他信息',
                    '${occurrence.courseType} ${occurrence.credit.isNotEmpty ? '· ${occurrence.credit}学分' : ''}',
                    accent,
                    secondaryLabel,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCupertinoInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color iconColor,
    Color secondaryLabel,
  ) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryLabel,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _cupertinoAccent(BuildContext context) {
    final colors = [
      CupertinoColors.systemBlue,
      CupertinoColors.systemTeal,
      CupertinoColors.systemGreen,
      CupertinoColors.systemIndigo,
      CupertinoColors.systemPurple,
      CupertinoColors.systemPink,
      CupertinoColors.systemOrange,
      CupertinoColors.systemBrown,
    ];
    return colors[occurrence.courseName.hashCode.abs() % colors.length].resolveFrom(context);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Material: original style
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMaterial(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          occurrence.courseName,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ),
                      if (isOngoing) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: tone.accent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '进行中',
                            style: textTheme.labelSmall?.copyWith(
                              color: tone.foreground,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    occurrence.weekText,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildMaterialInfoRow(context, AppIcons.time(designStyle), '时间', timeLine, tone.accent),
                  _buildMaterialInfoRow(context, AppIcons.location(designStyle), '地点', occurrence.location, tone.accent),
                  _buildMaterialInfoRow(context, AppIcons.person(designStyle), '教师', occurrence.teacher, tone.accent),
                  _buildMaterialInfoRow(context, AppIcons.school(designStyle), '其他信息', '${occurrence.courseType} ${occurrence.credit.isNotEmpty ? '· ${occurrence.credit}学分' : ''}', tone.accent),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMaterialInfoRow(BuildContext context, IconData icon, String label, String value, Color iconColor) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
