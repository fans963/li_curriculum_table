import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_helpers.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/presentation/glass_dialog.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/timetable/presentation/state/timetable_controller.dart';
import 'package:m3e_core/m3e_core.dart';

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
      ? tone.accent.withValues(alpha: 0.15)
      : tone.background;
  final borderColor = isOngoing
      ? tone.accent.withValues(alpha: 0.4)
      : CupertinoColors.separator.resolveFrom(context).withValues(alpha: 0.2);

  return Padding(
    padding: const EdgeInsets.all(2.0),
    child: GestureDetector(
      onTap: onTap,
      onLongPress: occurrence.courseType == '日程'
          ? () => confirmRemoveScheduleEvent(context, occurrence)
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: _CardContent(
                  title: title,
                  locationLine: locationLine,
                  isOngoing: isOngoing,
                  tone: tone,
                ),
              ),
            ),
          ],
        ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: sl<SettingsController>().autoSizeText.value
                ? AutoSizeText(
                    title,
                    maxLines: 2,
                    minFontSize: 8,
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tone.foreground,
                      letterSpacing: -0.2,
                      height: 1.15,
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
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(
                CupertinoIcons.location,
                size: 10,
                color: tone.foreground.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: sl<SettingsController>().autoSizeText.value
                  ? AutoSizeText(
                      locationLine,
                      maxLines: 2,
                      minFontSize: 7,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: tone.foreground.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.1,
                        height: 1.2,
                      ),
                    ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

CupertinoTone resolveCupertinoTone(BuildContext context, String seedText) {
  final tone = resolveAppointmentTone(context, seedText: seedText);
  return CupertinoTone(
    accent: tone.accent,
    background: tone.background,
    foreground: tone.foreground,
  );
}

Widget _ongoingBadge(Color accent, {double fontSize = 11, double hPad = 7, double vPad = 3, Color? foreground}) {
  final fg = foreground ?? CupertinoColors.white;
  return Container(
    padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
    decoration: BoxDecoration(
      color: accent,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: fg,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text('进行中', style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: fg,
        )),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// Course Details Sheet
// ═══════════════════════════════════════════════════════════════════════════

class CourseDetailsSheet extends StatelessWidget {
  final CourseOccurrence occurrence;
  final AppointmentTone tone;
  final String timeLine;
  final bool isOngoing;
  final DesignStyle designStyle;
  final VoidCallback? onClose;

  const CourseDetailsSheet({
    super.key,
    required this.occurrence,
    required this.tone,
    required this.designStyle,
    required this.timeLine,
    required this.isOngoing,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (AdaptiveStyle.isCupertino(designStyle)) return _buildCupertino(context);
    return _buildMaterial(context);
  }

  // ── Cupertino ──────────────────────────────────────────────────────────

  Widget _buildCupertino(BuildContext context) {
    final accent = resolveCupertinoTone(context, occurrence.courseName).accent;
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final sep = CupertinoColors.separator.resolveFrom(context);
    final otherInfo = '${occurrence.courseType}'
        '${occurrence.credit.isNotEmpty ? ' · ${occurrence.credit}学分' : ''}';

    return GlassDialog(
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 32),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(occurrence.courseName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: -0.5))),
                      if (isOngoing) ...[const SizedBox(width: 8), _ongoingBadge(accent, fontSize: 11, hPad: 7, vPad: 3)],
                    ],
                  ),
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
              ],
            ),
          ),
          if (onClose != null)
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: onClose,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.xmark,
                    size: 16,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Material ───────────────────────────────────────────────────────────

  Widget _buildMaterial(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final otherInfo = '${occurrence.courseType}'
        '${occurrence.credit.isNotEmpty ? ' · ${occurrence.credit}学分' : ''}';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(36),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(occurrence.courseName,
                        style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.bold, height: 1.15, letterSpacing: -0.5))),
                      if (isOngoing) ...[const SizedBox(width: 8), _ongoingBadge(cs.primaryContainer, foreground: cs.onPrimaryContainer)],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(occurrence.weekText, style: tt.titleMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 28),
                  _infoRow(context, AppIcons.time(designStyle), '时间', timeLine, tone.accent, null, isMaterial: true),
                  _infoRow(context, AppIcons.location(designStyle), '地点', occurrence.location, tone.accent, null, isMaterial: true),
                  _infoRow(context, AppIcons.person(designStyle), '教师', occurrence.teacher, tone.accent, null, isMaterial: true),
                  _infoRow(context, AppIcons.school(designStyle), '其他信息', otherInfo, tone.accent, null, isMaterial: true),
                  if (onClose != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          M3EFilledButton(
                            onPressed: onClose ?? () {},
                            size: M3EButtonSize.md,
                            shape: M3EButtonShape.round,
                            child: const Text('关闭'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String label, String value, Color iconColor, Color? secondaryLabel, {bool isMaterial = false}) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    final labelStyle = isMaterial
        ? Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)
        : TextStyle(fontSize: 13, color: secondaryLabel, fontWeight: FontWeight.w500);
    final valueStyle = isMaterial
        ? Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)
        : TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: CupertinoColors.label.resolveFrom(context));
    final iconSize = isMaterial ? 22.0 : 18.0;
    final bgAlpha = isMaterial ? 0.20 : 0.12;
    final gap = isMaterial ? 2.0 : 1.0;
    final bottom = isMaterial ? 18.0 : 14.0;
    final iconBg = BoxDecoration(
      color: iconColor.withValues(alpha: bgAlpha),
      borderRadius: BorderRadius.circular(isMaterial ? 16 : 8),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: isMaterial ? 44.0 : 34.0,
            height: isMaterial ? 44.0 : 34.0,
            alignment: Alignment.center,
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

/// Show a confirmation dialog and remove the schedule event.
Future<void> confirmRemoveScheduleEvent(
    BuildContext context, CourseOccurrence occurrence) async {
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
  final match = events.where((e) =>
      e.title == occurrence.courseName &&
      e.location == occurrence.location);
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
