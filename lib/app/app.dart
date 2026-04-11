import 'package:li_curriculum_table/features/navigation/presentation/pages/main_screen.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
      defaultRadius: 16,
      blendOnLevel: 10,
      blendOnColors: true,
      useMaterial3Typography: true,
      interactionEffects: true,
      tintedDisabledControls: true,
      inputDecoratorBorderType: FlexInputBorderType.outline,
      inputDecoratorRadius: 12.0,
      inputDecoratorUnfocusedHasBorder: true,
      inputDecoratorFocusedHasBorder: true,
      inputDecoratorBackgroundAlpha: 5,
      navigationBarIndicatorSchemeColor: SchemeColor.primaryContainer,
      navigationBarLabelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      cardRadius: 16,
      popupMenuRadius: 12,
      dialogRadius: 16,
      timePickerDialogRadius: 12,
    );

    // On Web, use system fonts to avoid downloading ~200KB+ of Google Fonts.
    // Material Icons are a separate bundled font and remain unaffected.
    const String? webFontFamily = kIsWeb
        ? 'system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, "Noto Sans SC", sans-serif'
        : null;

    return brightness == Brightness.dark
        ? FlexThemeData.dark(
            colors: colors,
            fontFamily: webFontFamily,
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
            fontFamily: webFontFamily,
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
