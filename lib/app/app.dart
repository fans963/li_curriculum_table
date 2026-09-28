import 'package:feedback/feedback.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/navigation/presentation/pages/main_screen.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart' as m3e_new;
import 'package:signals/signals_flutter.dart';

// ignore_for_file: deprecated_member_use

const bool isWeb = kIsWeb;

class _ThemeBundle {
  const _ThemeBundle({required this.modern, required this.expressive});

  final ThemeData modern;
  final m3e_new.M3EThemeData expressive;
}

class CurriculumTableApp extends SignalWidget {
  const CurriculumTableApp({super.key});

  _ThemeBundle _buildTheme({
    required Brightness brightness,
    required Color seedColor,
    ColorScheme? dynamicScheme,
    ColorSchemeType colorSchemeType = ColorSchemeType.tonalSpot,
  }) {
    final fallbackScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
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

    // M3 Expressive: bolder shapes, deeper tonal palettes, expressive radii
    // Shape tokens: large=20, xLarge=28, xxLarge=32 per M3 Expressive spec
    final subThemes = FlexSubThemesData(
      defaultRadius: 28,
      blendOnLevel: 10,
      blendOnColors: true,
      useMaterial3Typography: true,
      interactionEffects: true,
      tintedDisabledControls: true,
      inputDecoratorBorderType: FlexInputBorderType.outline,
      inputDecoratorRadius: 16.0,
      inputDecoratorUnfocusedHasBorder: true,
      inputDecoratorFocusedHasBorder: true,
      inputDecoratorBackgroundAlpha: 5,
      navigationBarIndicatorSchemeColor: SchemeColor.primaryContainer,
      navigationBarLabelBehavior:
          NavigationDestinationLabelBehavior.alwaysShow,
      // Expressive shape hierarchy: cards & dialogs get xxLarge (32)
      cardRadius: 28,
      dialogRadius: 32,
      popupMenuRadius: 20,
      timePickerDialogRadius: 20,
      // Buttons: large (20) per expressive spec
      chipRadius: 20,
      elevatedButtonRadius: 20,
      filledButtonRadius: 20,
      outlinedButtonRadius: 20,
      textButtonRadius: 20,
      segmentedButtonRadius: 20,
      fabRadius: 28,
      snackBarRadius: 20,
      appBarBackgroundSchemeColor: SchemeColor.surface,
      tabBarIndicatorSchemeColor: SchemeColor.primary,
    );

    // On Web, use system fonts to avoid downloading ~200KB+ of Google Fonts.
    const String? webFontFamily = kIsWeb ? 'Noto Sans SC' : null;

    final legacyTheme = brightness == Brightness.dark
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
            tones: _flexTones(colorSchemeType, Brightness.dark),
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
            tones: _flexTones(colorSchemeType, Brightness.light),
          );

    final modern = _modernThemeFromLegacy(legacyTheme, subThemes);
    return _ThemeBundle(
      modern: modern,
      expressive: m3e_new.M3EThemeData.fromMaterial(modern),
    );
  }

  ThemeData _modernThemeFromLegacy(
    ThemeData theme,
    FlexSubThemesData subThemes,
  ) {
    final scheme = theme.colorScheme;
    final defaultRadius = subThemes.defaultRadius ?? 28;
    final cardRadius = subThemes.cardRadius ?? defaultRadius;
    final dialogRadius = subThemes.dialogRadius ?? 32;
    final inputRadius = subThemes.inputDecoratorRadius ?? 16;

    return theme.copyWith(
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(dialogRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
    );
  }

  FlexTones _flexTones(ColorSchemeType type, Brightness brightness) {
    switch (type) {
      case ColorSchemeType.tonalSpot:
        return FlexTones.material(brightness);
      case ColorSchemeType.expressive:
        return FlexTones.vivid(brightness);
      case ColorSchemeType.vivid:
        return FlexTones.ultraContrast(brightness);
      case ColorSchemeType.jolly:
        return FlexTones.jolly(brightness);
      case ColorSchemeType.highContrast:
        return FlexTones.highContrast(brightness);
      case ColorSchemeType.neutral:
        return FlexTones.soft(brightness);
      case ColorSchemeType.monochrome:
        return FlexTones.oneHue(brightness);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsCtrl = sl<SettingsController>();
    final settings = settingsCtrl.state.value;

    return BetterFeedback(
      localeOverride: const Locale('zh', 'CN'),
      child: DynamicColorBuilder(
        builder: (lightDynamic, darkDynamic) {
          final ColorScheme? lightScheme = settings.useDynamicColor
              ? lightDynamic
              : null;
          final ColorScheme? darkScheme = settings.useDynamicColor
              ? darkDynamic
              : null;

          final isDark =
              settings.themeMode == ThemeMode.dark ||
              (settings.themeMode == ThemeMode.system &&
                  MediaQuery.platformBrightnessOf(context) == Brightness.dark);

          final lightTheme = _buildTheme(
            brightness: Brightness.light,
            seedColor: settings.seedColor,
            dynamicScheme: lightScheme,
            colorSchemeType: settings.colorSchemeType,
          );
          final darkTheme = _buildTheme(
            brightness: Brightness.dark,
            seedColor: settings.seedColor,
            dynamicScheme: darkScheme,
            colorSchemeType: settings.colorSchemeType,
          );

          return MaterialApp(
            title: '🍐课表',
            themeMode: settings.themeMode,
            theme: lightTheme.modern,
            darkTheme: darkTheme.modern,
            builder: (context, child) {
              final content = child ?? const SizedBox.shrink();
              final m3eTheme = m3e_new.M3ETheme(
                data: isDark ? darkTheme.expressive : lightTheme.expressive,
                child: content,
              );
              return MaterialUiCompatibilityBridge(child: m3eTheme);
            },
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}
