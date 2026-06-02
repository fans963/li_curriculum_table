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

  SecureSettingsLocalDataSource(this._store);

  Future<AppSettings> loadSettings() async {
    final data = await _store.readAll([
      _kProxyEnabled, _kProxyPort, _kWeeklyScroll,
      _kThemeMode, _kSeedColor, _kUseDynamicColor,
      _kDesignStyle,
    ]);

    final enabled = data[_kProxyEnabled] == 'true';
    final port = int.tryParse(data[_kProxyPort] ?? '9999') ?? 9999;
    final weekly = data[_kWeeklyScroll] == 'true';

    final themeMode = ThemeMode.values.firstWhere(
      (e) => e.name == data[_kThemeMode],
      orElse: () => ThemeMode.system,
    );
    final seedColor = Color(int.tryParse(data[_kSeedColor] ?? '') ?? 0xFF0A7C6D);
    final useDynamic = data[_kUseDynamicColor] != 'false'; // default true
    final designStyle = DesignStyle.values.firstWhere(
      (e) => e.name == data[_kDesignStyle],
      orElse: () => DesignStyle.system,
    );

    return AppSettings(
      proxyEnabled: enabled,
      proxyPort: port,
      weeklyScroll: weekly,
      themeMode: themeMode,
      seedColor: seedColor,
      useDynamicColor: useDynamic,
      designStyle: designStyle,
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
    });
  }
}

class SettingsRepositoryImpl implements SettingsRepository {
  final SecureSettingsLocalDataSource _localDataSource;

  SettingsRepositoryImpl(this._localDataSource);

  @override
  Future<AppSettings> loadSettings() => _localDataSource.loadSettings();

  @override
  Future<void> saveSettings(AppSettings settings) => _localDataSource.saveSettings(settings);
}
