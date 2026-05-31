import 'package:dio/dio.dart';
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

  bool get hasUpdate => latestVersion != currentVersion;
}

class UpdateService {
  static const _repoOwner = 'fans963';
  static const _repoName = '--table';
  static const _apiUrl =
      'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest';

  final Dio _dio;

  UpdateService({Dio? dio}) : _dio = dio ?? Dio();

  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await _dio.get(
        _apiUrl,
        options: Options(
          headers: {'Accept': 'application/vnd.github.v3+json'},
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final data = response.data as Map<String, dynamic>;
      final tagName = data['tag_name'] as String? ?? '';
      final latestVersion = tagName.replaceFirst('v', '');
      final htmlUrl = data['html_url'] as String? ?? '';
      final body = data['body'] as String? ?? '';
      final publishedAt =
          DateTime.tryParse(data['published_at'] as String? ?? '') ??
              DateTime.now();

      return UpdateInfo(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        releaseUrl: htmlUrl,
        releaseNotes: body,
        publishedAt: publishedAt,
      );
    } catch (_) {
      return null;
    }
  }
}
