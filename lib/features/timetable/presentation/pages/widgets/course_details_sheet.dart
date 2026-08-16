import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:signals/signals_flutter.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/course_occurrence.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/course_color_service.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/cupertino_detail_helpers.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/ongoing_badge.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/timetable_appointment_card.dart';

/// Full-screen style course/schedule detail sheet with Cupertino and Material variants.
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
    final customColor = sl<CourseColorService>().getColor(
      occurrence.courseName,
    );
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final sep = CupertinoColors.separator.resolveFrom(context);
    final otherInfo =
        '${occurrence.courseType}'
        '${occurrence.credit.isNotEmpty ? ' · ${occurrence.credit}学分' : ''}';

    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final viewPadding = MediaQuery.of(context).padding.bottom;

    final hasDetails =
        timeLine.trim().isNotEmpty ||
        occurrence.location.trim().isNotEmpty ||
        occurrence.teacher.trim().isNotEmpty ||
        otherInfo.trim().isNotEmpty;

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
                            color: CupertinoColors.systemBlue.resolveFrom(
                              context,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(height: 0.5, color: sep),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    16 + bottomPadding + viewPadding,
                  ),
                  child: Column(
                    children: [
                      // Card 1: Title and WeekText — reactive to color changes
                      SignalBuilder(
                        dependencies: [sl<CourseColorService>().version],
                        builder: (context) {
                          final liveAccent = resolveCupertinoTone(
                            context,
                            occurrence.courseName,
                            customColor: sl<CourseColorService>().getColor(
                              occurrence.courseName,
                            ),
                          ).accent;
                          return buildIOSDetailsCard(
                            context,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            occurrence.courseName,
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w700,
                                              color: CupertinoColors.label
                                                  .resolveFrom(context),
                                              height: 1.2,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                        ),
                                        if (isOngoing) ...[
                                          const SizedBox(width: 8),
                                          ongoingBadge(
                                            liveAccent,
                                            fontSize: 11,
                                            hPad: 7,
                                            vPad: 3,
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      occurrence.weekText,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: liveAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      if (hasDetails) ...[
                        const SizedBox(height: 20),
                        SignalBuilder(
                          dependencies: [sl<CourseColorService>().version],
                          builder: (context) {
                            final liveAccent2 = resolveCupertinoTone(
                              context,
                              occurrence.courseName,
                              customColor: sl<CourseColorService>().getColor(
                                occurrence.courseName,
                              ),
                            ).accent;
                            final liveRows = <Widget>[];
                            if (timeLine.trim().isNotEmpty) {
                              liveRows.add(
                                buildCupertinoInfoRow(
                                  context,
                                  icon: CupertinoIcons.clock,
                                  label: '时间',
                                  value: timeLine,
                                  iconColor: liveAccent2,
                                  secondaryColor: secondary,
                                ),
                              );
                            }
                            if (occurrence.location.trim().isNotEmpty) {
                              if (liveRows.isNotEmpty) {
                                liveRows.add(buildIOSDivider(context));
                              }
                              liveRows.add(
                                buildCupertinoInfoRow(
                                  context,
                                  icon: CupertinoIcons.location,
                                  label: '地点',
                                  value: occurrence.location,
                                  iconColor: liveAccent2,
                                  secondaryColor: secondary,
                                ),
                              );
                            }
                            if (occurrence.teacher.trim().isNotEmpty) {
                              if (liveRows.isNotEmpty) {
                                liveRows.add(buildIOSDivider(context));
                              }
                              liveRows.add(
                                buildCupertinoInfoRow(
                                  context,
                                  icon: CupertinoIcons.person,
                                  label: '教师',
                                  value: occurrence.teacher,
                                  iconColor: liveAccent2,
                                  secondaryColor: secondary,
                                ),
                              );
                            }
                            if (otherInfo.trim().isNotEmpty) {
                              if (liveRows.isNotEmpty) {
                                liveRows.add(buildIOSDivider(context));
                              }
                              liveRows.add(
                                buildCupertinoInfoRow(
                                  context,
                                  icon: CupertinoIcons.info_circle,
                                  label: '其他信息',
                                  value: otherInfo,
                                  iconColor: liveAccent2,
                                  secondaryColor: secondary,
                                ),
                              );
                            }
                            return buildIOSDetailsCard(
                              context,
                              children: liveRows,
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 20),
                      buildIOSDetailsCard(
                        context,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
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

  // _buildIOSDetailsCard, _buildIOSDivider, _buildCupertinoInfoRow
  // extracted to cupertino_detail_helpers.dart

  // ── Material ───────────────────────────────────────────────────────────

  Widget _buildMaterial(BuildContext context) {
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
                          null,
                          isMaterial: true,
                        ),
                        _infoRow(
                          context,
                          AppIcons.location(designStyle),
                          '地点',
                          occurrence.location,
                          liveTone.accent,
                          null,
                          isMaterial: true,
                        ),
                        _infoRow(
                          context,
                          AppIcons.person(designStyle),
                          '教师',
                          occurrence.teacher,
                          liveTone.accent,
                          null,
                          isMaterial: true,
                        ),
                        _infoRow(
                          context,
                          AppIcons.school(designStyle),
                          '其他信息',
                          otherInfo,
                          liveTone.accent,
                          null,
                          isMaterial: true,
                        ),
                        const SizedBox(height: 8),
                        _buildColorPicker(
                          context,
                          customColor,
                          isMaterial: true,
                        ),
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

  Widget _buildColorPicker(
    BuildContext context,
    Color? currentCustom, {
    bool isMaterial = false,
  }) {
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
                      ? Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        )
                      : TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                          fontWeight: FontWeight.w500,
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
                        color: isMaterial
                            ? cs.primary
                            : CupertinoColors.systemBlue.resolveFrom(context),
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
    Color? secondaryLabel, {
    bool isMaterial = false,
  }) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    final labelStyle = isMaterial
        ? Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          )
        : TextStyle(
            fontSize: 13,
            color: secondaryLabel,
            fontWeight: FontWeight.w500,
          );
    final valueStyle = isMaterial
        ? Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)
        : TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.label.resolveFrom(context),
          );
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

// confirmRemoveScheduleEvent extracted to schedule_event_remover.dart
