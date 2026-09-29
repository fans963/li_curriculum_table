import 'package:flutter/material.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/styles/styles.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/classroom/domain/models/building.dart';
import 'package:li_curriculum_table/features/classroom/domain/models/campus.dart';
import 'package:li_curriculum_table/features/classroom/presentation/pages/widgets/liquid_glass_classroom_filter_bar.dart';
import 'package:li_curriculum_table/features/classroom/presentation/pages/widgets/m3e_classroom_filter_bar.dart';
import 'package:li_curriculum_table/features/classroom/presentation/state/classroom_state.dart';

export 'liquid_glass_classroom_filter_bar.dart';
export 'm3e_classroom_filter_bar.dart';

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

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

/// Adaptive Query Control Card delegating to M3E or Liquid Glass
class QueryControlCard extends StatelessWidget {
  final ClassroomState state;
  final DesignStyle? designStyle;

  const QueryControlCard({super.key, required this.state, this.designStyle});

  @override
  Widget build(BuildContext context) {
    final ds =
        designStyle ?? sl<SettingsController>().state.value.designStyle;
    final concrete = UiStyleRegistry.resolveConcreteStyle(ds);

    if (concrete == DesignStyle.cupertino) {
      return LiquidGlassQueryControlCard(state: state);
    }
    return M3EQueryControlCard(state: state);
  }
}

/// Adaptive Quick Date Selector delegating to M3E or Liquid Glass
class QuickDateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final DesignStyle? designStyle;

  const QuickDateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.designStyle,
  });

  @override
  Widget build(BuildContext context) {
    final ds =
        designStyle ?? sl<SettingsController>().state.value.designStyle;
    final concrete = UiStyleRegistry.resolveConcreteStyle(ds);

    if (concrete == DesignStyle.cupertino) {
      return LiquidGlassQuickDateSelector(
        selectedDate: selectedDate,
        onDateSelected: onDateSelected,
      );
    }
    return M3EQuickDateSelector(
      selectedDate: selectedDate,
      onDateSelected: onDateSelected,
    );
  }
}

/// Adaptive Campus Dropdown delegating to M3E or Liquid Glass
class CampusDropdown extends StatelessWidget {
  final ValueChanged<Campus> onSelected;
  final DesignStyle? designStyle;

  const CampusDropdown({
    super.key,
    required this.onSelected,
    this.designStyle,
  });

  @override
  Widget build(BuildContext context) {
    final ds =
        designStyle ?? sl<SettingsController>().state.value.designStyle;
    final concrete = UiStyleRegistry.resolveConcreteStyle(ds);

    if (concrete == DesignStyle.cupertino) {
      return LiquidGlassCampusDropdown(onSelected: onSelected);
    }
    return M3ECampusDropdown(onSelected: onSelected);
  }
}

/// Adaptive Building Dropdown delegating to M3E or Liquid Glass
class BuildingDropdown extends StatelessWidget {
  final ValueChanged<Building> onSelected;
  final DesignStyle? designStyle;

  const BuildingDropdown({
    super.key,
    required this.onSelected,
    this.designStyle,
  });

  @override
  Widget build(BuildContext context) {
    final ds =
        designStyle ?? sl<SettingsController>().state.value.designStyle;
    final concrete = UiStyleRegistry.resolveConcreteStyle(ds);

    if (concrete == DesignStyle.cupertino) {
      return LiquidGlassBuildingDropdown(onSelected: onSelected);
    }
    return M3EBuildingDropdown(onSelected: onSelected);
  }
}

/// Adaptive Campus Selector delegating to M3E or Liquid Glass
class CampusSelector extends StatelessWidget {
  final List<Campus> campuses;
  final Campus? selectedCampus;
  final ValueChanged<Campus> onSelected;
  final DesignStyle? designStyle;

  const CampusSelector({
    super.key,
    required this.campuses,
    this.selectedCampus,
    required this.onSelected,
    this.designStyle,
  });

  @override
  Widget build(BuildContext context) {
    final ds =
        designStyle ?? sl<SettingsController>().state.value.designStyle;
    final concrete = UiStyleRegistry.resolveConcreteStyle(ds);

    if (concrete == DesignStyle.cupertino) {
      return LiquidGlassCampusSelector(
        campuses: campuses,
        selectedCampus: selectedCampus,
        onSelected: onSelected,
      );
    }
    return M3ECampusSelector(
      campuses: campuses,
      selectedCampus: selectedCampus,
      onSelected: onSelected,
    );
  }
}

/// Adaptive Building Selector delegating to M3E or Liquid Glass
class BuildingSelector extends StatelessWidget {
  final List<Building> buildings;
  final Building? selectedBuilding;
  final ValueChanged<Building> onSelected;
  final DesignStyle? designStyle;

  const BuildingSelector({
    super.key,
    required this.buildings,
    this.selectedBuilding,
    required this.onSelected,
    this.designStyle,
  });

  @override
  Widget build(BuildContext context) {
    final ds =
        designStyle ?? sl<SettingsController>().state.value.designStyle;
    final concrete = UiStyleRegistry.resolveConcreteStyle(ds);

    if (concrete == DesignStyle.cupertino) {
      return LiquidGlassBuildingSelector(
        buildings: buildings,
        selectedBuilding: selectedBuilding,
        onSelected: onSelected,
      );
    }
    return M3EBuildingSelector(
      buildings: buildings,
      selectedBuilding: selectedBuilding,
      onSelected: onSelected,
    );
  }
}
