import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:li_curriculum_table/core/rust/api/update.dart'
    as rust show checkForUpdate;

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
  /// Avoid hitting GitHub API too often (60 req/h unauthenticated).
  static const _cacheDuration = Duration(minutes: 30);

  // Simple in-memory cache so we don't spam the API on every launch.
  UpdateInfo? _cachedResult;
  DateTime? _lastFetchTime;

  /// Returns [UpdateInfo] if successful, or null if the check failed
  /// (network error, API rate limit, etc.).
  /// Results are cached for [_cacheDuration] to avoid rate limiting.
  Future<UpdateInfo?> checkForUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    // Return cached result if still fresh, but always re-check currentVersion
    // so we don't report stale version info after an app update.
    if (_cachedResult != null && _lastFetchTime != null) {
      final age = DateTime.now().difference(_lastFetchTime!);
      if (age < _cacheDuration) {
        if (_cachedResult!.currentVersion != currentVersion) {
          // App was updated — invalidate cache
          _cachedResult = null;
        } else {
          return _cachedResult;
        }
      }
    }

    try {
      final data = await rust.checkForUpdate();

      _cachedResult = UpdateInfo(
        currentVersion: currentVersion,
        latestVersion: data.latestVersion,
        releaseUrl: data.releaseUrl,
        releaseNotes: data.releaseNotes,
        publishedAt: DateTime.tryParse(data.publishedAt) ?? DateTime.now(),
      );
      _lastFetchTime = DateTime.now();
      return _cachedResult;
    } catch (e) {
      debugPrint('Update check failed: $e');
      // Fall back to stale cache on any error (network, rate limit, parse)
      return _cachedResult;
    }
  }
}
