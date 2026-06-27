import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:li_curriculum_table/core/rust/api/weather.dart' as rust;

class WeatherInfo {
  final double minTemperature;
  final double maxTemperature;
  final int weatherCode;
  final bool isDay;
  final double? windSpeed;

  const WeatherInfo({
    required this.minTemperature,
    required this.maxTemperature,
    required this.weatherCode,
    required this.isDay,
    this.windSpeed,
  });

  factory WeatherInfo.fromRust(rust.WeatherData data) => WeatherInfo(
    minTemperature: data.minTemperature,
    maxTemperature: data.maxTemperature,
    weatherCode: data.weatherCode,
    isDay: data.isDay,
    windSpeed: data.windSpeed,
  );

  String get description => _weatherDescription(weatherCode);
  IconData get icon => _weatherIcon(weatherCode, isDay);
  String get tip => _weatherTip(weatherCode, maxTemperature);
  Color get color => _weatherColor(weatherCode);

  static String _weatherDescription(int code) {
    if (code == 0) return '晴';
    if (code == 1) return '大部晴朗';
    if (code == 2) return '多云';
    if (code == 3) return '阴';
    if (code >= 45 && code <= 48) return '雾';
    if (code >= 51 && code <= 55) return '毛毛雨';
    if (code >= 56 && code <= 57) return '冻毛毛雨';
    if (code >= 61 && code <= 63) return '雨';
    if (code == 65) return '大雨';
    if (code >= 66 && code <= 67) return '冻雨';
    if (code >= 71 && code <= 75) return '雪';
    if (code == 77) return '雪粒';
    if (code >= 80 && code <= 82) return '阵雨';
    if (code >= 85 && code <= 86) return '阵雪';
    if (code >= 95 && code <= 99) return '雷暴';
    return '未知';
  }

  static IconData _weatherIcon(int code, bool isDay) {
    if (code <= 1) {
      return isDay ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded;
    }
    if (code == 2) return Icons.wb_cloudy_rounded;
    if (code == 3) return Icons.cloud_rounded;
    if (code >= 45 && code <= 48) return Icons.foggy;
    if (code >= 51 && code <= 57) return Icons.grain_rounded;
    if (code >= 61 && code <= 67) return Icons.water_drop_rounded;
    if (code >= 71 && code <= 77) return Icons.ac_unit_rounded;
    if (code >= 80 && code <= 82) return Icons.beach_access_rounded;
    if (code >= 85 && code <= 86) return Icons.ac_unit_rounded;
    if (code >= 95) return Icons.thunderstorm_rounded;
    return Icons.cloud_rounded;
  }

  static String _weatherTip(int code, double temp) {
    if (code >= 95) return '⚡ 雷暴天气，尽量待在室内';
    if (temp >= 35) return '🥵 天气炎热，注意防暑降温';
    if (code >= 61 || (code >= 80 && code <= 82)) return '🌧️ 下雨了，出门记得带伞';
    if (code >= 71) return '❄️ 下雪了，注意保暖防滑';
    if (code >= 45 && code <= 48) return '🌫️ 有雾，出行注意安全';
    if (temp >= 30) return '☀️ 天气较热，多补充水分';
    if (temp <= 0) return '🥶 天气寒冷，注意保暖';
    if (temp <= 5) return '🧣 天气较冷，多穿点衣服';
    if (code <= 1) return '☀️ 天气不错，适合去图书馆学习';
    if (code <= 3) return '⛅ 今天多云，适合出门活动';
    return '📚 祝你学习愉快';
  }

  static Color _weatherColor(int code) {
    if (code <= 1) return const Color(0xFFFF9500);
    if (code <= 3) return const Color(0xFF8E8E93);
    if (code >= 45 && code <= 48) return const Color(0xFF8E8E93);
    if (code >= 61 || (code >= 80 && code <= 82)) {
      return const Color(0xFF007AFF);
    }
    if (code >= 71) return const Color(0xFF5AC8FA);
    if (code >= 95) return const Color(0xFF5856D6);
    return const Color(0xFF8E8E93);
  }
}

class WeatherService {
  // Simple in-memory cache to avoid re-fetching on every widget rebuild.
  static const _cacheDuration = Duration(minutes: 30);

  WeatherInfo? _cachedWeather;
  DateTime? _lastFetchTime;

  Future<WeatherInfo?> fetchWeather() async {
    // Return cached result if still fresh
    if (_cachedWeather != null && _lastFetchTime != null) {
      final age = DateTime.now().difference(_lastFetchTime!);
      if (age < _cacheDuration) {
        return _cachedWeather;
      }
    }
    // Web and some desktop platforms don't support geolocator well
    if (kIsWeb) {
      debugPrint('Weather: skipped on web');
      return null;
    }

    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Weather: location services disabled');
        return null;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Weather: location permission denied');
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        debugPrint('Weather: location permission permanently denied');
        return null;
      }

      // Get position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );

      debugPrint(
        'Weather: position ${position.latitude}, ${position.longitude}',
      );

      // Fetch weather via Rust bridge
      final data = await rust.fetchWeather(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      final weather = WeatherInfo.fromRust(data);

      debugPrint(
        'Weather: ${weather.minTemperature}°C-${weather.maxTemperature}°C code=${weather.weatherCode}',
      );
      _cachedWeather = weather;
      _lastFetchTime = DateTime.now();
      return weather;
    } on LocationServiceDisabledException {
      debugPrint('Weather: location service disabled during fetch');
      return _cachedWeather; // fall back to stale cache
    } catch (e) {
      debugPrint('Weather error: $e');
      return _cachedWeather; // fall back to stale cache
    }
  }
}
