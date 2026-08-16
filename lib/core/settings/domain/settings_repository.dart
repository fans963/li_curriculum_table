import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// Color scheme generation type (M3 color harmonization).
enum ColorSchemeType {
  /// Default M3 tonalSpot — balanced, harmonious colors
  tonalSpot,

  /// More vibrant and saturated colors
  expressive,

  /// Maximum saturation, bold colors
  vivid,

  /// Warm, cheerful tones
  jolly,

  /// High contrast for accessibility
  highContrast,

  /// Muted, neutral tones
  neutral,

  /// Single hue variations
  monochrome;

  String get label {
    switch (this) {
      case ColorSchemeType.tonalSpot:
        return 'Tonal Spot';
      case ColorSchemeType.expressive:
        return 'Expressive';
      case ColorSchemeType.vivid:
        return 'Vivid';
      case ColorSchemeType.jolly:
        return 'Jolly';
      case ColorSchemeType.highContrast:
        return '高对比度';
      case ColorSchemeType.neutral:
        return 'Neutral';
      case ColorSchemeType.monochrome:
        return '单色';
    }
  }

  String get description {
    switch (this) {
      case ColorSchemeType.tonalSpot:
        return '默认和谐配色';
      case ColorSchemeType.expressive:
        return '鲜明活力';
      case ColorSchemeType.vivid:
        return '高饱和度';
      case ColorSchemeType.jolly:
        return '温暖欢快';
      case ColorSchemeType.highContrast:
        return '无障碍高对比';
      case ColorSchemeType.neutral:
        return '柔和中性';
      case ColorSchemeType.monochrome:
        return '单色系';
    }
  }

  IconData get icon {
    switch (this) {
      case ColorSchemeType.tonalSpot:
        return Icons.palette;
      case ColorSchemeType.expressive:
        return Icons.auto_awesome;
      case ColorSchemeType.vivid:
        return Icons.brightness_7;
      case ColorSchemeType.jolly:
        return Icons.emoji_emotions;
      case ColorSchemeType.highContrast:
        return Icons.contrast;
      case ColorSchemeType.neutral:
        return Icons.water_drop;
      case ColorSchemeType.monochrome:
        return Icons.gradient;
    }
  }
}

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
  final ColorSchemeType colorSchemeType;
  final bool enableBookCover;

  /// Current semester identifier, e.g. "2025-2026-1". Empty string means unset.
  final String currentTerm;

  /// Whether to use AutoSizeText for timetable cell text (course name & location).
  final bool autoSizeText;

  /// Minimum font size when [autoSizeText] is ON.
  final double autoSizeMinFontSize;

  /// Max lines for course name & location when [autoSizeText] is OFF.
  final int timetableTextMaxLines;

  /// Font size for course name when [autoSizeText] is OFF.
  final double timetableTextFontSize;

  /// Number of days to show simultaneously in the timetable week view.
  /// Only effective when [weeklyScroll] is false (free scrolling mode).
  /// Default is 7 (full week).
  final int daysVisibleCount;

  /// Whether the user has accepted the terms of service.
  final bool termsAccepted;

  const AppSettings({
    required this.proxyEnabled,
    required this.proxyPort,
    required this.weeklyScroll,
    required this.themeMode,
    required this.seedColor,
    required this.useDynamicColor,
    this.designStyle = DesignStyle.system,
    this.colorSchemeType = ColorSchemeType.tonalSpot,
    required this.enableBookCover,
    this.currentTerm = '',
    this.autoSizeText = true,
    this.autoSizeMinFontSize = 6.0,
    this.timetableTextMaxLines = 2,
    this.timetableTextFontSize =
        11.0, // overridden on mobile in defaultSettings()
    this.daysVisibleCount = 7,
    this.termsAccepted = false,
  });

  factory AppSettings.defaultSettings() {
    final isMobile =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    return AppSettings(
      proxyEnabled: false,
      proxyPort: 9999,
      weeklyScroll: false,
      themeMode: ThemeMode.system,
      seedColor: const Color(0xFF0A7C6D),
      useDynamicColor: true,
      designStyle: DesignStyle.system,
      colorSchemeType: ColorSchemeType.tonalSpot,
      enableBookCover: false,
      currentTerm: '',
      autoSizeText: !isMobile,
      autoSizeMinFontSize: 6.0,
      timetableTextMaxLines: isMobile ? 3 : 2,
      timetableTextFontSize: isMobile ? 8.0 : 11.0,
      daysVisibleCount: 7,
      termsAccepted: false,
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
    ColorSchemeType? colorSchemeType,
    bool? enableBookCover,
    String? currentTerm,
    bool? autoSizeText,
    double? autoSizeMinFontSize,
    int? timetableTextMaxLines,
    double? timetableTextFontSize,
    int? daysVisibleCount,
    bool? termsAccepted,
  }) {
    return AppSettings(
      proxyEnabled: proxyEnabled ?? this.proxyEnabled,
      proxyPort: proxyPort ?? this.proxyPort,
      weeklyScroll: weeklyScroll ?? this.weeklyScroll,
      themeMode: themeMode ?? this.themeMode,
      seedColor: seedColor ?? this.seedColor,
      useDynamicColor: useDynamicColor ?? this.useDynamicColor,
      designStyle: designStyle ?? this.designStyle,
      colorSchemeType: colorSchemeType ?? this.colorSchemeType,
      enableBookCover: enableBookCover ?? this.enableBookCover,
      currentTerm: currentTerm ?? this.currentTerm,
      autoSizeText: autoSizeText ?? this.autoSizeText,
      autoSizeMinFontSize: autoSizeMinFontSize ?? this.autoSizeMinFontSize,
      timetableTextMaxLines:
          timetableTextMaxLines ?? this.timetableTextMaxLines,
      timetableTextFontSize:
          timetableTextFontSize ?? this.timetableTextFontSize,
      daysVisibleCount: daysVisibleCount ?? this.daysVisibleCount,
      termsAccepted: termsAccepted ?? this.termsAccepted,
    );
  }
}

abstract class SettingsRepository {
  Future<AppSettings> loadSettings();
  Future<void> saveSettings(AppSettings settings);
}
