import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:progress_indicator_m3e/progress_indicator_m3e.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/rust/api/update.dart' as rust;
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:li_curriculum_table/core/services/update_service.dart';

const _ghOwner = 'fans963';
const _ghRepo = 'li_curriculum_table';
const _giteeOwner = 'fans963';
const _giteeRepo = 'li_curriculum_table';

/// GitHub mirror prefixes for in-app download (native platforms).
const _ghMirrorPrefixes = [
  'https://ghfast.top/',
  'https://gh-proxy.com/',
  'https://gh.ddlc.top/',
];

/// All downloadable assets with human-readable labels.
const _assets = [
  _Asset('app-arm64-v8a-release.apk', 'Android ARM64'),
  _Asset('app-armeabi-v7a-release.apk', 'Android ARM32'),
  _Asset('app-x86_64-release.apk', 'Android x86_64'),
  _Asset('li-curriculum-table-unsigned.ipa', 'iOS (IPA)'),
];

class _Asset {
  final String filename;
  final String label;
  const _Asset(this.filename, this.label);
}

/// Gitee download URL (fastest in mainland China).
String _giteeUrl(String version, String filename) =>
    'https://gitee.com/$_giteeOwner/$_giteeRepo/releases/download/v$version/$filename';

/// GitHub download URL (fallback).
String _ghUrl(String version, String filename) =>
    'https://github.com/$_ghOwner/$_ghRepo/releases/download/v$version/$filename';

/// Mirror-prefixed GitHub URL for in-app download.
String _ghMirrorUrl(String version, String filename) =>
    '${_ghMirrorPrefixes.first}${_ghUrl(version, filename)}';

/// Build the download URL for the current device (native in-app download).
String _buildDownloadUrl(String version) {
  String filename;
  if (defaultTargetPlatform == TargetPlatform.android) {
    filename = 'app-arm64-v8a-release.apk';
  } else if (defaultTargetPlatform == TargetPlatform.iOS) {
    filename = 'li-curriculum-table-unsigned.ipa';
  } else {
    return 'https://github.com/$_ghOwner/$_ghRepo/releases/tag/v$version';
  }
  // Native: use fastest mirror first
  return _ghMirrorUrl(version, filename);
}

/// Shows update dialog if [updateInfo] indicates a new version is available.
/// Returns true if an update dialog was shown, false otherwise.
Future<bool> showUpdateDialogIfNeeded(
  BuildContext context,
  UpdateInfo? updateInfo, {
  bool silent = true,
}) async {
  if (updateInfo == null) {
    if (!silent && context.mounted) {
      final ds = sl<SettingsController>().designStyle.value;
      if (AdaptiveStyle.isCupertino(ds)) {
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            content: const Text('检查更新失败，请稍后重试'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('好的'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('检查更新失败，请稍后重试')),
        );
      }
    }
    return false;
  }
  if (!updateInfo.hasUpdate) {
    if (!silent && context.mounted) {
      final ds = sl<SettingsController>().designStyle.value;
      if (AdaptiveStyle.isCupertino(ds)) {
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            content: const Text('当前已是最新版本 ✨'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('好的'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('当前已是最新版本 ✨')),
        );
      }
    }
    return false;
  }

  if (!context.mounted) return false;

  final ds = sl<SettingsController>().designStyle.value;
  if (AdaptiveStyle.isCupertino(ds)) {
    await showCupertinoDialog(
      context: context,
      builder: (_) => _CupertinoUpdateDialog(updateInfo: updateInfo),
    );
  } else {
    await showDialog(
      context: context,
      builder: (_) => _MaterialUpdateDialog(updateInfo: updateInfo),
    );
  }
  return true;
}

// ═══════════════════════════════════════════════════════════════════════════
// Download State
// ═══════════════════════════════════════════════════════════════════════════

class _DownloadState {
  bool downloading = false;
  double progress = 0; // 0.0 ~ 1.0
  String? error;
  String? savedPath;
  int received = 0;
  int total = 0;
}

// ═══════════════════════════════════════════════════════════════════════════
// Material Update Dialog
// ═══════════════════════════════════════════════════════════════════════════

class _MaterialUpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;
  const _MaterialUpdateDialog({required this.updateInfo});

  @override
  State<_MaterialUpdateDialog> createState() => _MaterialUpdateDialogState();
}

