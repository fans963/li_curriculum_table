import 'package:flutter/material.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:slider_m3e/slider_m3e.dart';
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
          if (settings.autoSizeText) ...[
            _AutoSizeMinFontSizeSlider(settings: settings, notifier: notifier),
          ] else ...[
            _FixedTextSettings(settings: settings, notifier: notifier),
          ],
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
            subtitle: const Text('自动获取图书封面,目前数据库并不完善，仅有部分热门书籍封面信息'),
            value: settings.enableBookCover,
            onChanged: (v) => notifier.setEnableBookCover(v),
          ),
        ],
      ),
    );
  }
}

/// Slider for minimum font size when auto-size is ON.
class _AutoSizeMinFontSizeSlider extends StatelessWidget {
  final AppSettings settings;
  final SettingsController notifier;

  const _AutoSizeMinFontSizeSlider({required this.settings, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.format_size, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('最小字号', style: Theme.of(context).textTheme.bodySmall),
                SliderM3E(
                  value: settings.autoSizeMinFontSize,
                  min: 4,
                  max: 14,
                  divisions: 10,
                  label: settings.autoSizeMinFontSize.toStringAsFixed(1),
                  onChanged: (v) => notifier.setAutoSizeMinFontSize(v),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              settings.autoSizeMinFontSize.toStringAsFixed(1),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Controls for font size and max lines when auto-size is OFF.
class _FixedTextSettings extends StatelessWidget {
  final AppSettings settings;
  final SettingsController notifier;

  const _FixedTextSettings({required this.settings, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        children: [
          // Font size slider
          Row(
            children: [
              Icon(Icons.format_size, size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('字体大小', style: Theme.of(context).textTheme.bodySmall),
                    SliderM3E(
                      value: settings.timetableTextFontSize,
                      min: 5,
                      max: 20,
                      divisions: 15,
                      label: settings.timetableTextFontSize.toStringAsFixed(1),
                      onChanged: (v) => notifier.setTimetableTextFontSize(v),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  settings.timetableTextFontSize.toStringAsFixed(1),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary),
                ),
              ),
            ],
          ),
          // Max lines selector
          Row(
            children: [
              Icon(Icons.format_list_numbered, size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('最大行数', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [1, 2, 3, 4].map((n) {
                        final selected = settings.timetableTextMaxLines == n;
                        return ChoiceChip(
                          label: Text('$n'),
                          selected: selected,
                          onSelected: (v) {
                            if (v) notifier.setTimetableTextMaxLines(n);
                          },
                          selectedColor: cs.primaryContainer,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            color: selected ? cs.onPrimaryContainer : cs.onSurface,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
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
