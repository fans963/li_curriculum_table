import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:li_curriculum_table/app/app.dart';
import 'package:li_curriculum_table/core/rust/frb_generated.dart';
import 'package:li_curriculum_table/core/settings/data/settings_repository_impl.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/features/timetable/presentation/providers/timetable_providers.dart';

final secureSettingsLocalDataSourceProvider = Provider<SecureSettingsLocalDataSource>((ref) {
  final store = ref.watch(secureStorageStoreProvider);
  return SecureSettingsLocalDataSource(store);
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final localDataSource = ref.watch(secureSettingsLocalDataSourceProvider);
  return SettingsRepositoryImpl(localDataSource);
});

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    // Initial state is default, then loaded asynchronously
    _init();
    return AppSettings.defaultSettings();
  }

  Future<void> _init() async {
    final repository = ref.read(settingsRepositoryProvider);
    state = await repository.loadSettings();
    _syncWithRust();
  }

  Future<void> setProxyEnabled(bool enabled) async {
    state = state.copyWith(proxyEnabled: enabled);
    await _save();
    _syncWithRust();
  }

  Future<void> setProxyPort(int port) async {
    if (port < 1024 || port > 65535) return;
    state = state.copyWith(proxyPort: port);
    await _save();
    _syncWithRust();
  }

  Future<void> _save() async {
    final repository = ref.read(settingsRepositoryProvider);
    await repository.saveSettings(state);
  }

  /// Syncs current Dart state with the Rust background service
  void _syncWithRust() {
    // Always sync the port to Rust's global state (especially for Web probe)
    RustLib.instance.api.crateApiCrawlerUpdateProxyConfig(port: state.proxyPort.toInt());

    if (isWeb) return;
    
    if (state.proxyEnabled) {
      RustLib.instance.api.crateApiCrawlerRunProxyServer(port: state.proxyPort.toInt());
    } 
  }
}

final settingsControllerProvider = NotifierProvider<SettingsController, AppSettings>(() {
  return SettingsController();
});
