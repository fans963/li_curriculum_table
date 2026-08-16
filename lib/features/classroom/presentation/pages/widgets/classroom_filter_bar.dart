import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:progress_indicator_m3e/progress_indicator_m3e.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/classroom/domain/models/building.dart';
import 'package:li_curriculum_table/features/classroom/domain/models/campus.dart';
import 'package:li_curriculum_table/features/classroom/presentation/state/classroom_controller.dart';
import 'package:li_curriculum_table/features/classroom/presentation/state/classroom_state.dart';
import 'package:signals/signals_flutter.dart';

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class QueryControlCard extends StatelessWidget {
  final ClassroomState state;
  const QueryControlCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final notifier = sl<ClassroomController>();
    final ds = sl<SettingsController>().state.value.designStyle;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            if (state.campuses.isNotEmpty) ...[
              SelectionHeader(
                title: '校区',
                icon: AppIcons.locationOn(ds),
                trailing: Text(
                  '${state.campuses.length}个校区',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: colorScheme.outline),
                ),
              ),
              CampusSelector(
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
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              SelectionHeader(
                title: '教学楼',
                icon: AppIcons.apartment(ds),
                trailing: Text(
                  '${state.buildings.length}栋楼',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: colorScheme.outline),
                ),
              ),
              BuildingSelector(
                buildings: state.buildings,
                selectedBuilding: state.selectedBuilding,
                onSelected: (b) => notifier.selectBuilding(b),
              ),
            ] else if (state.isLoading && state.selectedCampus != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              SelectionHeader(title: '教学楼', icon: AppIcons.apartment(ds)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: LinearProgressIndicatorM3E(
                  size: LinearProgressM3ESize.s,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SelectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;

  const SelectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

class QuickDateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const QuickDateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final ds = sl<SettingsController>().state.value.designStyle;

    // Generate dates: today, tomorrow, after-tomorrow, 3-days-later
    final dates = List.generate(4, (index) => now.add(Duration(days: index)));
    final labels = ['今天', '明天', '后天', '大后天'];

    final isQuickDate = dates.any((d) => isSameDay(selectedDate, d));
    final quickDateIndex = dates.indexWhere((d) => isSameDay(selectedDate, d));
    final selectedIndex = isQuickDate ? quickDateIndex : 4;
    final dateString = DateFormat('MM-dd').format(selectedDate);

    return M3EToggleButtonGroup(
      style: M3EButtonStyle.tonal,
      size: M3EButtonSize.sm,
      shape: M3EButtonShape.round,
      overflow: M3EButtonGroupOverflow.scroll,
      selectedIndex: selectedIndex,
      onSelectedIndexChanged: (index) async {
        if (index == null) return;
        if (index < 4) {
          onDateSelected(dates[index]);
        } else {
          final picked = await showDatePicker(
            context: context,
            initialDate: selectedDate,
            firstDate: DateTime.now().subtract(const Duration(days: 30)),
            lastDate: DateTime.now().add(const Duration(days: 90)),
          );
          if (picked != null) onDateSelected(picked);
        }
      },
      actions: [
        for (int i = 0; i < 4; i++)
          M3EToggleButtonGroupAction(
            label: Text(
              '${labels[i]} (${DateFormat('MM-dd').format(dates[i])})',
            ),
          ),
        M3EToggleButtonGroupAction(
          icon: Icon(AppIcons.calendarMonth(ds), size: 16),
          label: Text(!isQuickDate ? '其他: $dateString' : '选择日期...'),
        ),
      ],
    );
  }
}

class CampusDropdown extends SignalStatefulWidget {
  final ValueChanged<Campus> onSelected;

  const CampusDropdown({super.key, required this.onSelected});

  @override
  State<CampusDropdown> createState() => _CampusDropdownState();
}

class _CampusDropdownState extends State<CampusDropdown> {
  late final M3EDropdownController<Campus> _controller;
  late final EffectCleanup _syncEffect;

  @override
  void initState() {
    super.initState();
    _controller = M3EDropdownController<Campus>();
    _controller.initialize();

    // Reactively sync dropdown items from the controller signal
    _syncEffect = effect(() {
      final state = sl<ClassroomController>().state.value;
      _controller.setItems(
        state.campuses
            .map(
              (c) => M3EDropdownItem(
                label: c.name,
                value: c,
                selected: c.id == state.selectedCampus?.id,
              ),
            )
            .toList(),
      );
      if (state.selectedCampus != null) {
        _controller.selectWhere(
          (item) => item.value.id == state.selectedCampus!.id,
        );
      }
    });
  }

  @override
  void dispose() {
    _syncEffect();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ds = sl<SettingsController>().state.value.designStyle;

    return SizedBox(
      width: 140,
      child: M3EDropdownMenu<Campus>(
        singleSelect: true,
        showChipAnimation: false,
        items: const [],
        controller: _controller,
        onSelectionChanged: (items) {
          if (items.isNotEmpty) widget.onSelected(items.first.value);
        },
        containerRadius: 16,
        fieldStyle: M3EDropdownFieldStyle(
          hintText: '校区',
          prefixIcon: Icon(AppIcons.locationOn(ds), size: 18),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: BorderSide(color: cs.outlineVariant, width: 0.5),
          focusedBorder: BorderSide(color: cs.primary, width: 1),
          borderRadius: BorderRadius.circular(12),
          selectedBorderRadius: 12,
        ),
        dropdownStyle: M3EDropdownStyle(maxHeight: 300, containerRadius: 16),
        itemStyle: M3EDropdownItemStyle(
          outerRadius: 12,
          innerRadius: 6,
          selectedIcon: Icon(Icons.check, size: 18, color: cs.primary),
        ),
      ),
    );
  }
}

class BuildingDropdown extends SignalStatefulWidget {
  final ValueChanged<Building> onSelected;

  const BuildingDropdown({super.key, required this.onSelected});

  @override
  State<BuildingDropdown> createState() => _BuildingDropdownState();
}

class _BuildingDropdownState extends State<BuildingDropdown> {
  late final M3EDropdownController<Building> _controller;
  late final EffectCleanup _syncEffect;

  @override
  void initState() {
    super.initState();
    _controller = M3EDropdownController<Building>();
    _controller.initialize();

    // Reactively sync dropdown items from the controller signal
    _syncEffect = effect(() {
      final state = sl<ClassroomController>().state.value;
      _controller.setItems(
        state.buildings
            .map(
              (b) => M3EDropdownItem(
                label: b.name,
                value: b,
                selected: b.id == state.selectedBuilding?.id,
              ),
            )
            .toList(),
      );
      if (state.selectedBuilding != null) {
        _controller.selectWhere(
          (item) => item.value.id == state.selectedBuilding!.id,
        );
      }
    });
  }

  @override
  void dispose() {
    _syncEffect();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ds = sl<SettingsController>().state.value.designStyle;

    return SizedBox(
      width: 160,
      child: M3EDropdownMenu<Building>(
        singleSelect: true,
        showChipAnimation: false,
        items: const [],
        controller: _controller,
        onSelectionChanged: (items) {
          if (items.isNotEmpty) widget.onSelected(items.first.value);
        },
        containerRadius: 16,
        fieldStyle: M3EDropdownFieldStyle(
          hintText: '教学楼',
          prefixIcon: Icon(AppIcons.apartment(ds), size: 18),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: BorderSide(color: cs.outlineVariant, width: 0.5),
          focusedBorder: BorderSide(color: cs.primary, width: 1),
          borderRadius: BorderRadius.circular(12),
          selectedBorderRadius: 12,
        ),
        dropdownStyle: M3EDropdownStyle(maxHeight: 350, containerRadius: 16),
        itemStyle: M3EDropdownItemStyle(
          outerRadius: 12,
          innerRadius: 6,
          selectedIcon: Icon(Icons.check, size: 18, color: cs.primary),
        ),
      ),
    );
  }
}

class BuildingSelector extends StatelessWidget {
  final List<Building> buildings;
  final Building? selectedBuilding;
  final ValueChanged<Building> onSelected;

  const BuildingSelector({
    super.key,
    required this.buildings,
    this.selectedBuilding,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selectedIndex = buildings.indexWhere(
      (b) => b.id == selectedBuilding?.id,
    );
    return M3EToggleButtonGroup(
      style: M3EButtonStyle.tonal,
      size: M3EButtonSize.sm,
      shape: M3EButtonShape.round,
      overflow: M3EButtonGroupOverflow.scroll,
      selectedIndex: selectedIndex >= 0 ? selectedIndex : null,
      onSelectedIndexChanged: (index) {
        if (index != null) onSelected(buildings[index]);
      },
      actions: buildings
          .map((b) => M3EToggleButtonGroupAction(label: Text(b.name)))
          .toList(),
    );
  }
}

class CampusSelector extends StatelessWidget {
  final List<Campus> campuses;
  final Campus? selectedCampus;
  final ValueChanged<Campus> onSelected;

  const CampusSelector({
    super.key,
    required this.campuses,
    this.selectedCampus,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selectedIndex = campuses.indexWhere(
      (c) => c.id == selectedCampus?.id,
    );
    return M3EToggleButtonGroup(
      style: M3EButtonStyle.tonal,
      size: M3EButtonSize.sm,
      shape: M3EButtonShape.round,
      overflow: M3EButtonGroupOverflow.scroll,
      selectedIndex: selectedIndex >= 0 ? selectedIndex : null,
      onSelectedIndexChanged: (index) {
        if (index != null) onSelected(campuses[index]);
      },
      actions: campuses
          .map((c) => M3EToggleButtonGroupAction(label: Text(c.name)))
          .toList(),
    );
  }
}
