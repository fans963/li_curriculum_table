import 'package:feedback/feedback.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/navigation/presentation/pages/main_screen.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:m3e_design/m3e_design.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' as legacy;
import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';

// ignore_for_file: deprecated_member_use

const bool isWeb = kIsWeb;

class CurriculumTableApp extends SignalWidget {
  const CurriculumTableApp({super.key});

  ThemeData _buildTheme({
    required Brightness brightness,
    required Color seedColor,
    legacy.ColorScheme? dynamicScheme,
    ColorSchemeType colorSchemeType = ColorSchemeType.tonalSpot,
  }) {
    final fallbackScheme = legacy.ColorScheme.fromSeed(
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
          legacy.NavigationDestinationLabelBehavior.alwaysShow,
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

    return _modernThemeFromLegacy(
      withM3ETheme(
        brightness == Brightness.dark
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
              ),
      ),
    );
  }

  ThemeData _modernThemeFromLegacy(legacy.ThemeData theme) {
    return ThemeData(
      useMaterial3: true,
      platform: theme.platform,
      colorScheme: _modernColorScheme(theme.colorScheme),
      textTheme: _modernTextTheme(theme.textTheme),
      primaryTextTheme: _modernTextTheme(theme.primaryTextTheme),
      visualDensity: VisualDensity(
        horizontal: theme.visualDensity.horizontal,
        vertical: theme.visualDensity.vertical,
      ),
    );
  }

  ColorScheme _modernColorScheme(legacy.ColorScheme scheme) {
    return ColorScheme(
      brightness: scheme.brightness,
      primary: scheme.primary,
      onPrimary: scheme.onPrimary,
      primaryContainer: scheme.primaryContainer,
      onPrimaryContainer: scheme.onPrimaryContainer,
      primaryFixed: scheme.primaryFixed,
      primaryFixedDim: scheme.primaryFixedDim,
      onPrimaryFixed: scheme.onPrimaryFixed,
      onPrimaryFixedVariant: scheme.onPrimaryFixedVariant,
      secondary: scheme.secondary,
      onSecondary: scheme.onSecondary,
      secondaryContainer: scheme.secondaryContainer,
      onSecondaryContainer: scheme.onSecondaryContainer,
      secondaryFixed: scheme.secondaryFixed,
      secondaryFixedDim: scheme.secondaryFixedDim,
      onSecondaryFixed: scheme.onSecondaryFixed,
      onSecondaryFixedVariant: scheme.onSecondaryFixedVariant,
      tertiary: scheme.tertiary,
      onTertiary: scheme.onTertiary,
      tertiaryContainer: scheme.tertiaryContainer,
      onTertiaryContainer: scheme.onTertiaryContainer,
      tertiaryFixed: scheme.tertiaryFixed,
      tertiaryFixedDim: scheme.tertiaryFixedDim,
      onTertiaryFixed: scheme.onTertiaryFixed,
      onTertiaryFixedVariant: scheme.onTertiaryFixedVariant,
      error: scheme.error,
      onError: scheme.onError,
      errorContainer: scheme.errorContainer,
      onErrorContainer: scheme.onErrorContainer,
      surface: scheme.surface,
      onSurface: scheme.onSurface,
      surfaceDim: scheme.surfaceDim,
      surfaceBright: scheme.surfaceBright,
      surfaceContainerLowest: scheme.surfaceContainerLowest,
      surfaceContainerLow: scheme.surfaceContainerLow,
      surfaceContainer: scheme.surfaceContainer,
      surfaceContainerHigh: scheme.surfaceContainerHigh,
      surfaceContainerHighest: scheme.surfaceContainerHighest,
      onSurfaceVariant: scheme.onSurfaceVariant,
      outline: scheme.outline,
      outlineVariant: scheme.outlineVariant,
      shadow: scheme.shadow,
      scrim: scheme.scrim,
      inverseSurface: scheme.inverseSurface,
      onInverseSurface: scheme.onInverseSurface,
      inversePrimary: scheme.inversePrimary,
      surfaceTint: scheme.surfaceTint,
      background: scheme.background,
      onBackground: scheme.onBackground,
      surfaceVariant: scheme.surfaceVariant,
    );
  }

