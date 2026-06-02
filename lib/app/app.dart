import 'package:feedback/feedback.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
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

  CupertinoThemeData _buildCupertinoTheme({
    required Brightness brightness,
    required Color seedColor,
    ColorScheme? dynamicScheme,
  }) {
    final scheme = dynamicScheme ??
        ColorScheme.fromSeed(seedColor: seedColor, brightness: brightness);
    return CupertinoThemeData(
      brightness: brightness,
      primaryColor: scheme.primary,
      scaffoldBackgroundColor: scheme.surface,
      barBackgroundColor: scheme.surface.withValues(alpha: 0.9),
      textTheme: CupertinoTextThemeData(
        primaryColor: scheme.primary,
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
              ),
              darkTheme: _buildTheme(
                brightness: Brightness.dark,
                seedColor: settings.seedColor,
                dynamicScheme: darkScheme,
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
