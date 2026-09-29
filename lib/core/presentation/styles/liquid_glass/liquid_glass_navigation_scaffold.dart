import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:li_curriculum_table/core/presentation/styles/ui_style.dart';
import 'package:li_curriculum_table/core/presentation/widgets/liquid_glass_background.dart';

/// iOS 26 Liquid Glass navigation shell using GlassScaffold and GlassTabBar.bottom.
class LiquidGlassNavigationScaffold extends StatelessWidget {
  final Brightness brightness;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final List<NavigationItemConfig> items;
  final Widget body;
  final Widget? extraButton;

  const LiquidGlassNavigationScaffold({
    super.key,
    required this.brightness,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.items,
    required this.body,
    this.extraButton,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = brightness == Brightness.dark;

    return GlassScaffold(
      // The glass backdrop is captured once and reused while its size and
      // position stay unchanged. Rebuild the complete shell on a brightness
      // change so switching light/dark also invalidates that cached capture,
      // matching what a window resize previously forced.
      key: ValueKey(brightness),
      themeOverride: GlassThemeData(brightness: brightness),
      background: LiquidGlassBackground(isDark: isDark),
      backgroundColor: isDark
          ? LiquidGlassBackground.darkBaseColor
          : LiquidGlassBackground.lightBaseColor,
      statusBarStyle: isDark
          ? GlassStatusBarStyle.light
          : GlassStatusBarStyle.dark,
      settings: const LiquidGlassSettings(
        blur: 4,
        thickness: 10,
        glassColor: Color.fromRGBO(255, 255, 255, 0.08),
        lightAngle: 0.75 * math.pi,
        lightIntensity: 0.7,
        ambientStrength: 0,
        saturation: 1.2,
        refractiveIndex: 1.2,
        chromaticAberration: 0.01,
        specularSharpness: GlassSpecularSharpness.medium,
      ),
      extendBody: true,
      body: body,
      bottomBar: GlassTabBar.bottom(
        interactionBehavior: GlassInteractionBehavior.full,
        selectedIconColor: const Color(0xFFA855F7),
        iconSize: 28,
        labelFontSize: 10,
        iconLabelSpacing: 0,
        settings: const LiquidGlassSettings(
          glassColor: Color.fromRGBO(255, 255, 255, 0.08),
          thickness: 30,
          blur: 3,
          chromaticAberration: 0.01,
          lightAngle: 0.75 * math.pi,
          lightIntensity: 0.5,
          ambientStrength: 0,
          refractiveIndex: 1.2,
          saturation: 1.2,
          specularSharpness: GlassSpecularSharpness.medium,
        ),
        tabs: items
            .map(
              (item) => GlassTab(
                icon: item.icon,
                activeIcon: item.selectedIcon ?? item.icon,
                label: item.label,
              ),
            )
            .toList(),
        selectedIndex: currentIndex,
        onTabSelected: onIndexChanged,
        extraButton: extraButton is LiquidGlassExtraButtonWidget
            ? (extraButton as LiquidGlassExtraButtonWidget).config
            : null,
      ),
    );
  }
}

/// Widget wrapper that encapsulates [GlassTabBarExtraButton] for polymorphic shell building.
class LiquidGlassExtraButtonWidget extends StatelessWidget {
  final GlassTabBarExtraButton config;
  const LiquidGlassExtraButtonWidget(this.config, {super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
