import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:li_curriculum_table/core/rust/api/update.dart' as rust;

// Re-export DownloadProgress so that other files importing this service don't break.
export 'package:li_curriculum_table/core/rust/api/update.dart' show DownloadProgress;

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

/// Delegates the update download to the Rust side via FFI.
/// Listens to progress events, manages system local notifications, and yields
/// updates back to the UI.
Stream<rust.DownloadProgress> downloadWithProgress({
  required String url,
  required String savePath,
}) async* {
  var lastNotifTime = DateTime.fromMillisecondsSinceEpoch(0);

  yield const rust.DownloadProgress(
    received: 0,
    total: 0,
    done: false,
    savedPath: '',
    error: '正在连接...',
  );

  String? proxyString;
  try {
    proxyString = HttpClient.findProxyFromEnvironment(Uri.parse(url));
    debugPrint('OTA System Proxy resolved: $proxyString');
    if (proxyString == 'DIRECT') {
      debugPrint('提示: 系统代理解析为 DIRECT。如果您在手机上开启了 VPN，请确保在 VPN 软件的“分流/应用过滤”列表中勾选了 "com.example.curriculum_table" (或尝试切换为“全局代理”模式)，否则应用的流量将绕过 VPN 直连，导致下载极慢。');
    }
  } catch (e) {
    debugPrint('OTA: Failed to resolve system proxy: $e');
  }

  try {
    await for (final progress in rust.downloadUpdate(
      url: url,
      savePath: savePath,
      proxy: proxyString,
    )) {
      if (progress.done) {
        if (progress.error.isNotEmpty) {
          unawaited(_showErrorNotif(progress.error));
        } else {
          unawaited(_showCompleteNotif());
        }
      } else {
        final now = DateTime.now();
        if (now.difference(lastNotifTime).inMilliseconds >= 500) {
          lastNotifTime = now;
          unawaited(_showProgressNotif(
            progress.received,
            progress.total > 0 ? progress.total : progress.received,
          ));
        }
      }
      yield progress;
    }
  } catch (e) {
    unawaited(_showErrorNotif(e.toString()));
    yield rust.DownloadProgress(
      received: 0,
      total: 0,
      done: true,
      savedPath: '',
      error: e.toString(),
    );
  }
}

String _fmtBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