class _MaterialUpdateDialogState extends State<_MaterialUpdateDialog> {
  final _dl = _DownloadState();

  Future<void> _startDownload() async {
    if (_dl.downloading) return;
    setState(() {
      _dl.downloading = true;
      _dl.error = null;
      _dl.progress = 0;
    });

    final url = _buildDownloadUrl(widget.updateInfo.latestVersion);
    final dir = await getTemporaryDirectory();
    final ext = defaultTargetPlatform == TargetPlatform.android ? 'apk' : 'ipa';
    final savePath = '${dir.path}/update_v${widget.updateInfo.latestVersion}.$ext';

    try {
      await for (final progress in rust.downloadUpdate(url: url, savePath: savePath, mirrorPrefixes: _ghMirrorPrefixes)) {
        if (!mounted) return;
        setState(() {
          _dl.received = progress.received.toInt();
          _dl.total = progress.total.toInt();
          if (progress.total > BigInt.zero) {
            _dl.progress = progress.received.toDouble() / progress.total.toDouble();
          }
          if (progress.done) {
            _dl.downloading = false;
            if (progress.error.isNotEmpty) {
              _dl.error = progress.error;
            } else {
              _dl.savedPath = progress.savedPath;
            }
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() { _dl.downloading = false; _dl.error = '下载失败: $e'; });
    }
  }

  Future<void> _installOrOpen() async {
    final path = _dl.savedPath;
    if (path == null) return;
    try {
      await OpenFilex.open(path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('无法打开文件: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final canDownload = defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Row(
        children: [
          Icon(Icons.system_update_rounded, color: cs.primary),
          const SizedBox(width: 10),
          const Text('发现新版本'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Version badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('v${widget.updateInfo.currentVersion}',
                      style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.arrow_forward_rounded, size: 18, color: cs.primary),
                  ),
                  Text('v${widget.updateInfo.latestVersion}',
                      style: tt.titleMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            // Download progress
            if (_dl.downloading) ...[
              const SizedBox(height: 20),
              LinearProgressIndicatorM3E(
                value: _dl.progress.isNaN ? null : _dl.progress,
                size: LinearProgressM3ESize.m,
              ),
              const SizedBox(height: 8),
              Text(
                _dl.total > 0
                    ? '${_formatBytes(_dl.received)} / ${_formatBytes(_dl.total)}'
                    : '正在下载...',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
            if (_dl.error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.errorContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 18, color: cs.error),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_dl.error!, style: tt.bodySmall?.copyWith(color: cs.onErrorContainer))),
                  ],
                ),
              ),
            ],
            if (_dl.savedPath != null && !_dl.downloading) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 18, color: cs.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text('下载完成，点击「安装更新」打开安装', style: tt.bodySmall?.copyWith(color: cs.onPrimaryContainer))),
                  ],
                ),
              ),
            ],
            // Release notes
            if (widget.updateInfo.releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('更新日志', style: tt.labelLarge),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: MarkdownWidget(
                    data: widget.updateInfo.releaseNotes,
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    config: MarkdownConfig(configs: [
                      PConfig(textStyle: tt.bodySmall ?? const TextStyle()),
                      H1Config(style: const TextStyle(fontWeight: FontWeight.bold)),
                      H2Config(style: const TextStyle(fontWeight: FontWeight.bold)),
                      H3Config(style: const TextStyle(fontWeight: FontWeight.bold)),
                      CodeConfig(style: TextStyle(backgroundColor: cs.surfaceContainerHighest, fontFamily: 'monospace', fontSize: 12)),
                      PreConfig(textStyle: tt.bodySmall?.copyWith(fontFamily: 'monospace', fontSize: 12) ?? const TextStyle(fontFamily: 'monospace', fontSize: 12), decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(8))),
                    ]),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!_dl.downloading && _dl.savedPath == null)
          M3ETextButton(
            onPressed: () => Navigator.pop(context),
            size: M3EButtonSize.md,
            shape: M3EButtonShape.round,
            child: const Text('稍后再说'),
          ),
        if (_dl.downloading)
          M3ETextButton(
            onPressed: null, // disabled while downloading
            size: M3EButtonSize.md,
            shape: M3EButtonShape.round,
            child: const Text('下载中...'),
          )
        else if (_dl.savedPath != null)
          M3EFilledButton.icon(
            icon: const Icon(Icons.install_mobile_rounded, size: 18),
            label: const Text('安装更新'),
            size: M3EButtonSize.md,
            shape: M3EButtonShape.round,
            onPressed: _installOrOpen,
          )
        else if (canDownload)
          M3EFilledButton.icon(
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('下载更新'),
            size: M3EButtonSize.md,
            shape: M3EButtonShape.round,
            onPressed: _startDownload,
          )
        else if (kIsWeb)
          M3EFilledButton.icon(
            icon: const Icon(Icons.phone_android_rounded, size: 18),
            label: const Text('下载本地应用'),
            size: M3EButtonSize.md,
            shape: M3EButtonShape.round,
            onPressed: () => _showWebDownloadSheet(context),
          )
        else
          M3EFilledButton.icon(
            icon: const Icon(Icons.open_in_browser_rounded, size: 18),
            label: const Text('前往下载'),
            size: M3EButtonSize.md,
            shape: M3EButtonShape.round,
            onPressed: () async {
              final url = Uri.parse(_buildDownloadUrl(widget.updateInfo.latestVersion));
              if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
              if (context.mounted) Navigator.pop(context);
            },
          ),
      ],
    );
  }

  void _showWebDownloadSheet(BuildContext context) {
    final v = widget.updateInfo.latestVersion;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('下载本地应用 v$v', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Gitee 镜像速度更快，GitHub 作为备选', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 16),
            for (final asset in _assets) ...[
              _DownloadAssetTile(
                label: asset.label,
                filename: asset.filename,
                version: v,
                primaryUrl: _giteeUrl(v, asset.filename),
                fallbackUrl: _ghUrl(v, asset.filename),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

/// A tappable row that opens [primaryUrl], falling back to [fallbackUrl] on error.
class _DownloadAssetTile extends StatelessWidget {
  final String label;
  final String filename;
  final String version;
  final String primaryUrl;
  final String fallbackUrl;

  const _DownloadAssetTile({
    required this.label,
    required this.filename,
    required this.version,
    required this.primaryUrl,
    required this.fallbackUrl,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _launchWithFallback(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.phone_android_rounded, size: 20, color: cs.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    Text(filename, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Gitee', style: tt.labelSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 2),
                  Text('备选 GitHub', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 9)),
                ],
              ),
              const SizedBox(width: 8),
              Icon(Icons.download_rounded, size: 20, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchWithFallback(BuildContext context) async {
    // Try Gitee first
    final primary = Uri.parse(primaryUrl);
    try {
      if (await canLaunchUrl(primary)) {
        await launchUrl(primary, mode: LaunchMode.platformDefault);
        return;
      }
    } catch (_) {}
    // Fallback to GitHub
    final fallback = Uri.parse(fallbackUrl);
    if (await canLaunchUrl(fallback)) {
      await launchUrl(fallback, mode: LaunchMode.platformDefault);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Cupertino Update Dialog
// ═══════════════════════════════════════════════════════════════════════════

class _CupertinoUpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;
  const _CupertinoUpdateDialog({required this.updateInfo});

  @override
  State<_CupertinoUpdateDialog> createState() => _CupertinoUpdateDialogState();
}

class _CupertinoUpdateDialogState extends State<_CupertinoUpdateDialog> {
  final _dl = _DownloadState();

  Future<void> _startDownload() async {
    if (_dl.downloading) return;
    setState(() { _dl.downloading = true; _dl.error = null; _dl.progress = 0; });

    final url = _buildDownloadUrl(widget.updateInfo.latestVersion);
    final dir = await getTemporaryDirectory();
    final ext = defaultTargetPlatform == TargetPlatform.android ? 'apk' : 'ipa';
    final savePath = '${dir.path}/update_v${widget.updateInfo.latestVersion}.$ext';

    try {
      await for (final progress in rust.downloadUpdate(url: url, savePath: savePath, mirrorPrefixes: _ghMirrorPrefixes)) {
        if (!mounted) return;
        setState(() {
          _dl.received = progress.received.toInt();
          _dl.total = progress.total.toInt();
          if (progress.total > BigInt.zero) {
            _dl.progress = progress.received.toDouble() / progress.total.toDouble();
          }
          if (progress.done) {
            _dl.downloading = false;
            if (progress.error.isNotEmpty) {
              _dl.error = progress.error;
            } else {
              _dl.savedPath = progress.savedPath;
            }
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() { _dl.downloading = false; _dl.error = '下载失败: $e'; });
    }
  }

  Future<void> _installOrOpen() async {
    final path = _dl.savedPath;
    if (path == null) return;
    try {
      await OpenFilex.open(path);
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            content: Text('无法打开文件: $e'),
            actions: [CupertinoDialogAction(isDefaultAction: true, child: const Text('好的'), onPressed: () => Navigator.pop(context))],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryLabel = CupertinoColors.secondaryLabel.resolveFrom(context);
    final accent = CupertinoColors.systemBlue.resolveFrom(context);
    final bgColor = CupertinoColors.systemGroupedBackground.resolveFrom(context);
    final cardColor = CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);
    final canDownload = defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

    final screenHeight = MediaQuery.of(context).size.height;
    final sheetHeight = screenHeight * 0.85;

    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 48, 8, 32),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: sheetHeight, maxWidth: 480),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: CupertinoPageScaffold(
                backgroundColor: bgColor,
                navigationBar: CupertinoNavigationBar(
                  backgroundColor: bgColor,
                  border: null,
                  leading: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _dl.downloading ? null : () => Navigator.pop(context),
                    child: Text(_dl.downloading ? '下载中...' : '稍后再说',
                        style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context))),
                  ),
                  middle: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.arrow_down_circle_fill, color: accent, size: 20),
                      const SizedBox(width: 6),
                      const Text('发现新版本', style: TextStyle(fontSize: 17)),
                    ],
                  ),
                  trailing: _dl.downloading
                      ? CupertinoActivityIndicator(radius: 10)
                      : _dl.savedPath != null
                          ? CupertinoButton.filled(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              minimumSize: const Size(0, 32),
                              onPressed: _installOrOpen,
                              child: const Text('安装', style: TextStyle(fontSize: 15, color: CupertinoColors.white)),
                            )
                          : canDownload
                              ? CupertinoButton.filled(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  minimumSize: const Size(0, 32),
                                  onPressed: _startDownload,
                                  child: const Text('下载', style: TextStyle(fontSize: 15, color: CupertinoColors.white)),
                                )
                              : kIsWeb
                                  ? CupertinoButton.filled(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                      minimumSize: const Size(0, 32),
                                      onPressed: () => _showWebDownloadSheet(context),
                                      child: const Text('本地应用', style: TextStyle(fontSize: 15, color: CupertinoColors.white)),
                                    )
                                  : CupertinoButton.filled(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                      minimumSize: const Size(0, 32),
                                      onPressed: () async {
                                        final url = Uri.parse(_buildDownloadUrl(widget.updateInfo.latestVersion));
                                        if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                                        if (context.mounted) Navigator.pop(context);
                                      },
                                      child: const Text('下载', style: TextStyle(fontSize: 15, color: CupertinoColors.white)),
                                    ),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Version info card
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Column(children: [
                                Text('当前版本', style: TextStyle(fontSize: 12, color: secondaryLabel)),
                                const SizedBox(height: 2),
                                Text('v${widget.updateInfo.currentVersion}', style: TextStyle(fontSize: 15, color: secondaryLabel)),
                              ]),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Icon(CupertinoIcons.arrow_right, size: 18, color: secondaryLabel),
                              ),
                              Column(children: [
                                Text('最新版本', style: TextStyle(fontSize: 12, color: secondaryLabel)),
                                const SizedBox(height: 2),
                                Text('v${widget.updateInfo.latestVersion}', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: accent)),
                              ]),
                            ],
                          ),
                        ),
  
                        // Download progress
                        if (_dl.downloading) ...[
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _dl.progress.isNaN ? null : _dl.progress,
                              minHeight: 6,
                              backgroundColor: CupertinoColors.systemGrey5.resolveFrom(context),
                              color: accent,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _dl.total > 0
                                ? '${_formatBytes(_dl.received)} / ${_formatBytes(_dl.total)}'
                                : '正在下载...',
                            style: TextStyle(fontSize: 12, color: secondaryLabel),
                          ),
                        ],
                        if (_dl.error != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: CupertinoColors.destructiveRed.resolveFrom(context).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(children: [
                              Icon(CupertinoIcons.exclamationmark_triangle, size: 18, color: CupertinoColors.destructiveRed.resolveFrom(context)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_dl.error!, style: TextStyle(fontSize: 13, color: CupertinoColors.destructiveRed.resolveFrom(context)))),
                            ]),
                          ),
                        ],
                        if (_dl.savedPath != null && !_dl.downloading) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGreen.resolveFrom(context).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(children: [
                              Icon(CupertinoIcons.checkmark_circle, size: 18, color: CupertinoColors.systemGreen.resolveFrom(context)),
                              const SizedBox(width: 8),
                              Expanded(child: Text('下载完成，点击「安装」打开安装', style: TextStyle(fontSize: 13, color: CupertinoColors.systemGreen.resolveFrom(context)))),
                            ]),
                          ),
                        ],
  
                        // Release notes
                        if (widget.updateInfo.releaseNotes.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 8),
                            child: Text('更新日志', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: secondaryLabel)),
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14)),
                            child: MarkdownWidget(
                              data: widget.updateInfo.releaseNotes,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              config: MarkdownConfig(configs: [
                                PConfig(textStyle: TextStyle(fontSize: 14, color: labelColor, height: 1.6)),
                                H1Config(style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: labelColor, height: 2)),
                                H2Config(style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: labelColor, height: 1.8)),
                                H3Config(style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: labelColor, height: 1.6)),
                                CodeConfig(style: TextStyle(backgroundColor: CupertinoColors.systemGrey5.resolveFrom(context), fontFamily: 'monospace', fontSize: 13)),
                                PreConfig(textStyle: TextStyle(fontFamily: 'monospace', fontSize: 13, color: labelColor, height: 1.5), decoration: BoxDecoration(color: CupertinoColors.systemGrey5.resolveFrom(context), borderRadius: BorderRadius.circular(8))),
                                ImgConfig(builder: (url, attributes) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(url, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => Container(padding: const EdgeInsets.all(16), alignment: Alignment.center, child: Icon(CupertinoIcons.photo, color: CupertinoColors.systemGrey.resolveFrom(context), size: 32)))))),
                                BlockquoteConfig(sideColor: accent, textColor: secondaryLabel),
                              ]),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showWebDownloadSheet(BuildContext context) {
    final v = widget.updateInfo.latestVersion;
    final secondaryLabel = CupertinoColors.secondaryLabel.resolveFrom(context);

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('下载本地应用 v$v',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('关闭'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Gitee 镜像速度更快，GitHub 作为备选',
                  style: TextStyle(fontSize: 13, color: secondaryLabel)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _assets.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final asset = _assets[i];
                  return _CupertinoAssetRow(
                    label: asset.label,
                    filename: asset.filename,
                    primaryUrl: _giteeUrl(v, asset.filename),
                    fallbackUrl: _ghUrl(v, asset.filename),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _CupertinoAssetRow extends StatelessWidget {
  final String label;
  final String filename;
  final String primaryUrl;
  final String fallbackUrl;

  const _CupertinoAssetRow({
    required this.label,
    required this.filename,
    required this.primaryUrl,
    required this.fallbackUrl,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);
    final secondaryLabel = CupertinoColors.secondaryLabel.resolveFrom(context);
    final accent = CupertinoColors.systemBlue.resolveFrom(context);

    return GestureDetector(
      onTap: () async {
        final primary = Uri.parse(primaryUrl);
        try {
          if (await canLaunchUrl(primary)) {
            await launchUrl(primary, mode: LaunchMode.platformDefault);
            return;
          }
        } catch (_) {}
        final fb = Uri.parse(fallbackUrl);
        if (await canLaunchUrl(fb)) {
          await launchUrl(fb, mode: LaunchMode.platformDefault);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(CupertinoIcons.device_phone_portrait, size: 20, color: accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(filename, style: TextStyle(fontSize: 11, color: secondaryLabel)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('Gitee', style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            Icon(CupertinoIcons.cloud_download, size: 18, color: secondaryLabel),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Utilities
// ═══════════════════════════════════════════════════════════════════════════

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
