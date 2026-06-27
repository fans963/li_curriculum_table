import 'package:flutter/material.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/features/timetable/data/datasources/secure_storage_store.dart';

class SecureSettingsLocalDataSource {
  final SecureStorageStore _store;

  static const _kProxyEnabled = 'proxy_enabled';
  static const _kProxyPort = 'proxy_port';
  static const _kWeeklyScroll = 'weekly_scroll';
  static const _kThemeMode = 'theme_mode';
  static const _kSeedColor = 'seed_color';
  static const _kUseDynamicColor = 'use_dynamic_color';
  static const _kDesignStyle = 'design_style';
  static const _kColorSchemeType = 'color_scheme_type';
  static const _kEnableBookCover = 'enable_book_cover';
  static const _kCurrentTerm = 'current_term';
  static const _kAutoSizeText = 'auto_size_text';
  static const _kAutoSizeMinFontSize = 'auto_size_min_font_size';
  static const _kTimetableTextMaxLines = 'timetable_text_max_lines';
  static const _kTimetableTextFontSize = 'timetable_text_font_size';
  static const _kDaysVisibleCount = 'days_visible_count';
  static const _kTermsAccepted = 'terms_accepted';
  SecureSettingsLocalDataSource(this._store);

  Future<AppSettings> loadSettings() async {
    final data = await _store.readAll([
      _kProxyEnabled,
      _kProxyPort,
      _kWeeklyScroll,
      _kThemeMode,
      _kSeedColor,
      _kUseDynamicColor,
      _kDesignStyle,
      _kColorSchemeType,
      _kEnableBookCover,
      _kCurrentTerm,
      _kAutoSizeText,
      _kAutoSizeMinFontSize,
      _kTimetableTextMaxLines,
      _kTimetableTextFontSize,
      _kDaysVisibleCount,
      _kTermsAccepted,
    ]);

    final enabled = data[_kProxyEnabled] == 'true';
    final port = int.tryParse(data[_kProxyPort] ?? '9999') ?? 9999;
    final weekly = data[_kWeeklyScroll] == 'true';

    final themeMode = ThemeMode.values.firstWhere(
      (e) => e.name == data[_kThemeMode],
      orElse: () => ThemeMode.system,
    );
    final seedColor = Color(
      int.tryParse(data[_kSeedColor] ?? '') ?? 0xFF0A7C6D,
    );
    final useDynamic = data[_kUseDynamicColor] != 'false'; // default true
    final designStyle = DesignStyle.values.firstWhere(
      (e) => e.name == data[_kDesignStyle],
      orElse: () => DesignStyle.system,
    );
    final colorSchemeType = ColorSchemeType.values.firstWhere(
      (e) => e.name == data[_kColorSchemeType],
      orElse: () => ColorSchemeType.tonalSpot,
    );
    final enableBookCover = data[_kEnableBookCover] == 'true'; // default false
    final currentTerm = data[_kCurrentTerm] ?? '';
    final autoSizeText = data[_kAutoSizeText] != 'false'; // default true
    final autoSizeMinFontSize =
        double.tryParse(data[_kAutoSizeMinFontSize] ?? '') ?? 6.0;
    final timetableTextMaxLines =
        int.tryParse(data[_kTimetableTextMaxLines] ?? '') ?? 2;
    final timetableTextFontSize =
        double.tryParse(data[_kTimetableTextFontSize] ?? '') ?? 11.0;
    final daysVisibleCount = int.tryParse(data[_kDaysVisibleCount] ?? '7') ?? 7;
    final termsAccepted = data[_kTermsAccepted] == 'true'; // default false

    return AppSettings(
      proxyEnabled: enabled,
      proxyPort: port,
      weeklyScroll: weekly,
      themeMode: themeMode,
      seedColor: seedColor,
      useDynamicColor: useDynamic,
      designStyle: designStyle,
      colorSchemeType: colorSchemeType,
      enableBookCover: enableBookCover,
      currentTerm: currentTerm,
      autoSizeText: autoSizeText,
      autoSizeMinFontSize: autoSizeMinFontSize,
      timetableTextMaxLines: timetableTextMaxLines,
      timetableTextFontSize: timetableTextFontSize,
      daysVisibleCount: daysVisibleCount,
      termsAccepted: termsAccepted,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _store.writeAll({
      _kProxyEnabled: settings.proxyEnabled.toString(),
      _kProxyPort: settings.proxyPort.toString(),
      _kWeeklyScroll: settings.weeklyScroll.toString(),
      _kThemeMode: settings.themeMode.name,
      _kSeedColor: settings.seedColor.toARGB32().toString(),
      _kUseDynamicColor: settings.useDynamicColor.toString(),
      _kDesignStyle: settings.designStyle.name,
      _kColorSchemeType: settings.colorSchemeType.name,
      _kEnableBookCover: settings.enableBookCover.toString(),
      _kCurrentTerm: settings.currentTerm,
      _kAutoSizeText: settings.autoSizeText.toString(),
      _kAutoSizeMinFontSize: settings.autoSizeMinFontSize.toString(),
      _kTimetableTextMaxLines: settings.timetableTextMaxLines.toString(),
      _kTimetableTextFontSize: settings.timetableTextFontSize.toString(),
      _kDaysVisibleCount: settings.daysVisibleCount.toString(),
      _kTermsAccepted: settings.termsAccepted.toString(),
    });
  }
}

class SettingsRepositoryImpl implements SettingsRepository {
  final SecureSettingsLocalDataSource _localDataSource;

  SettingsRepositoryImpl(this._localDataSource);

  @override
  Future<AppSettings> loadSettings() => _localDataSource.loadSettings();

  @override
  Future<void> saveSettings(AppSettings settings) =>
      _localDataSource.saveSettings(settings);
}
