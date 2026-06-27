import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
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
const _mirrorPrefixes = [
  'https://ghfast.top/',
  'https://gh-proxy.com/',
  'https://gh.ddlc.top/',
];

const _dlChannelId = 'download_progress';
const _dlChannelName = '下载通知';
const _notifId = 90000;

// ─── Notifications ────────────────────────────────────────────────────────

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
        _dlChannelId, _dlChannelName,
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

Future<void> _showCompleteNotif() async {
  final plugin = await _ensureNotif();
  await plugin.show(
    id: _notifId,
    title: '下载完成',
    body: '点击安装更新',
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        _dlChannelId, _dlChannelName,
        channelDescription: '应用更新下载进度',
        importance: Importance.high,
        priority: Priority.high,
        autoCancel: true,
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
        _dlChannelId, _dlChannelName,
        channelDescription: '应用更新下载进度',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        autoCancel: true,
      ),
    ),
  );
}

// ─── Download ────────────────────────────────────────────────────────────

/// Race all mirrors + GitHub in parallel. Use whichever connects first,
/// then stream from that connection. If the stream errors, fall back to
/// the next connected response (if available) or re-race remaining candidates.
Stream<DownloadProgress> downloadWithProgress({
  required String url,
  required String savePath,
}) async* {
  final candidates = <String>[
    ..._mirrorPrefixes.map((p) => '$p$url'),
    url,
  ];

  yield const DownloadProgress(
    received: 0, total: 0, done: false,
    error: '正在连接...',
  );

  // Phase 1: race all candidates — take the first that responds 200
  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 8)
    ..autoUncompress = false;

  HttpClientResponse? bestResponse;
  String bestUrl = '';

  // Fire all connections in parallel
  final futures = candidates.map((u) async {
    try {
      final req = await client.getUrl(Uri.parse(u));
      req.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
      final resp = await req.close().timeout(const Duration(seconds: 8));
      return (u, resp);
    } catch (_) {
      return null;
    }
  }).toList();

  // Wait for the first successful response
  final completer = Completer<void>();
  var resolved = false;

  for (final future in futures) {
    future.then((result) {
      if (result != null && !resolved) {
        resolved = true;
        bestUrl = result.$1;
        bestResponse = result.$2;
        if (!completer.isCompleted) completer.complete();
      }
    });
  }

  // Also set a total timeout for the race
  Future.delayed(const Duration(seconds: 12), () {
    if (!resolved) {
      resolved = true;
      if (!completer.isCompleted) completer.complete();
    }
  });

  await completer.future;

  if (bestResponse == null) {
    client.close(force: true);
    unawaited(_showErrorNotif('所有下载源均不可达'));
    yield const DownloadProgress(
      received: 0, total: 0, done: true,
      error: '所有下载源均不可达',
    );
    return;
  }

  debugPrint('OTA: using $bestUrl');

  // Phase 2: stream from the winning response
  final response = bestResponse!;
  final total = response.contentLength;
  var received = 0;
  final file = File(savePath);
  IOSink? fileSink;
  var lastNotifTime = DateTime.fromMillisecondsSinceEpoch(0);
  String lastError = '';

  try {
    fileSink = file.openWrite();

    await for (final chunk in response) {
      fileSink.add(chunk);
      received += chunk.length;

      yield DownloadProgress(
        received: received,
        total: total > 0 ? total : 0,
        done: false,
      );

      final now = DateTime.now();
      if (now.difference(lastNotifTime).inMilliseconds >= 500) {
        lastNotifTime = now;
        unawaited(_showProgressNotif(received, total > 0 ? total : received));
      }
    }

    await fileSink.flush();
    await fileSink.close();
    client.close(force: true);

    unawaited(_showCompleteNotif());
    yield DownloadProgress(
      received: received,
      total: total > 0 ? total : 0,
      done: true,
      savedPath: savePath,
    );
    return;
  } catch (e) {
    lastError = '$bestUrl: $e';
    await fileSink?.close();
    client.close(force: true);
  }

  // If we get here, the stream failed — try remaining candidates sequentially
  debugPrint('OTA: stream error on $bestUrl, trying fallbacks...');

  for (final candidate in candidates) {
    if (candidate == bestUrl) continue;

    yield DownloadProgress(
      received: 0, total: 0, done: false,
      error: '正在回退到 $candidate...',
    );

    try {
      final c = HttpClient()
        ..connectionTimeout = const Duration(seconds: 8)
        ..autoUncompress = false;
      final req = await c.getUrl(Uri.parse(candidate));
      req.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
      final resp = await req.close().timeout(const Duration(seconds: 8));

      if (resp.statusCode != HttpStatus.ok) {
        c.close(force: true);
        continue;
      }

      final t = resp.contentLength;
      var r = 0;
      final sink = File(savePath).openWrite();

      await for (final chunk in resp) {
        sink.add(chunk);
        r += chunk.length;
        yield DownloadProgress(received: r, total: t > 0 ? t : 0, done: false);
      }

      await sink.flush();
      await sink.close();
      c.close(force: true);

      unawaited(_showCompleteNotif());
      yield DownloadProgress(
        received: r, total: t > 0 ? t : 0,
        done: true, savedPath: savePath,
      );
      return;
    } catch (e) {
      lastError += '\n$candidate: $e';
      continue;
    }
  }

  unawaited(_showErrorNotif(lastError));
  yield DownloadProgress(
    received: 0, total: 0, done: true,
    error: '所有下载源均失败: $lastError',
  );
}

String _fmtBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
