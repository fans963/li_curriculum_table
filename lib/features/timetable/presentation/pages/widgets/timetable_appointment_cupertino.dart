import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/course_occurrence.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/timetable_appointment_card.dart';

class CupertinoTone {
  const CupertinoTone({required this.accent, required this.background, required this.foreground});
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
}) {
  final tone = resolveCupertinoTone(context, title);
  final bgColor = isOngoing
      ? tone.accent.withValues(alpha: 0.12)
      : tone.background;
  final borderColor = isOngoing
      ? tone.accent.withValues(alpha: 0.4)
      : CupertinoColors.separator.resolveFrom(context).withValues(alpha: 0.3);

  return Padding(
    padding: const EdgeInsets.all(1.5),
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 3,
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
                              color: tone.foreground,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (isOngoing) ...[
                          const SizedBox(width: 6),
                          _ongoingBadge(tone.accent, fontSize: 9, hPad: 5, vPad: 1.5),
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
                          color: tone.foreground.withValues(alpha: 0.65),
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
  );
}

CupertinoTone resolveCupertinoTone(BuildContext context, String seedText) {
  const colors = [
    CupertinoColors.systemBlue,
    CupertinoColors.systemTeal,
    CupertinoColors.systemGreen,
    CupertinoColors.systemIndigo,
    CupertinoColors.systemPurple,
    CupertinoColors.systemPink,
    CupertinoColors.systemOrange,
    CupertinoColors.systemBrown,
  ];
  final accent = colors[seedText.hashCode.abs() % colors.length];
  return CupertinoTone(
    accent: accent.resolveFrom(context),
    background: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
    foreground: CupertinoColors.label.resolveFrom(context),
  );
}

Widget _ongoingBadge(Color accent, {double fontSize = 11, double hPad = 8, double vPad = 4, Color? foreground}) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
    decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(4)),
    child: Text('进行中', style: TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: foreground ?? CupertinoColors.white,
    )),
  );
}

class CourseDetailsSheet extends StatelessWidget {
  final CourseOccurrence occurrence;
  final AppointmentTone tone;
  final String timeLine;
  final bool isOngoing;
  final DesignStyle designStyle;

  const CourseDetailsSheet({
    super.key,
    required this.occurrence,
    required this.tone,
    required this.designStyle,
    required this.timeLine,
    required this.isOngoing,
  });

  @override
  Widget build(BuildContext context) {
    if (AdaptiveStyle.isCupertino(designStyle)) return _buildCupertino(context);
    return _buildMaterial(context);
  }

  Widget _buildSheet({
    required Color bgColor,
    required double topRadius,
    required double hPad,
    required Widget handle,
    required List<Widget> children,
  }) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(topRadius)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 32),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [handle, ...children],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Cupertino ──────────────────────────────────────────────────────────

  Widget _buildCupertino(BuildContext context) {
    final accent = resolveCupertinoTone(context, occurrence.courseName).accent;
    final bg = CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);
    final label = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final sep = CupertinoColors.separator.resolveFrom(context);
    final otherInfo = '${occurrence.courseType}'
        '${occurrence.credit.isNotEmpty ? ' · ${occurrence.credit}学分' : ''}';

    return _buildSheet(
      bgColor: bg,
      topRadius: 18,
      hPad: 20,
      handle: Center(
        child: Container(
          width: 36, height: 5,
          decoration: BoxDecoration(color: sep, borderRadius: BorderRadius.circular(2.5)),
        ),
      ),
      children: [
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(occurrence.courseName,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: label, height: 1.2))),
            if (isOngoing) ...[const SizedBox(width: 8), _ongoingBadge(accent, fontSize: 11, hPad: 7, vPad: 3)],
          ],
        ),
        const SizedBox(height: 6),
        Text(occurrence.weekText, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: accent)),
        const SizedBox(height: 20),
        Container(height: 0.5, color: sep),
        const SizedBox(height: 16),
        _infoRow(context, CupertinoIcons.clock, '时间', timeLine, accent, secondary),
        _infoRow(context, CupertinoIcons.location, '地点', occurrence.location, accent, secondary),
        _infoRow(context, CupertinoIcons.person, '教师', occurrence.teacher, accent, secondary),
        _infoRow(context, CupertinoIcons.book, '其他信息', otherInfo, accent, secondary),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Material ───────────────────────────────────────────────────────────

  Widget _buildMaterial(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final otherInfo = '${occurrence.courseType}'
        '${occurrence.credit.isNotEmpty ? ' · ${occurrence.credit}学分' : ''}';

    return _buildSheet(
      bgColor: cs.surface,
      topRadius: 28,
      hPad: 24,
      handle: Center(
        child: Container(
          width: 32, height: 4,
          decoration: BoxDecoration(
            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
      children: [
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(occurrence.courseName,
              style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold, height: 1.2))),
            if (isOngoing) ...[const SizedBox(width: 8), _ongoingBadge(tone.accent, foreground: tone.foreground)],
          ],
        ),
        const SizedBox(height: 8),
        Text(occurrence.weekText, style: tt.bodyMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 24),
        _infoRow(context, AppIcons.time(designStyle), '时间', timeLine, tone.accent, null, isMaterial: true),
        _infoRow(context, AppIcons.location(designStyle), '地点', occurrence.location, tone.accent, null, isMaterial: true),
        _infoRow(context, AppIcons.person(designStyle), '教师', occurrence.teacher, tone.accent, null, isMaterial: true),
        _infoRow(context, AppIcons.school(designStyle), '其他信息', otherInfo, tone.accent, null, isMaterial: true),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String label, String value, Color iconColor, Color? secondaryLabel, {bool isMaterial = false}) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    final labelStyle = isMaterial
        ? Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)
        : TextStyle(fontSize: 12, color: secondaryLabel);
    final valueStyle = isMaterial
        ? Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)
        : const TextStyle(fontSize: 16, fontWeight: FontWeight.w400);
    final iconSize = isMaterial ? 20.0 : 17.0;
    final bgAlpha = isMaterial ? 0.15 : 0.12;
    final gap = isMaterial ? 2.0 : 1.0;
    final bottom = isMaterial ? 16.0 : 14.0;
    final iconBg = isMaterial
        ? BoxDecoration(color: iconColor.withValues(alpha: bgAlpha), shape: BoxShape.circle)
        : BoxDecoration(color: iconColor.withValues(alpha: bgAlpha), borderRadius: BorderRadius.circular(8));
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: isMaterial ? null : 32.0,
            height: isMaterial ? null : 32.0,
            padding: isMaterial ? const EdgeInsets.all(8) : null,
            decoration: iconBg,
            child: Icon(icon, size: iconSize, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: labelStyle),
                SizedBox(height: gap),
                Text(value, style: valueStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
