import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// An iOS 26 Liquid Glass dropdown/pull-down menu for book advanced search.
class LiquidGlassAdvDropdown extends StatelessWidget {
  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;

  const LiquidGlassAdvDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currentLabel = items[value] ?? label;

    final menuItems = items.entries.map((e) {
      final isSelected = e.key == value;
      return GlassMenuItem(
        title: e.value,
        isSelected: isSelected,
        icon: isSelected
            ? const Icon(CupertinoIcons.checkmark, size: 14)
            : null,
        onTap: () => onChanged(e.key),
      );
    }).toList();

    return GlassPullDownButton(
      label: currentLabel,
      icon: const Icon(CupertinoIcons.chevron_down, size: 12),
      buttonHeight: 38,
      buttonWidth: double.infinity,
      buttonShape: const LiquidRoundedSuperellipse(borderRadius: 10),
      items: menuItems,
    );
  }
}
