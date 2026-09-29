import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/classroom/domain/models/building.dart';
import 'package:li_curriculum_table/features/classroom/domain/models/campus.dart';
import 'package:li_curriculum_table/features/classroom/presentation/pages/widgets/classroom_filter_bar.dart';
import 'package:li_curriculum_table/features/classroom/presentation/state/classroom_controller.dart';
import 'package:li_curriculum_table/features/classroom/presentation/state/classroom_state.dart';
import 'package:signals/signals_flutter.dart';

/// Material 3 Expressive Query Control Card
class M3EQueryControlCard extends StatelessWidget {
  final ClassroomState state;
  const M3EQueryControlCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final notifier = sl<ClassroomController>();
    final ds = sl<SettingsController>().state.value.designStyle;

    return M3ECard(
      variant: M3ECardVariant.outlined,
      borderRadius: BorderRadius.circular(28),
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      border: BorderSide(color: colorScheme.outlineVariant),
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
            M3ECampusSelector(
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
            M3EBuildingSelector(
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
              child: M3EProgressIndicator.linear(
                linearSize: M3EProgressIndicatorSize.s,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Material 3 Expressive Quick Date Selector
class M3EQuickDateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const M3EQuickDateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final ds = sl<SettingsController>().state.value.designStyle;

    final dates = List.generate(4, (index) => now.add(Duration(days: index)));
    final labels = ['今天', '明天', '后天', '大后天'];

    final isQuickDate = dates.any((d) => isSameDay(selectedDate, d));
    final quickDateIndex = dates.indexWhere((d) => isSameDay(selectedDate, d));
    final selectedIndex = isQuickDate ? quickDateIndex : 4;
    final dateString = DateFormat('MM-dd').format(selectedDate);

    return M3EButtonGroup(
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
          M3EButtonGroupAction(
            label: Text(
              '${labels[i]} (${DateFormat('MM-dd').format(dates[i])})',
            ),
          ),
        M3EButtonGroupAction(
          icon: Icon(AppIcons.calendarMonth(ds), size: 16),
          label: Text(!isQuickDate ? '其他: $dateString' : '选择日期...'),
        ),
      ],
    );
  }
}

/// Material 3 Expressive Campus Dropdown
class M3ECampusDropdown extends SignalStatefulWidget {
  final ValueChanged<Campus> onSelected;

  const M3ECampusDropdown({super.key, required this.onSelected});

  @override
  State<M3ECampusDropdown> createState() => _M3ECampusDropdownState();
}

class _M3ECampusDropdownState extends State<M3ECampusDropdown> {
  late final M3EDropdownController<Campus> _controller;
  late final EffectCleanup _syncEffect;

  @override
  void initState() {
    super.initState();
    _controller = M3EDropdownController<Campus>();
    _controller.initialize();

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
        dropdownStyle: M3EDropdownPanelStyle(
          maxHeight: 300,
          containerRadius: 16,
        ),
        itemStyle: M3EDropdownItemStyle(
          outerRadius: 12,
          innerRadius: 6,
          selectedIcon: Icon(Icons.check, size: 18, color: cs.primary),
        ),
      ),
    );
  }
}

/// Material 3 Expressive Building Dropdown
class M3EBuildingDropdown extends SignalStatefulWidget {
  final ValueChanged<Building> onSelected;

  const M3EBuildingDropdown({super.key, required this.onSelected});

  @override
  State<M3EBuildingDropdown> createState() => _M3EBuildingDropdownState();
}

class _M3EBuildingDropdownState extends State<M3EBuildingDropdown> {
  late final M3EDropdownController<Building> _controller;
  late final EffectCleanup _syncEffect;

  @override
  void initState() {
    super.initState();
    _controller = M3EDropdownController<Building>();
    _controller.initialize();

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
        dropdownStyle: M3EDropdownPanelStyle(
          maxHeight: 350,
          containerRadius: 16,
        ),
        itemStyle: M3EDropdownItemStyle(
          outerRadius: 12,
          innerRadius: 6,
          selectedIcon: Icon(Icons.check, size: 18, color: cs.primary),
        ),
      ),
    );
  }
}

/// Material 3 Expressive Building Selector
class M3EBuildingSelector extends StatelessWidget {
  final List<Building> buildings;
  final Building? selectedBuilding;
  final ValueChanged<Building> onSelected;

  const M3EBuildingSelector({
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
    return M3EButtonGroup(
      style: M3EButtonStyle.tonal,
      size: M3EButtonSize.sm,
      shape: M3EButtonShape.round,
      overflow: M3EButtonGroupOverflow.scroll,
      selectedIndex: selectedIndex >= 0 ? selectedIndex : null,
      onSelectedIndexChanged: (index) {
        if (index != null) onSelected(buildings[index]);
      },
      actions: buildings
          .map((b) => M3EButtonGroupAction(label: Text(b.name)))
          .toList(),
    );
  }
}

/// Material 3 Expressive Campus Selector
class M3ECampusSelector extends StatelessWidget {
  final List<Campus> campuses;
  final Campus? selectedCampus;
  final ValueChanged<Campus> onSelected;

  const M3ECampusSelector({
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
    return M3EButtonGroup(
      style: M3EButtonStyle.tonal,
      size: M3EButtonSize.sm,
      shape: M3EButtonShape.round,
      overflow: M3EButtonGroupOverflow.scroll,
      selectedIndex: selectedIndex >= 0 ? selectedIndex : null,
      onSelectedIndexChanged: (index) {
        if (index != null) onSelected(campuses[index]);
      },
      actions: campuses
          .map((c) => M3EButtonGroupAction(label: Text(c.name)))
          .toList(),
    );
  }
}