  TextTheme _modernTextTheme(legacy.TextTheme textTheme) {
    return TextTheme(
      displayLarge: textTheme.displayLarge,
      displayMedium: textTheme.displayMedium,
      displaySmall: textTheme.displaySmall,
      headlineLarge: textTheme.headlineLarge,
      headlineMedium: textTheme.headlineMedium,
      headlineSmall: textTheme.headlineSmall,
      titleLarge: textTheme.titleLarge,
      titleMedium: textTheme.titleMedium,
      titleSmall: textTheme.titleSmall,
      bodyLarge: textTheme.bodyLarge,
      bodyMedium: textTheme.bodyMedium,
      bodySmall: textTheme.bodySmall,
      labelLarge: textTheme.labelLarge,
      labelMedium: textTheme.labelMedium,
      labelSmall: textTheme.labelSmall,
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

  CupertinoThemeData _buildCupertinoTheme({
    required Brightness brightness,
    required Color seedColor,
    legacy.ColorScheme? dynamicScheme,
  }) {
    final scheme =
        dynamicScheme ??
        legacy.ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: brightness,
        );
    final primaryColor = scheme.primary;

    // iOS 26 Liquid Glass typography: monochromatic adaptive, crisp weights
    return CupertinoThemeData(
      brightness: brightness,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: brightness == Brightness.dark
          ? CupertinoColors.systemGroupedBackground.darkColor
          : CupertinoColors.systemGroupedBackground.color,
      textTheme: CupertinoTextThemeData(
        primaryColor: primaryColor,
        textStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.41,
          color: brightness == Brightness.dark
              ? CupertinoColors.label.darkColor
              : CupertinoColors.label.color,
        ),
        actionTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.41,
          color: primaryColor,
        ),
        tabLabelTextStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.06,
          color: brightness == Brightness.dark
              ? CupertinoColors.label.darkColor
              : CupertinoColors.label.color,
        ),
        navTitleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.41,
          color: brightness == Brightness.dark
              ? CupertinoColors.label.darkColor
              : CupertinoColors.label.color,
        ),
        navLargeTitleTextStyle: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.37,
          color: brightness == Brightness.dark
              ? CupertinoColors.label.darkColor
              : CupertinoColors.label.color,
        ),
        navActionTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.41,
          color: primaryColor,
        ),
        pickerTextStyle: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.41,
          color: brightness == Brightness.dark
              ? CupertinoColors.label.darkColor
              : CupertinoColors.label.color,
        ),
        dateTimePickerTextStyle: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.41,
          color: brightness == Brightness.dark
              ? CupertinoColors.label.darkColor
              : CupertinoColors.label.color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsCtrl = sl<SettingsController>();
    final settings = settingsCtrl.state.value;

    return BetterFeedback(
      localeOverride: const Locale('zh', 'CN'),
      child: DynamicColorBuilder(
        builder: (lightDynamic, darkDynamic) {
          final legacy.ColorScheme? lightScheme = settings.useDynamicColor
              ? lightDynamic
              : null;
          final legacy.ColorScheme? darkScheme = settings.useDynamicColor
              ? darkDynamic
              : null;

          final isDark =
              settings.themeMode == ThemeMode.dark ||
              (settings.themeMode == ThemeMode.system &&
                  MediaQuery.platformBrightnessOf(context) == Brightness.dark);

          final cupertinoTheme = _buildCupertinoTheme(
            brightness: isDark ? Brightness.dark : Brightness.light,
            seedColor: settings.seedColor,
            dynamicScheme: isDark ? darkScheme : lightScheme,
          );

          return MaterialApp(
            title: '',
            themeMode: settings.themeMode,
            theme: _buildTheme(
              brightness: Brightness.light,
              seedColor: settings.seedColor,
              dynamicScheme: lightScheme,
              colorSchemeType: settings.colorSchemeType,
            ),
            darkTheme: _buildTheme(
              brightness: Brightness.dark,
              seedColor: settings.seedColor,
              dynamicScheme: darkScheme,
              colorSchemeType: settings.colorSchemeType,
            ),
            builder: (context, child) {
              final content = child ?? const SizedBox.shrink();
              if (AdaptiveStyle.isCupertino(settings.designStyle)) {
                return CupertinoUiCompatibilityBridge(
                  child: CupertinoTheme(
                    data: cupertinoTheme,
                    child: content,
                  ),
                );
              }
              return MaterialUiCompatibilityBridge(child: content);
            },
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}
