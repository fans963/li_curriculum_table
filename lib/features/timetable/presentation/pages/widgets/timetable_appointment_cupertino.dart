import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_helpers.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/timetable/presentation/state/timetable_controller.dart';
import 'package:m3e_core/m3e_core.dart';

import 'package:li_curriculum_table/features/timetable/domain/entities/course_occurrence.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/course_color_service.dart';
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
  final customColor = sl<CourseColorService>().getColor(title);
  final tone = resolveCupertinoTone(context, title, customColor: customColor);
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
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 0.5),
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
              _ongoingBadge(tone.accent, fontSize: 9, hPad: 5, vPad: 1.5),
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

CupertinoTone resolveCupertinoTone(BuildContext context, String seedText, {Color? customColor}) {
  final tone = resolveAppointmentTone(context, seedText: seedText, customColor: customColor);
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
    final customColor = sl<CourseColorService>().getColor(occurrence.courseName);
    final accent = resolveCupertinoTone(context, occurrence.courseName, customColor: customColor).accent;
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final sep = CupertinoColors.separator.resolveFrom(context);
    final otherInfo = '${occurrence.courseType}'
        '${occurrence.credit.isNotEmpty ? ' · ${occurrence.credit}学分' : ''}';

    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final viewPadding = MediaQuery.of(context).padding.bottom;

    final List<Widget> detailRows = [];
    if (timeLine.trim().isNotEmpty) {
      detailRows.add(_buildCupertinoInfoRow(context, icon: CupertinoIcons.clock, label: '时间', value: timeLine, iconColor: accent, secondaryColor: secondary));
    }
    if (occurrence.location.trim().isNotEmpty) {
      if (detailRows.isNotEmpty) detailRows.add(_buildIOSDivider(context));
      detailRows.add(_buildCupertinoInfoRow(context, icon: CupertinoIcons.location, label: '地点', value: occurrence.location, iconColor: accent, secondaryColor: secondary));
    }
    if (occurrence.teacher.trim().isNotEmpty) {
      if (detailRows.isNotEmpty) detailRows.add(_buildIOSDivider(context));
      detailRows.add(_buildCupertinoInfoRow(context, icon: CupertinoIcons.person, label: '教师', value: occurrence.teacher, iconColor: accent, secondaryColor: secondary));
    }
    if (otherInfo.trim().isNotEmpty) {
      if (detailRows.isNotEmpty) detailRows.add(_buildIOSDivider(context));
      detailRows.add(_buildCupertinoInfoRow(context, icon: CupertinoIcons.info_circle, label: '其他信息', value: otherInfo, iconColor: accent, secondaryColor: secondary));
    }

    return CupertinoTheme(
      data: CupertinoTheme.of(context),
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.70,
          decoration: BoxDecoration(
            color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // iOS Drag Handle / Top Margin
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: CupertinoColors.inactiveGray.resolveFrom(context),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Title Action Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      occurrence.courseType == '日程' ? '日程详情' : '课程详情',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                    if (onClose != null)
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: onClose,
                        child: Text(
                          '完成',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.systemBlue.resolveFrom(context),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(height: 0.5, color: sep),

              // Scrollable Details
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding + viewPadding),
                  child: Column(
                    children: [
                      // Card 1: Title and WeekText
                      _buildIOSDetailsCard(
                        context,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        occurrence.courseName,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: CupertinoColors.label.resolveFrom(context),
                                          height: 1.2,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ),
                                    if (isOngoing) ...[
                                      const SizedBox(width: 8),
                                      _ongoingBadge(accent, fontSize: 11, hPad: 7, vPad: 3),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  occurrence.weekText,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Card 2: Details List
                      if (detailRows.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildIOSDetailsCard(context, children: detailRows),
                      ],

                      // Card 3: Color Picker
                      const SizedBox(height: 20),
                      _buildIOSDetailsCard(
                        context,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: _buildColorPicker(context, customColor),
                          ),
                        ],
                      ),
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

  Widget _buildIOSDetailsCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context).withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildIOSDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 62),
      child: Container(
        height: 0.5,
        color: CupertinoColors.separator.resolveFrom(context).withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildCupertinoInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    required Color secondaryColor,
  }) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
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
                    color: secondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ],
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
    final customColor = sl<CourseColorService>().getColor(occurrence.courseName);
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
                  const SizedBox(height: 8),
                  _buildColorPicker(context, customColor, isMaterial: true),
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

  static const _palette = <Color>[
    Color(0xFFD32F2F), // red
    Color(0xFFE64A19), // deep orange
    Color(0xFFF57C00), // orange
    Color(0xFFEF6C00), // amber
    Color(0xFF689F38), // light green
    Color(0xFF2E7D32), // green
    Color(0xFF00695C), // teal
    Color(0xFF00838F), // cyan
    Color(0xFF1565C0), // blue
    Color(0xFF283593), // indigo
    Color(0xFF6A1B9A), // purple
    Color(0xFFAD1457), // pink
    Color(0xFF5D4037), // brown
    Color(0xFF37474F), // blue grey
  ];

  Widget _buildColorPicker(BuildContext context, Color? currentCustom, {bool isMaterial = false}) {
    final service = sl<CourseColorService>();
    final cs = Theme.of(context).colorScheme;

    return StatefulBuilder(
      builder: (context, setPickerState) {
        final active = service.getColor(occurrence.courseName);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '卡片颜色',
                  style: isMaterial
                      ? Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)
                      : TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel.resolveFrom(context), fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                if (active != null)
                  GestureDetector(
                    onTap: () async {
                      await service.removeColor(occurrence.courseName);
                      setPickerState(() {});
                    },
                    child: Text(
                      '恢复默认',
                      style: TextStyle(
                        fontSize: 13,
                        color: isMaterial ? cs.primary : CupertinoColors.systemBlue.resolveFrom(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _palette.map((color) {
                final isSelected = active?.toARGB32() == color.toARGB32();
                return GestureDetector(
                  onTap: () async {
                    await service.setColor(occurrence.courseName, color);
                    setPickerState(() {});
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: cs.onSurface, width: 2.5)
                          : null,
                      boxShadow: isSelected
                          ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 2))]
                          : null,
                    ),
                    child: isSelected
                        ? Icon(Icons.check, size: 18, color: cs.surface)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
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
