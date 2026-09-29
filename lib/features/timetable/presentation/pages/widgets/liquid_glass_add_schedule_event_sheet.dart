import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_helpers.dart';
import 'package:li_curriculum_table/core/presentation/styles/styles.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';

class LiquidGlassAddScheduleEventSheetView extends StatelessWidget {
  final ScrollController scrollController;
  final TextEditingController nameController;
  final TextEditingController teacherController;
  final TextEditingController locationController;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool enableNotification;
  final TimeOfDay notifyTime;
  final bool nameNotEmpty;
  final VoidCallback onPickDate;
  final VoidCallback onPickStartTime;
  final VoidCallback onPickEndTime;
  final ValueChanged<bool> onToggleNotification;
  final VoidCallback onPickNotifyTime;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const LiquidGlassAddScheduleEventSheetView({
    super.key,
    required this.scrollController,
    required this.nameController,
    required this.teacherController,
    required this.locationController,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.enableNotification,
    required this.notifyTime,
    required this.nameNotEmpty,
    required this.onPickDate,
    required this.onPickStartTime,
    required this.onPickEndTime,
    required this.onToggleNotification,
    required this.onPickNotifyTime,
    required this.onSubmit,
    required this.onCancel,
  });

  String _weekdayLabel(int weekday) {
    const labels = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return labels[weekday];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final style = UiStyleRegistry.resolve(DesignStyle.cupertino);

    return GlassContainer(
      shape: const LiquidRoundedSuperellipse(borderRadius: 32),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.event_available_rounded,
                  color: cs.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '添加日程',
                style: tt.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Title
          adaptiveTextField(
            context: context,
            designStyle: DesignStyle.cupertino,
            controller: nameController,
            textInputAction: TextInputAction.next,
            labelText: '日程名称 *',
            prefixIcon: const Icon(Icons.event_note_outlined),
          ),
          const SizedBox(height: 12),
          adaptiveTextField(
            context: context,
            designStyle: DesignStyle.cupertino,
            controller: teacherController,
            textInputAction: TextInputAction.next,
            labelText: '相关人员',
            prefixIcon: const Icon(Icons.person_outline),
          ),
          const SizedBox(height: 12),
          adaptiveTextField(
            context: context,
            designStyle: DesignStyle.cupertino,
            controller: locationController,
            textInputAction: TextInputAction.next,
            labelText: '地点',
            prefixIcon: const Icon(Icons.location_on_outlined),
          ),
          const SizedBox(height: 20),

          // Date
          Text(
            '日期',
            style: tt.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onPickDate,
            child: style.buildCard(
              context: context,
              borderRadius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 20,
                    color: cs.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}  ${_weekdayLabel(date.weekday)}',
                    style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Time range
          Text(
            '时间',
            style: tt.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onPickStartTime,
                  child: style.buildCard(
                    context: context,
                    borderRadius: 16,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '开始时间',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_outlined,
                              size: 16,
                              color: cs.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                              style: tt.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '—',
                  style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onPickEndTime,
                  child: style.buildCard(
                    context: context,
                    borderRadius: 16,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '结束时间',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_outlined,
                              size: 16,
                              color: cs.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                              style: tt.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Notification card
          style.buildCard(
            context: context,
            borderRadius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      size: 20,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '开启提醒',
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    adaptiveSwitch(
                      context: context,
                      designStyle: DesignStyle.cupertino,
                      value: enableNotification,
                      onChanged: onToggleNotification,
                    ),
                  ],
                ),
                if (enableNotification) ...[
                  const Divider(height: 16),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onPickNotifyTime,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text('提醒时间', style: tt.bodyMedium),
                          const Spacer(),
                          Text(
                            '${notifyTime.hour.toString().padLeft(2, '0')}:${notifyTime.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: cs.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: cs.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              Expanded(
                child: adaptiveButton(
                  context: context,
                  designStyle: DesignStyle.cupertino,
                  style: UiButtonStyle.text,
                  onPressed: onCancel,
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: adaptiveButton(
                  context: context,
                  designStyle: DesignStyle.cupertino,
                  style: UiButtonStyle.filled,
                  onPressed: nameNotEmpty ? onSubmit : null,
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
