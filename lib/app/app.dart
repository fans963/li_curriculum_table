import 'package:li_curriculum_table/features/navigation/presentation/pages/main_screen.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

class CurriculumTableApp extends StatelessWidget {
  const CurriculumTableApp({super.key});

  ThemeData _buildTheme({
    required Brightness brightness,
    ColorScheme? dynamicScheme,
  }) {
    final fallbackScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0A7C6D),
      brightness: brightness,
    );
    final scheme = dynamicScheme ?? fallbackScheme;
    final colors = FlexSchemeColor(
      primary: scheme.primary,
      primaryContainer: scheme.primaryContainer,
      secondary: scheme.secondary,
      secondaryContainer: scheme.secondaryContainer,
      tertiary: scheme.tertiary,
      tertiaryContainer: scheme.tertiaryContainer,
      appBarColor: scheme.surface,
      error: scheme.error,
    );

    final subThemes = FlexSubThemesData(
      defaultRadius: 12,
      blendOnLevel: 14,
      blendOnColors: true,
      useMaterial3Typography: true,
      interactionEffects: true,
      tintedDisabledControls: true,
      inputDecoratorBorderType: FlexInputBorderType.outline,
      inputDecoratorUnfocusedHasBorder: true,
      navigationBarIndicatorSchemeColor: SchemeColor.secondaryContainer,
      navigationBarLabelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    );

    return brightness == Brightness.dark
        ? FlexThemeData.dark(
            colors: colors,
            useMaterial3: true,
            swapLegacyOnMaterial3: true,
            visualDensity: FlexColorScheme.comfortablePlatformDensity,
            subThemesData: subThemes,
            keyColors: const FlexKeyColors(
              useSecondary: true,
              useTertiary: true,
              keepPrimary: true,
            ),
            tones: FlexTones.material(Brightness.dark),
          )
        : FlexThemeData.light(
            colors: colors,
            useMaterial3: true,
            swapLegacyOnMaterial3: true,
            visualDensity: FlexColorScheme.comfortablePlatformDensity,
            subThemesData: subThemes,
            keyColors: const FlexKeyColors(
              useSecondary: true,
              useTertiary: true,
              keepPrimary: true,
            ),
            tones: FlexTones.material(Brightness.light),
          );
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp(
          title: '',
          themeMode: ThemeMode.system,
          theme: _buildTheme(
            brightness: Brightness.light,
            dynamicScheme: lightDynamic,
          ),
          darkTheme: _buildTheme(
            brightness: Brightness.dark,
            dynamicScheme: darkDynamic,
          ),
          home: const MainScreen(),
        );
      },
    );
  }
}
