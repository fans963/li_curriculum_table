import 'dart:async';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/styles/styles.dart';
import 'package:li_curriculum_table/core/rust/api/crawler.dart' as rust_api;
import 'package:li_curriculum_table/core/services/cookie_storage/cookie_storage.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/settings/presentation/pages/widgets/liquid_glass_qr_login_dialog.dart';
import 'package:li_curriculum_table/features/settings/presentation/pages/widgets/m3e_qr_login_dialog.dart';

class QrLoginDialog extends StatefulWidget {
  const QrLoginDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => const QrLoginDialog(),
        ) ??
        false;
  }

  @override
  State<QrLoginDialog> createState() => _QrLoginDialogState();
}

class _QrLoginDialogState extends State<QrLoginDialog> {
  Timer? _timer;
  Uint8List? _image;
  String _message = '正在生成二维码...';
  bool _loading = true;
  bool _polling = false;
  int _generation = 0;

  /// Consecutive poll failures. Incremented on every exception, reset to 0
  /// on any successful response. We only surface a user-visible error after
  /// the network has clearly given up — a single failure is normal when the
  /// app comes back from the WeChat scanner (TCP keepalive sockets that
  /// were idle for tens of seconds get RST'd by the carrier's NAT, but the
  /// reqwest pool doesn't know yet, so the next poll sees a broken pipe).
  int _consecutiveFailures = 0;

  /// Threshold for surfacing a transient "网络不稳定" hint. Polling
  /// continues silently past this until either a poll succeeds (server
  /// returns a status) or the user gives up and presses 刷新二维码.
  static const _transientFailureThreshold = 2;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final generation = ++_generation;
    _timer?.cancel();
    _consecutiveFailures = 0;
    setState(() {
      _loading = true;
      _image = null;
      _message = '正在生成二维码...';
    });
    try {
      final result = await rust_api.startQrLogin();
      if (!mounted) {
        await rust_api.cancelQrLogin();
        return;
      }
      if (generation != _generation) return;
      if (result.alreadyAuthenticated) {
        Navigator.of(context).pop(true);
        return;
      }
      setState(() {
        _image = result.imagePng;
        _loading = false;
        _message = '请用微信扫描二维码，并在手机上确认登录';
      });
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _poll(generation),
      );
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _message = '二维码获取失败，请检查网络后重试';
      });
    }
  }

  Future<void> _poll(int generation) async {
    if (_polling || !mounted || generation != _generation) return;
    _polling = true;
    try {
      final status = await rust_api.pollQrLogin();
      if (!mounted || generation != _generation) return;
      _consecutiveFailures = 0; // any successful response resets the streak
      switch (status) {
        case 'waiting':
          if (_message == '网络不稳定，正在重试...' ||
              _message == '登录连接中断，请刷新二维码重试') {
            setState(() => _message = '请用微信扫描二维码，并在手机上确认登录');
          }
        case 'scanned':
          setState(() => _message = '扫码成功，请在手机上确认登录');
        case 'expired':
          _timer?.cancel();
          setState(() => _message = '二维码已过期，请点击刷新');
        case 'confirmed':
          _timer?.cancel();
          // Persist the cookie jar so the next launch skips QR.
          unawaited(CookieStorage.saveFromRust());
          Navigator.of(context).pop(true);
        default:
          throw StateError('Unexpected QR status');
      }
    } catch (_) {
      if (!mounted || generation != _generation) return;
      _consecutiveFailures++;
      // Transient network blips (e.g. Android killed an idle TCP socket while
      // the user was scanning in WeChat, then reqwest hands us a broken
      // pipe on resume) must NOT abort polling — the server-side QR
      // session is independent of our HTTP connection. We keep ticking and
      // let reqwest rotate the dead connection out of its pool; the next
      // successful poll will catch the server's `confirmed` / `expired`
      // status on its own.
      if (_consecutiveFailures == _transientFailureThreshold) {
        setState(() => _message = '网络不稳定，正在重试...');
      }
    } finally {
      _polling = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(rust_api.cancelQrLogin());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ds = sl<SettingsController>().state.value.designStyle;
    final concrete = UiStyleRegistry.resolveConcreteStyle(ds);

    if (concrete == DesignStyle.cupertino) {
      return LiquidGlassQrLoginDialogView(
        image: _image,
        loading: _loading,
        message: _message,
        onRefresh: _start,
        onCancel: () => Navigator.of(context).pop(false),
      );
    }

    return M3EQrLoginDialogView(
      image: _image,
      loading: _loading,
      message: _message,
      onRefresh: _start,
      onCancel: () => Navigator.of(context).pop(false),
    );
  }
}
