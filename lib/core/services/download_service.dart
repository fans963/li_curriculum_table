import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Progress event emitted during a download.
class DownloadProgress {
  final int received;
  final int total;
  final bool done;
  final String savedPath;
  final String error;

  const DownloadProgress({
    required this.received,
    required this.total,
    required this.done,
    this.savedPath = '',
    this.error = '',
  });
}

/// GitHub mirror prefixes — tried first for users in mainland China.
/// The raw GitHub URL is used as final fallback.
const _mirrorPrefixes = [
  'https://ghfast.top/',
  'https://gh-proxy.com/',
  'https://gh.ddlc.top/',
];

const _dlChannelId = 'download_progress';
const _dlChannelName = '下载通知';
const _notifId = 90000;

FlutterLocalNotificationsPlugin? _notifPlugin;

Future<FlutterLocalNotificationsPlugin> _ensureNotif() async {
  if (_notifPlugin != null) return _notifPlugin!;
  _notifPlugin = FlutterLocalNotificationsPlugin();
  await _notifPlugin!.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/launcher_icon'),
    ),
  );
  await _notifPlugin!
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
        _dlChannelId,
        _dlChannelName,
        description: '应用更新下载进度',
        importance: Importance.low,
      ));
  return _notifPlugin!;
}

Future<void> _showProgressNotif(int received, int total) async {
  final plugin = await _ensureNotif();
  final max = total > 0 ? total : 0;
  final current = received.clamp(0, max);
  final pct = total > 0 ? '${(current * 100 ~/ total)}%' : '';

  await plugin.show(
    id: _notifId,
    title: '正在下载更新',
    body: '$pct  ${_fmtBytes(current)} / ${_fmtBytes(total)}',
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        _dlChannelId,
        _dlChannelName,
        channelDescription: '应用更新下载进度',
        importance: Importance.low,
        priority: Priority.low,
        showProgress: true,
        maxProgress: max,
        progress: current,
        ongoing: true,
        autoCancel: false,
        onlyAlertOnce: true,
      ),
    ),
  );
}

Future<void> _showCompleteNotif(String savedPath) async {
  final plugin = await _ensureNotif();
  await plugin.show(
    id: _notifId,
    title: '下载完成',
    body: '点击安装更新',
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        _dlChannelId,
        _dlChannelName,
        channelDescription: '应用更新下载进度',
        importance: Importance.high,
        priority: Priority.high,
        autoCancel: true,
        // Open the APK when tapped
        // Note: open_filex handles this from the dialog; the notification
        // serves as a persistent reminder.
      ),
    ),
  );
}

Future<void> _showErrorNotif(String error) async {
  final plugin = await _ensureNotif();
  await plugin.show(
    id: _notifId,
    title: '下载失败',
    body: error,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        _dlChannelId,
        _dlChannelName,
        channelDescription: '应用更新下载进度',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        autoCancel: true,
      ),
    ),
  );
}

/// Download a file with automatic mirror fallback and progress streaming.
///
/// Mirrors are tried first (fastest for mainland China), then the original
/// GitHub URL as final fallback. If a stream error occurs mid-download,
/// retries with the next candidate from scratch.
Stream<DownloadProgress> downloadWithProgress({
  required String url,
  required String savePath,
}) async* {
  // Mirrors first, then original GitHub URL as fallback
  final candidates = <String>[
    ..._mirrorPrefixes.map((p) => '$p$url'),
    url,
  ];

  String lastError = '';

  for (var idx = 0; idx < candidates.length; idx++) {
    final candidate = candidates[idx];
    final isMirror = idx < _mirrorPrefixes.length;

    // Notify which source we're trying
    yield DownloadProgress(
      received: 0,
      total: 0,
      done: false,
      error: isMirror ? '正在尝试镜像 ${idx + 1}...' : '正在连接 GitHub...',
    );

    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10)
        ..autoUncompress = false;

      final request = await client.getUrl(Uri.parse(candidate));
      request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');

      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode != HttpStatus.ok) {
        lastError = '$candidate: HTTP ${response.statusCode}';
        client.close(force: true);
        continue;
      }

      final total = response.contentLength;
      var received = 0;
      final file = File(savePath);
      final sink = file.openSync(mode: FileMode.write);
      var streamErr = false;
      var lastNotifTime = DateTime.fromMillisecondsSinceEpoch(0);

      await for (final chunk in response) {
        try {
          sink.writeFromSync(chunk);
          received += chunk.length;

          yield DownloadProgress(
            received: received,
            total: total > 0 ? total : 0,
            done: false,
          );

          // Throttle notification updates to ~2/sec
          final now = DateTime.now();
          if (now.difference(lastNotifTime).inMilliseconds >= 500) {
            lastNotifTime = now;
            unawaited(_showProgressNotif(received, total > 0 ? total : received));
          }
        } catch (e) {
          lastError = '写入失败: $e';
          streamErr = true;
          break;
        }
      }

      await sink.close();
      client.close(force: true);

      if (streamErr) {
        yield DownloadProgress(
          received: received,
          total: total > 0 ? total : 0,
          done: false,
          error: '$lastError，尝试下一个源...',
        );
        continue;
      }

      // Success — show completion notification
      unawaited(_showCompleteNotif(savePath));

      yield DownloadProgress(
        received: received,
        total: total > 0 ? total : 0,
        done: true,
        savedPath: savePath,
      );
      return;
    } catch (e) {
      lastError = '$candidate: $e';
      yield DownloadProgress(
        received: 0,
        total: 0,
        done: false,
        error: '$lastError，尝试下一个源...',
      );
      continue;
    }
  }

  // All candidates failed
  unawaited(_showErrorNotif(lastError));

  yield DownloadProgress(
    received: 0,
    total: 0,
    done: true,
    error: '所有下载源均失败: $lastError',
  );
}

String _fmtBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
