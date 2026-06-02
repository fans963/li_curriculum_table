import 'package:flutter/material.dart';

/// Design style for the app UI.
enum DesignStyle {
  /// Material Design 3 (Android/Google style)
  material,

  /// Cupertino design (iOS/Apple style)
  cupertino,

  /// Follow the current platform (Android → Material, iOS → Cupertino)
  system;

  String get label {
    switch (this) {
      case DesignStyle.material:
        return 'Material';
      case DesignStyle.cupertino:
        return 'Cupertino';
      case DesignStyle.system:
        return '跟随系统';
    }
  }

  IconData get icon {
    switch (this) {
      case DesignStyle.material:
        return Icons.android;
      case DesignStyle.cupertino:
        return Icons.apple;
      case DesignStyle.system:
        return Icons.phone_android;
    }
  }
}

class AppSettings {
  final bool proxyEnabled;
  final int proxyPort;
  final bool weeklyScroll;
  final ThemeMode themeMode;
  final Color seedColor;
  final bool useDynamicColor;
  final DesignStyle designStyle;

  const AppSettings({
    required this.proxyEnabled,
    required this.proxyPort,
    required this.weeklyScroll,
    required this.themeMode,
    required this.seedColor,
    required this.useDynamicColor,
    this.designStyle = DesignStyle.system,
  });

  factory AppSettings.defaultSettings() {
    return const AppSettings(
      proxyEnabled: false,
      proxyPort: 9999,
      weeklyScroll: false,
      themeMode: ThemeMode.system,
      seedColor: Color(0xFF0A7C6D),
      useDynamicColor: true,
      designStyle: DesignStyle.system,
    );
  }

  AppSettings copyWith({
    bool? proxyEnabled,
    int? proxyPort,
    bool? weeklyScroll,
    ThemeMode? themeMode,
    Color? seedColor,
    bool? useDynamicColor,
    DesignStyle? designStyle,
  }) {
    return AppSettings(
      proxyEnabled: proxyEnabled ?? this.proxyEnabled,
      proxyPort: proxyPort ?? this.proxyPort,
      weeklyScroll: weeklyScroll ?? this.weeklyScroll,
      themeMode: themeMode ?? this.themeMode,
      seedColor: seedColor ?? this.seedColor,
      useDynamicColor: useDynamicColor ?? this.useDynamicColor,
      designStyle: designStyle ?? this.designStyle,
    );
  }
}

abstract class SettingsRepository {
  Future<AppSettings> loadSettings();
  Future<void> saveSettings(AppSettings settings);
}
