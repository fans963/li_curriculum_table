import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_helpers.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/presentation/widgets/adaptive_date_picker.dart';
import 'package:li_curriculum_table/core/presentation/styles/styles.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/classroom/domain/models/building.dart';
import 'package:li_curriculum_table/features/classroom/domain/models/campus.dart';
import 'package:li_curriculum_table/features/classroom/presentation/pages/widgets/classroom_filter_bar.dart';
import 'package:li_curriculum_table/features/classroom/presentation/state/classroom_controller.dart';
import 'package:li_curriculum_table/features/classroom/presentation/state/classroom_state.dart';

/// iOS 26 Liquid Glass Query Control Card
class LiquidGlassQueryControlCard extends StatelessWidget {
  final ClassroomState state;
  const LiquidGlassQueryControlCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final notifier = sl<ClassroomController>();
    final ds = sl<SettingsController>().state.value.designStyle;
    final style = UiStyleRegistry.resolve(ds);

    return style.buildCard(
      context: context,
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        children: [
          if (state.campuses.isNotEmpty) ...[
            SelectionHeader(
              title: '校区',
              icon: AppIcons.locationOn(ds),
              trailing: Text(
                '${state.campuses.length}个校区',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: colorScheme.outline),
              ),
            ),
            LiquidGlassCampusSelector(
              campuses: state.campuses,
              selectedCampus: state.selectedCampus,
              onSelected: (c) => notifier.setCampus(c),
            ),
          ],
          if (state.buildings.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Divider(
                height: 1,
                thickness: 0.5,
                indent: 16,
                endIndent: 16,
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            SelectionHeader(
              title: '教学楼',
              icon: AppIcons.apartment(ds),
              trailing: Text(
                '${state.buildings.length}栋楼',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: colorScheme.outline),
              ),
            ),
            LiquidGlassBuildingSelector(
              buildings: state.buildings,
              selectedBuilding: state.selectedBuilding,
              onSelected: (b) => notifier.selectBuilding(b),
            ),
          ] else if (state.isLoading && state.selectedCampus != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Divider(
                height: 1,
                thickness: 0.5,
                indent: 16,
                endIndent: 16,
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            SelectionHeader(title: '教学楼', icon: AppIcons.apartment(ds)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: adaptiveLinearProgressIndicator(
                context: context,
                designStyle: ds,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// iOS 26 Liquid Glass Quick Date Selector with squircle glass pills
class LiquidGlassQuickDateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const LiquidGlassQuickDateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dates = List.generate(4, (index) => now.add(Duration(days: index)));
    final labels = ['今天', '明天', '后天', '大后天'];
    final isQuickDate = dates.any((d) => isSameDay(selectedDate, d));
    final quickDateIndex = dates.indexWhere((d) => isSameDay(selectedDate, d));
    final dateString = DateFormat('MM-dd').format(selectedDate);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (int i = 0; i < 4; i++) ...[
            _DatePill(
              label: '${labels[i]} (${DateFormat('MM-dd').format(dates[i])})',
              isSelected: isQuickDate && quickDateIndex == i,
              cs: cs,
              isDark: isDark,
              onTap: () => onDateSelected(dates[i]),
            ),
            const SizedBox(width: 8),
          ],
          _DatePill(
            icon: CupertinoIcons.calendar,
            label: !isQuickDate ? '其他: $dateString' : '选择日期...',
            isSelected: !isQuickDate,
            cs: cs,
            isDark: isDark,
            onTap: () async {
              final picked = await showAdaptiveDatePicker(
                context: context,
                designStyle: sl<SettingsController>().state.value.designStyle,
                initialDate: selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (picked != null) onDateSelected(picked);
            },
          ),
        ],
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final ColorScheme cs;
  final bool isDark;
  final VoidCallback onTap;

  const _DatePill({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.cs,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        shape: const LiquidRoundedSuperellipse(borderRadius: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? cs.primary : cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// iOS 26 Liquid Glass Campus Dropdown with GlassPullDownButton
class LiquidGlassCampusDropdown extends StatelessWidget {
  final ValueChanged<Campus> onSelected;

  const LiquidGlassCampusDropdown({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final state = sl<ClassroomController>().state.value;
    final selectedCampus = state.selectedCampus;
    final title = selectedCampus?.name ?? '选择校区';

    final items = state.campuses
        .map(
          (c) => GlassMenuItem(
            title: c.name,
            icon: selectedCampus?.id == c.id
                ? const Icon(CupertinoIcons.checkmark)
                : null,
            onTap: () => onSelected(c),
          ),
        )
        .toList();

    return GlassPullDownButton(
      label: title,
      icon: const Icon(CupertinoIcons.location),
      buttonWidth: 148,
      buttonHeight: 40,
      items: items.isEmpty
          ? [GlassMenuItem(title: '暂无校区', onTap: () {})]
          : items,
      buttonShape: const LiquidRoundedSuperellipse(borderRadius: 14),
    );
  }
}

/// iOS 26 Liquid Glass Building Dropdown with GlassPullDownButton
class LiquidGlassBuildingDropdown extends StatelessWidget {
  final ValueChanged<Building> onSelected;

  const LiquidGlassBuildingDropdown({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final state = sl<ClassroomController>().state.value;
    final selectedBuilding = state.selectedBuilding;
    final title = selectedBuilding?.name ?? '选择教学楼';

    final items = state.buildings
        .map(
          (b) => GlassMenuItem(
            title: b.name,
            icon: selectedBuilding?.id == b.id
                ? const Icon(CupertinoIcons.checkmark)
                : null,
            onTap: () => onSelected(b),
          ),
        )
        .toList();

    return GlassPullDownButton(
      label: title,
      icon: const Icon(CupertinoIcons.building_2_fill),
      buttonWidth: 148,
      buttonHeight: 40,
      items: items.isEmpty
          ? [GlassMenuItem(title: '暂无教学楼', onTap: () {})]
          : items,
      buttonShape: const LiquidRoundedSuperellipse(borderRadius: 14),
    );
  }
}

/// iOS 26 Liquid Glass Campus Selector
class LiquidGlassCampusSelector extends StatelessWidget {
  final List<Campus> campuses;
  final Campus? selectedCampus;
  final ValueChanged<Campus> onSelected;

  const LiquidGlassCampusSelector({
    super.key,
    required this.campuses,
    this.selectedCampus,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: campuses.map((c) {
          final isSelected = c.id == selectedCampus?.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _DatePill(
              label: c.name,
              isSelected: isSelected,
              cs: cs,
              isDark: isDark,
              onTap: () => onSelected(c),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// iOS 26 Liquid Glass Building Selector
class LiquidGlassBuildingSelector extends StatelessWidget {
  final List<Building> buildings;
  final Building? selectedBuilding;
  final ValueChanged<Building> onSelected;

  const LiquidGlassBuildingSelector({
    super.key,
    required this.buildings,
    this.selectedBuilding,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: buildings.map((b) {
          final isSelected = b.id == selectedBuilding?.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _DatePill(
              label: b.name,
              isSelected: isSelected,
              cs: cs,
              isDark: isDark,
              onTap: () => onSelected(b),
            ),
          );
        }).toList(),
      ),
    );
  }
}
