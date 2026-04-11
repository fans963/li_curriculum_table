import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/features/timetable/data/datasources/secure_storage_store.dart';

class SecureSettingsLocalDataSource {
  final SecureStorageStore _store;

  static const _kProxyEnabled = 'proxy_enabled';
  static const _kProxyPort = 'proxy_port';

  SecureSettingsLocalDataSource(this._store);

  Future<AppSettings> loadSettings() async {
    final data = await _store.readAll([_kProxyEnabled, _kProxyPort]);
    
    final enabled = data[_kProxyEnabled] == 'true';
    final port = int.tryParse(data[_kProxyPort] ?? '9999') ?? 9999;

    return AppSettings(proxyEnabled: enabled, proxyPort: port);
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _store.writeAll({
      _kProxyEnabled: settings.proxyEnabled.toString(),
      _kProxyPort: settings.proxyPort.toString(),
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
