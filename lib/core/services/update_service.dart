import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String releaseUrl;
  final String releaseNotes;
  final DateTime publishedAt;

  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseUrl,
    required this.releaseNotes,
    required this.publishedAt,
  });

  /// Semver comparison: returns true if latestVersion > currentVersion.
  bool get hasUpdate => _compareVersions(latestVersion, currentVersion) > 0;

  /// Returns >0 if a > b, 0 if equal, <0 if a < b.
  static int _compareVersions(String a, String b) {
    final aParts = _parseVersion(a);
    final bParts = _parseVersion(b);
    for (int i = 0; i < 3; i++) {
      final cmp = aParts[i].compareTo(bParts[i]);
      if (cmp != 0) return cmp;
    }
    return 0;
  }

  static List<int> _parseVersion(String v) {
    final parts = v
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    // Pad to at least 3 parts: major.minor.patch
    while (parts.length < 3) {
      parts.add(0);
    }
    return parts.take(3).toList();
  }
}

class UpdateService {
  static const _repoOwner = 'fans963';
  static const _repoName = '--table';
  static const _apiUrl =
      'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest';

  /// Avoid hitting GitHub API too often (60 req/h unauthenticated).
  static const _cacheDuration = Duration(minutes: 30);

  final Dio _dio;

  // Simple in-memory cache so we don't spam the API on every launch.
  UpdateInfo? _cachedResult;
  DateTime? _lastFetchTime;

  UpdateService({Dio? dio}) : _dio = dio ?? Dio();

  /// Returns [UpdateInfo] if successful, or null if the check failed
  /// (network error, API rate limit, etc.).
  /// Results are cached for [_cacheDuration] to avoid rate limiting.
  Future<UpdateInfo?> checkForUpdate() async {
    // Return cached result if still fresh.
    if (_cachedResult != null && _lastFetchTime != null) {
      final age = DateTime.now().difference(_lastFetchTime!);
      if (age < _cacheDuration) {
        return _cachedResult;
      }
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    try {
      final response = await _dio.get(
        _apiUrl,
        options: Options(
          headers: {'Accept': 'application/vnd.github.v3+json'},
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final data = response.data as Map<String, dynamic>;
      final tagName = data['tag_name'] as String? ?? '';
      final latestVersion = tagName.replaceFirst(RegExp(r'^v'), '');
      final htmlUrl = data['html_url'] as String? ?? '';
      final body = data['body'] as String? ?? '';
      final publishedAt =
          DateTime.tryParse(data['published_at'] as String? ?? '') ??
              DateTime.now();

      _cachedResult = UpdateInfo(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        releaseUrl: htmlUrl,
        releaseNotes: body,
        publishedAt: publishedAt,
      );
      _lastFetchTime = DateTime.now();
      return _cachedResult;
    } on DioException catch (e) {
      debugPrint('Update check failed (network): ${e.message}');
      // If rate-limited, try to use stale cache as fallback.
      if (e.response?.statusCode == 403 || e.response?.statusCode == 429) {
        debugPrint('GitHub API rate limited, using cached result if available');
        return _cachedResult;
      }
      return null;
    } catch (e) {
      debugPrint('Update check failed (parse): $e');
      return _cachedResult; // fall back to stale cache on parse errors too
    }
  }
}
