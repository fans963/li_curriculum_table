import 'package:flutter/material.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';

import '../settings_sections.dart';

class TimetableDisplaySettingsSection extends StatelessWidget {
  const TimetableDisplaySettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = sl<SettingsController>().state.value;
    final notifier = sl<SettingsController>();
    final ds = settings.designStyle;

    return SectionCard(
      icon: AppIcons.viewWeek(ds),
      title: '课表与交互',
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            secondary: Icon(Icons.text_fields_rounded, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
            title: const Text('课表文字自适应'),
            subtitle: const Text('自动缩小字号以完整显示课程名和地点，关闭则固定字号'),
            value: settings.autoSizeText,
            onChanged: (v) => notifier.setAutoSizeText(v),
          ),
          const Divider(height: 1),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            secondary: Icon(AppIcons.swapHoriz(ds), size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
            title: const Text('按星期滑动'),
            subtitle: const Text('以整周为单位左右对齐滑动，关闭则自由无极滑动'),
            value: settings.weeklyScroll,
            onChanged: (v) => notifier.setWeeklyScroll(v),
          ),
          if (!settings.weeklyScroll) ...[
            const Divider(height: 1),
            _DaysCountSelector(settings: settings, notifier: notifier),
          ],
          const Divider(height: 1),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            secondary: Icon(AppIcons.menuBook(ds), size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
            title: const Text('图书馆检索封面'),
            subtitle: const Text('自动获取图书封面，开启将消耗更多流量'),
            value: settings.enableBookCover,
            onChanged: (v) => notifier.setEnableBookCover(v),
          ),
        ],
      ),
    );
  }
}

/// Selector for the number of days visible in the timetable view.
/// Only shown when [weeklyScroll] is off (free scrolling mode).
class _DaysCountSelector extends StatelessWidget {
  final AppSettings settings;
  final SettingsController notifier;

  const _DaysCountSelector({required this.settings, required this.notifier});

  static const _options = [1, 3, 5, 7];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final count = settings.daysVisibleCount;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.view_column_outlined, size: 20, color: cs.onSurfaceVariant),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('屏幕内显示天数', style: tt.bodyMedium),
                    Text(
                      '当前显示 $count 天课程',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 10,
              children: _options.map((days) {
                final selected = count == days;
                return ChoiceChip(
                  label: Text('$days 天'),
                  selected: selected,
                  onSelected: (v) {
                    if (v) notifier.setDaysVisibleCount(days);
                  },
                  selectedColor: cs.primaryContainer,
                  labelStyle: TextStyle(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    color: selected ? cs.onPrimaryContainer : cs.onSurface,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
