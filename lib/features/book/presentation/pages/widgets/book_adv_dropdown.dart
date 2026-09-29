import 'package:flutter/material.dart';
import 'package:li_curriculum_table/core/presentation/styles/styles.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/features/book/presentation/pages/widgets/liquid_glass_adv_dropdown.dart';
import 'package:li_curriculum_table/features/book/presentation/pages/widgets/m3e_adv_dropdown.dart';

export 'liquid_glass_adv_dropdown.dart';
export 'm3e_adv_dropdown.dart';

/// Adaptive advanced search dropdown for book tab.
class BookAdvDropdown extends StatelessWidget {
  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;
  final DesignStyle? designStyle;

  const BookAdvDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.designStyle,
  });

  @override
  Widget build(BuildContext context) {
    final concrete = UiStyleRegistry.resolveConcreteStyle(designStyle);

    if (concrete == DesignStyle.cupertino) {
      return LiquidGlassAdvDropdown(
        label: label,
        value: value,
        items: items,
        onChanged: onChanged,
      );
    }

    return M3EAdvDropdown(
      label: label,
      value: value,
      items: items,
      onChanged: onChanged,
    );
  }
}
