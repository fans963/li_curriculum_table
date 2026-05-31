import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/features/timetable/data/datasources/secure_storage_store.dart';

class SecureSettingsLocalDataSource {
  final SecureStorageStore _store;

  static const _kProxyEnabled = 'proxy_enabled';
  static const _kProxyPort = 'proxy_port';
  static const _kWeeklyScroll = 'weekly_scroll';

  SecureSettingsLocalDataSource(this._store);

  Future<AppSettings> loadSettings() async {
    final data = await _store.readAll([_kProxyEnabled, _kProxyPort, _kWeeklyScroll]);
    
    final enabled = data[_kProxyEnabled] == 'true';
    final port = int.tryParse(data[_kProxyPort] ?? '9999') ?? 9999;
    final weekly = data[_kWeeklyScroll] == 'true';

    return AppSettings(
      proxyEnabled: enabled,
      proxyPort: port,
      weeklyScroll: weekly,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _store.writeAll({
      _kProxyEnabled: settings.proxyEnabled.toString(),
      _kProxyPort: settings.proxyPort.toString(),
      _kWeeklyScroll: settings.weeklyScroll.toString(),
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
