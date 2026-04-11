class AppSettings {
  final bool proxyEnabled;
  final int proxyPort;

  const AppSettings({
    required this.proxyEnabled,
    required this.proxyPort,
  });

  factory AppSettings.defaultSettings() {
    return const AppSettings(
      proxyEnabled: false,
      proxyPort: 9999,
    );
  }

  AppSettings copyWith({
    bool? proxyEnabled,
    int? proxyPort,
  }) {
    return AppSettings(
      proxyEnabled: proxyEnabled ?? this.proxyEnabled,
      proxyPort: proxyPort ?? this.proxyPort,
    );
  }
}

abstract class SettingsRepository {
  Future<AppSettings> loadSettings();
  Future<void> saveSettings(AppSettings settings);
}
