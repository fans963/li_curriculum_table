import 'package:flutter/material.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
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
            secondary: Icon(AppIcons.swapHoriz(ds), size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
            title: const Text('按星期滑动'),
            subtitle: const Text('以整周为单位左右对齐滑动，关闭则自由无极滑动'),
            value: settings.weeklyScroll,
            onChanged: (v) => notifier.setWeeklyScroll(v),
          ),
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
