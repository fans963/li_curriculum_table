import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:signals/signals_flutter.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/course_occurrence.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/course_color_service.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/ongoing_badge.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/timetable_appointment_card.dart';

/// Full-screen style course/schedule detail dialog in Material 3 Expressive.
class CourseDetailsSheet extends StatelessWidget {
  final CourseOccurrence occurrence;
  final AppointmentTone tone;
  final String timeLine;
  final bool isOngoing;
  final DesignStyle? designStyle;
  final VoidCallback? onClose;

  const CourseDetailsSheet({
    super.key,
    required this.occurrence,
    required this.tone,
    this.designStyle,
    required this.timeLine,
    required this.isOngoing,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final customColor = sl<CourseColorService>().getColor(
      occurrence.courseName,
    );
    final otherInfo =
        '${occurrence.courseType}'
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
                    Expanded(
                      child: Text(
                        occurrence.courseName,
                        style: tt.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.15,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    if (isOngoing) ...[
                      const SizedBox(width: 8),
                      ongoingBadge(
                        cs.primaryContainer,
                        foreground: cs.onPrimaryContainer,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  occurrence.weekText,
                  style: tt.titleMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 28),
                // Info rows + color picker — reactive to color changes
                SignalBuilder(
                  dependencies: [sl<CourseColorService>().version],
                  builder: (context) {
                    final liveTone = resolveAppointmentTone(
                      context,
                      seedText: occurrence.courseName,
                      customColor: sl<CourseColorService>().getColor(
                        occurrence.courseName,
                      ),
                    );
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow(
                          context,
                          AppIcons.time(designStyle),
                          '时间',
                          timeLine,
                          liveTone.accent,
                        ),
                        _infoRow(
                          context,
                          AppIcons.location(designStyle),
                          '地点',
                          occurrence.location,
                          liveTone.accent,
                        ),
                        _infoRow(
                          context,
                          AppIcons.person(designStyle),
                          '教师',
                          occurrence.teacher,
                          liveTone.accent,
                        ),
                        _infoRow(
                          context,
                          AppIcons.school(designStyle),
                          '其他信息',
                          otherInfo,
                          liveTone.accent,
                        ),
                        const SizedBox(height: 8),
                        _buildColorPicker(context, customColor),
                      ],
                    );
                  },
                ),
                if (onClose != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        M3EButton.filled(
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
    Color(0xFFD32F2F),
    Color(0xFFE64A19),
    Color(0xFFF57C00),
    Color(0xFFEF6C00),
    Color(0xFF689F38),
    Color(0xFF2E7D32),
    Color(0xFF00695C),
    Color(0xFF00838F),
    Color(0xFF1565C0),
    Color(0xFF283593),
    Color(0xFF6A1B9A),
    Color(0xFFAD1457),
    Color(0xFF5D4037),
    Color(0xFF37474F),
  ];

  Widget _buildColorPicker(BuildContext context, Color? currentCustom) {
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
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
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
                        color: cs.primary,
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
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
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

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: cs.onSurfaceVariant,
    );
    final valueStyle = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600);
    const iconSize = 22.0;
    const bgAlpha = 0.20;
    const gap = 2.0;
    const bottom = 18.0;
    final iconBg = BoxDecoration(
      color: iconColor.withValues(alpha: bgAlpha),
      borderRadius: BorderRadius.circular(16),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: bottom),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44.0,
            height: 44.0,
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
                const SizedBox(height: gap),
                Text(value, style: valueStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
