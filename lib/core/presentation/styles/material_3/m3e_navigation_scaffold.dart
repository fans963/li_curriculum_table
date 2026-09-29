import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:li_curriculum_table/core/presentation/styles/ui_style.dart';

/// Material 3 Expressive navigation shell using M3ENavigationBar.
class M3eNavigationScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final List<NavigationItemConfig> items;
  final Widget body;
  final Widget? floatingActionButton;

  const M3eNavigationScaffold({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.items,
    required this.body,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: M3ENavigationBar(
        selectedIndex: currentIndex,
        indicatorStyle: M3ENavBarIndicatorStyle.pill,
        labelBehavior: M3ENavBarLabelBehavior.alwaysShow,
        shapeFamily: M3ENavBarShapeFamily.square,
        onDestinationSelected: onIndexChanged,
        destinations: items
            .map(
              (item) => M3ENavigationBarDestination(
                icon: item.icon,
                selectedIcon: item.selectedIcon ?? item.icon,
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}
