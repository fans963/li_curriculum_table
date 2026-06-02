import 'package:flutter/material.dart';
import 'package:li_curriculum_table/app/app.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/rust/api/crawler.dart' as crawler;
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:signals/signals.dart';

class SettingsController {
  final _state = signal(AppSettings.defaultSettings());

  ReadonlySignal<AppSettings> get state => _state;

  late final themeMode = computed(() => _state.value.themeMode);
  late final seedColor = computed(() => _state.value.seedColor);
  late final useDynamicColor = computed(() => _state.value.useDynamicColor);
  late final designStyle = computed(() => _state.value.designStyle);
  late final weeklyScroll = computed(() => _state.value.weeklyScroll);
  late final proxyEnabled = computed(() => _state.value.proxyEnabled);
  late final proxyPort = computed(() => _state.value.proxyPort);

  Future<void> init() async {
    final repository = sl<SettingsRepository>();
    _state.value = await repository.loadSettings();
    _syncWithRust();
  }

  Future<void> setProxyEnabled(bool enabled) async {
    _state.value = _state.value.copyWith(proxyEnabled: enabled);
    await _save();
    _syncWithRust();
  }

  Future<void> setProxyPort(int port) async {
    if (port < 1024 || port > 65535) return;
    _state.value = _state.value.copyWith(proxyPort: port);
    await _save();
    _syncWithRust();
  }

  Future<void> setWeeklyScroll(bool enabled) async {
    _state.value = _state.value.copyWith(weeklyScroll: enabled);
    await _save();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _state.value = _state.value.copyWith(themeMode: mode);
    await _save();
  }

  Future<void> setSeedColor(Color color) async {
    _state.value = _state.value.copyWith(seedColor: color);
    await _save();
  }

  Future<void> setUseDynamicColor(bool enabled) async {
    _state.value = _state.value.copyWith(useDynamicColor: enabled);
    await _save();
  }

  Future<void> setDesignStyle(DesignStyle style) async {
    _state.value = _state.value.copyWith(designStyle: style);
    await _save();
  }

  Future<void> _save() async {
    final repository = sl<SettingsRepository>();
    await repository.saveSettings(_state.value);
  }

  void _syncWithRust() {
    crawler.updateProxyConfig(port: _state.value.proxyPort.toInt());

    if (isWeb) return;

    if (_state.value.proxyEnabled) {
      crawler.runProxyServer(port: _state.value.proxyPort.toInt());
    }
  }
}
