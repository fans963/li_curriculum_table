import 'package:material_ui/material_ui.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/styles/styles.dart';
import 'package:li_curriculum_table/core/services/weather_service.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:signals/signals_flutter.dart';

class WeatherBanner extends SignalStatefulWidget {
  final DesignStyle? designStyle;

  const WeatherBanner({super.key, this.designStyle});

  @override
  State<WeatherBanner> createState() => _WeatherBannerState();
}

class _WeatherBannerState extends State<WeatherBanner> {
  final _weather = signal<WeatherInfo?>(null);
  final _loading = signal(true);

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    try {
      final result = await sl<WeatherService>().fetchWeather();
      if (mounted) {
        _weather.value = result;
        _loading.value = false;
      }
    } catch (_) {
      if (mounted) _loading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading.value) return const SizedBox.shrink();
    final w = _weather.value;
    if (w == null) return const SizedBox.shrink();

    final ds = widget.designStyle ??
        sl<SettingsController>().state.value.designStyle;
    return _buildContent(context, w, ds);
  }

  Widget _buildContent(BuildContext context, WeatherInfo w, DesignStyle ds) {
    final cs = Theme.of(context).colorScheme;
    final style = UiStyleRegistry.resolve(ds);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Semantics(
        label:
            '天气: ${w.minTemperature.round()}到${w.maxTemperature.round()}度, ${w.description}',
        child: style.buildCard(
          context: context,
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(w.icon, size: 22, color: w.color),
              const SizedBox(width: 10),
              Flexible(
                flex: 2,
                child: Text(
                  '${w.minTemperature.round()}~${w.maxTemperature.round()}°C ${w.description}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                flex: 3,
                child: Text(
                  w.tip,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
