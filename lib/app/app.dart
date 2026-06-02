import 'package:feedback/feedback.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/navigation/presentation/pages/main_screen.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

const bool isWeb = kIsWeb;

class CurriculumTableApp extends StatelessWidget {
  const CurriculumTableApp({super.key});

  ThemeData _buildTheme({
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

    // M3 Expressive: bolder shapes, more vibrant colors, expressive radii
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
      navigationBarLabelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      cardRadius: 28,
      popupMenuRadius: 16,
      dialogRadius: 28,
      timePickerDialogRadius: 16,
      chipRadius: 20,
      elevatedButtonRadius: 20,
      filledButtonRadius: 20,
      outlinedButtonRadius: 20,
      textButtonRadius: 20,
      segmentedButtonRadius: 20,
      snackBarRadius: 16,
      appBarBackgroundSchemeColor: SchemeColor.surface,
      tabBarIndicatorSchemeColor: SchemeColor.primary,
    );

    // On Web, use system fonts to avoid downloading ~200KB+ of Google Fonts.
    const String? webFontFamily = kIsWeb ? 'Noto Sans SC' : null;

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
    ColorScheme? dynamicScheme,
  }) {
    final scheme = dynamicScheme ??
        ColorScheme.fromSeed(seedColor: seedColor, brightness: brightness);
    final primaryColor = scheme.primary;

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
          fontSize: 11,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.12,
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

    return SignalBuilder(builder: (context) {
      final settings = settingsCtrl.state.value;

      return BetterFeedback(
        localeOverride: const Locale('zh', 'CN'),
        child: DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
            final ColorScheme? lightScheme =
                settings.useDynamicColor ? lightDynamic : null;
            final ColorScheme? darkScheme =
                settings.useDynamicColor ? darkDynamic : null;

            final isDark = settings.themeMode == ThemeMode.dark ||
                (settings.themeMode == ThemeMode.system &&
                    MediaQuery.platformBrightnessOf(context) ==
                        Brightness.dark);

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
                if (AdaptiveStyle.isCupertino(settings.designStyle)) {
                  return CupertinoTheme(
                    data: cupertinoTheme,
                    child: child!,
                  );
                }
                return child!;
              },
              home: const MainScreen(),
            );
          },
        ),
      );
    });
  }
}
