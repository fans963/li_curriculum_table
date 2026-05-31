class AppSettings {
  final bool proxyEnabled;
  final int proxyPort;
  final bool weeklyScroll;

  const AppSettings({
    required this.proxyEnabled,
    required this.proxyPort,
    required this.weeklyScroll,
  });

  factory AppSettings.defaultSettings() {
    return const AppSettings(
      proxyEnabled: false,
      proxyPort: 9999,
      weeklyScroll: false,
    );
  }

  AppSettings copyWith({
    bool? proxyEnabled,
    int? proxyPort,
    bool? weeklyScroll,
  }) {
    return AppSettings(
      proxyEnabled: proxyEnabled ?? this.proxyEnabled,
      proxyPort: proxyPort ?? this.proxyPort,
      weeklyScroll: weeklyScroll ?? this.weeklyScroll,
    );
  }
}

abstract class SettingsRepository {
  Future<AppSettings> loadSettings();
  Future<void> saveSettings(AppSettings settings);
}
