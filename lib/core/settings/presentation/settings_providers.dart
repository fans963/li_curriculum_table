import 'package:material_ui/material_ui.dart';
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
  late final colorSchemeType = computed(() => _state.value.colorSchemeType);
  late final weeklyScroll = computed(() => _state.value.weeklyScroll);
  late final proxyEnabled = computed(() => _state.value.proxyEnabled);
  late final proxyPort = computed(() => _state.value.proxyPort);
  late final enableBookCover = computed(() => _state.value.enableBookCover);
  late final currentTerm = computed(() => _state.value.currentTerm);
  late final autoSizeText = computed(() => _state.value.autoSizeText);
  late final autoSizeMinFontSize = computed(
    () => _state.value.autoSizeMinFontSize,
  );
  late final timetableTextMaxLines = computed(
    () => _state.value.timetableTextMaxLines,
  );
  late final timetableTextFontSize = computed(
    () => _state.value.timetableTextFontSize,
  );
  late final daysVisibleCount = computed(() => _state.value.daysVisibleCount);
  late final termsAccepted = computed(() => _state.value.termsAccepted);
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

  Future<void> setEnableBookCover(bool enabled) async {
    _state.value = _state.value.copyWith(enableBookCover: enabled);
    await _save();
  }

  Future<void> setCurrentTerm(String term) async {
    _state.value = _state.value.copyWith(currentTerm: term);
    await _save();
  }

  Future<void> setAutoSizeText(bool enabled) async {
    _state.value = _state.value.copyWith(autoSizeText: enabled);
    await _save();
  }

  Future<void> setAutoSizeMinFontSize(double size) async {
    if (size < 4 || size > 20) return;
    _state.value = _state.value.copyWith(autoSizeMinFontSize: size);
    await _save();
  }

  Future<void> setTimetableTextMaxLines(int lines) async {
    if (lines < 1 || lines > 5) return;
    _state.value = _state.value.copyWith(timetableTextMaxLines: lines);
    await _save();
  }

  Future<void> setTimetableTextFontSize(double size) async {
    if (size < 5 || size > 20) return;
    _state.value = _state.value.copyWith(timetableTextFontSize: size);
    await _save();
  }

  Future<void> setTermsAccepted(bool accepted) async {
    _state.value = _state.value.copyWith(termsAccepted: accepted);
    await _save();
  }

  Future<void> setDaysVisibleCount(int days) async {
    if (days < 1 || days > 14) return;
    _state.value = _state.value.copyWith(daysVisibleCount: days);
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

  Future<void> setColorSchemeType(ColorSchemeType type) async {
    _state.value = _state.value.copyWith(colorSchemeType: type);
    await _save();
  }

  Future<void> _save() async {
    final repository = sl<SettingsRepository>();
    await repository.saveSettings(_state.value);
  }

  void _syncWithRust() {
    crawler.updateProxyConfig(port: _state.value.proxyPort);

    if (isWeb) return;

    if (_state.value.proxyEnabled) {
      crawler.runProxyServer(port: _state.value.proxyPort.toInt());
    }
  }
}
