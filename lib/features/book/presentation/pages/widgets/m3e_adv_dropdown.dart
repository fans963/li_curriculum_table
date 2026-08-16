import 'package:material_ui/material_ui.dart';
import 'package:m3e_core/m3e_core.dart';

/// A dropdown widget for Material advanced search (book tab).
class M3EAdvDropdown extends StatefulWidget {
  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;

  const M3EAdvDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  State<M3EAdvDropdown> createState() => _M3EAdvDropdownState();
}

class _M3EAdvDropdownState extends State<M3EAdvDropdown> {
  late final M3EDropdownController<String> _controller;

  @override
  void initState() {
    super.initState();
    _controller = M3EDropdownController<String>()..initialize();
    _sync();
  }

  @override
  void didUpdateWidget(covariant M3EAdvDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value || oldWidget.items != widget.items) {
      _sync();
    }
  }

  void _sync() {
    _controller.setItems(
      widget.items.entries
          .map(
            (e) => M3EDropdownItem(
              label: e.value,
              value: e.key,
              selected: e.key == widget.value,
            ),
          )
          .toList(),
    );
    _controller.selectWhere((i) => i.value == widget.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return M3EDropdownMenu<String>(
      singleSelect: true,
      showChipAnimation: false,
      items: const [],
      controller: _controller,
      onSelectionChanged: (selected) {
        if (selected.isNotEmpty) widget.onChanged(selected.first.value);
      },
      containerRadius: 12,
      fieldStyle: M3EDropdownFieldStyle(
        hintText: widget.label,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: BorderSide(color: cs.outlineVariant, width: 0.5),
        focusedBorder: BorderSide(color: cs.primary, width: 1),
        borderRadius: BorderRadius.circular(12),
        selectedBorderRadius: 12,
      ),
      dropdownStyle: const M3EDropdownStyle(
        maxHeight: 300,
        containerRadius: 12,
      ),
      itemStyle: M3EDropdownItemStyle(
        outerRadius: 10,
        innerRadius: 6,
        selectedIcon: Icon(Icons.check, size: 18, color: cs.primary),
      ),
    );
  }
}
