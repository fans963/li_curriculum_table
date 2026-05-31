import 'package:flutter/material.dart';

class AppSettings {
  final bool proxyEnabled;
  final int proxyPort;
  final bool weeklyScroll;
  final ThemeMode themeMode;
  final Color seedColor;
  final bool useDynamicColor;

  const AppSettings({
    required this.proxyEnabled,
    required this.proxyPort,
    required this.weeklyScroll,
    required this.themeMode,
    required this.seedColor,
    required this.useDynamicColor,
  });

  factory AppSettings.defaultSettings() {
    return const AppSettings(
      proxyEnabled: false,
      proxyPort: 9999,
      weeklyScroll: false,
      themeMode: ThemeMode.system,
      seedColor: Color(0xFF0A7C6D),
      useDynamicColor: true,
    );
  }

  AppSettings copyWith({
    bool? proxyEnabled,
    int? proxyPort,
    bool? weeklyScroll,
    ThemeMode? themeMode,
    Color? seedColor,
    bool? useDynamicColor,
  }) {
    return AppSettings(
      proxyEnabled: proxyEnabled ?? this.proxyEnabled,
      proxyPort: proxyPort ?? this.proxyPort,
      weeklyScroll: weeklyScroll ?? this.weeklyScroll,
      themeMode: themeMode ?? this.themeMode,
      seedColor: seedColor ?? this.seedColor,
      useDynamicColor: useDynamicColor ?? this.useDynamicColor,
    );
  }
}

abstract class SettingsRepository {
  Future<AppSettings> loadSettings();
  Future<void> saveSettings(AppSettings settings);
}
