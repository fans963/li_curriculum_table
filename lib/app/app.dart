import 'package:feedback/feedback.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/navigation/presentation/pages/main_screen.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' as flutter_material;
import 'package:flutter/cupertino.dart' as flutter_cupertino;
import 'package:li_curriculum_table/core/presentation/styles/styles.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';

// ignore_for_file: deprecated_member_use

const bool isWeb = kIsWeb;

class CurriculumTableApp extends SignalWidget {
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
      navigationBarLabelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
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

    return _modernThemeFromLegacy(legacyTheme, subThemes);
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

          final activeStyle = UiStyleRegistry.resolve(settings.designStyle);

          final app = MaterialApp(
            title: '🍐课表',
            localizationsDelegates: const [
              flutter_material.DefaultMaterialLocalizations.delegate,
              flutter_cupertino.DefaultCupertinoLocalizations.delegate,
            ],
            themeMode: settings.themeMode,
            theme: lightTheme,
            darkTheme: darkTheme,
            builder: (context, child) {
              final content = child ?? const SizedBox.shrink();
              final appTheme = Theme.of(context);
              final scheme = appTheme.colorScheme;
              // The app uses material_ui, while Liquid Glass and a few legacy
              // widgets read Flutter's own Material/Cupertino inherited themes.
              // Keep both trees on the same palette and brightness.
              final flutterScheme =
                  flutter_material.ColorScheme.fromSeed(
                    seedColor: scheme.primary,
                    brightness: scheme.brightness,
                  ).copyWith(
                    primary: scheme.primary,
                    onPrimary: scheme.onPrimary,
                    primaryContainer: scheme.primaryContainer,
                    onPrimaryContainer: scheme.onPrimaryContainer,
                    secondary: scheme.secondary,
                    onSecondary: scheme.onSecondary,
                    secondaryContainer: scheme.secondaryContainer,
                    onSecondaryContainer: scheme.onSecondaryContainer,
                    tertiary: scheme.tertiary,
                    onTertiary: scheme.onTertiary,
                    tertiaryContainer: scheme.tertiaryContainer,
                    onTertiaryContainer: scheme.onTertiaryContainer,
                    error: scheme.error,
                    onError: scheme.onError,
                    surface: scheme.surface,
                    onSurface: scheme.onSurface,
                    onSurfaceVariant: scheme.onSurfaceVariant,
                    outline: scheme.outline,
                    outlineVariant: scheme.outlineVariant,
                    surfaceContainerLowest: scheme.surfaceContainerLowest,
                    surfaceContainerLow: scheme.surfaceContainerLow,
                    surfaceContainer: scheme.surfaceContainer,
                    surfaceContainerHigh: scheme.surfaceContainerHigh,
                    surfaceContainerHighest: scheme.surfaceContainerHighest,
                  );
              return flutter_material.Theme(
                data: flutter_material.ThemeData(
                  useMaterial3: true,
                  colorScheme: flutterScheme,
                  scaffoldBackgroundColor: scheme.surface,
                ),
                child: flutter_cupertino.CupertinoTheme(
                  data: flutter_cupertino.CupertinoThemeData(
                    brightness: scheme.brightness,
                    primaryColor: scheme.primary,
                  ),
                  child: DefaultTextStyle(
                    // material_ui's MaterialApp deliberately uses a red,
                    // 48px, yellow-underlined fallback outside Material.
                    // Glass pages do not have Material ancestors.
                    style: (appTheme.textTheme.bodyMedium ?? const TextStyle())
                        .copyWith(
                          color: scheme.onSurface,
                          decoration: TextDecoration.none,
                        ),
                    // Keep the Navigator's inherited wrapper stable while
                    // the first-use appearance dialog previews either style.
                    // Glass widgets can coexist with this M3 compatibility
                    // layer; replacing it would dispose the open dialog.
                    child: const Material3ExpressiveStyle().wrapContent(
                      context: context,
                      child: content,
                      isDark: isDark,
                      colorScheme: scheme,
                    ),
                  ),
                ),
              );
            },
            home: const MainScreen(),
          );

          return activeStyle.wrapApp(
            child: app,
            lightScheme: lightTheme.colorScheme,
            darkScheme: darkTheme.colorScheme,
            isDark: isDark,
          );
        },
      ),
    );
  }
}
