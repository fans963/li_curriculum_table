import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:progress_indicator_m3e/progress_indicator_m3e.dart';
import 'package:signals/signals_flutter.dart';
import 'package:li_curriculum_table/core/presentation/update/update_constants.dart';
import 'package:li_curriculum_table/core/presentation/update/download_asset_tiles.dart';
import 'package:li_curriculum_table/core/rust/api/update.dart' as rust;
import 'package:li_curriculum_table/core/services/update_service.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class MaterialUpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;
  const MaterialUpdateDialog({super.key, required this.updateInfo});

  @override
  State<MaterialUpdateDialog> createState() => _MaterialUpdateDialogState();
}

class _MaterialUpdateDialogState extends State<MaterialUpdateDialog> {
  final _dl = signal(DownloadState());

  Future<void> _startDownload() async {
    if (_dl.value.downloading) return;
    _dl.value = DownloadState()..downloading = true;

    final url = buildDownloadUrl(widget.updateInfo.latestVersion);
    final dir = await getTemporaryDirectory();
    final ext = defaultTargetPlatform == TargetPlatform.android ? 'apk' : 'ipa';
    final savePath =
        '${dir.path}/update_v${widget.updateInfo.latestVersion}.$ext';

    try {
      await for (final progress in rust.downloadUpdate(
        url: url,
        savePath: savePath,
        mirrorPrefixes: ghMirrorPrefixes,
      )) {
        if (!mounted) return;
        final updated = DownloadState()
          ..received = progress.received.toInt()
          ..total = progress.total.toInt()
          ..progress = progress.total > BigInt.zero
              ? progress.received.toDouble() / progress.total.toDouble()
              : 0;
        if (progress.done) {
          updated.downloading = false;
          if (progress.error.isNotEmpty) {
            updated.error = progress.error;
          } else {
            updated.savedPath = progress.savedPath;
          }
        } else {
          updated.downloading = _dl.value.downloading;
          updated.error = _dl.value.error;
          updated.savedPath = _dl.value.savedPath;
        }
        _dl.value = updated;
      }
    } catch (e) {
      if (mounted) {
        _dl.value = DownloadState()
          ..downloading = false
          ..error = '下载失败: $e';
      }
    }
  }

  Future<void> _installOrOpen() async {
    final path = _dl.value.savedPath;
    if (path == null) return;
    try {
      await OpenFilex.open(path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('无法打开文件: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final dl = _dl.value;
        final cs = Theme.of(context).colorScheme;
        final tt = Theme.of(context).textTheme;
        final canDownload =
            defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'v${widget.updateInfo.currentVersion}',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: cs.primary,
                        ),
                      ),
                      Text(
                        'v${widget.updateInfo.latestVersion}',
                        style: tt.titleMedium?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (dl.downloading) ...[
                  const SizedBox(height: 20),
                  LinearProgressIndicatorM3E(
                    value: dl.progress.isNaN ? null : dl.progress,
                    size: LinearProgressM3ESize.m,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dl.total > 0
                        ? '${formatBytes(dl.received)} / ${formatBytes(dl.total)}'
                        : '正在下载...',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
                if (dl.error != null) ...[
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
                        Expanded(
                          child: Text(
                            dl.error!,
                            style: tt.bodySmall?.copyWith(
                              color: cs.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (dl.savedPath != null && !dl.downloading) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: cs.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '下载完成，点击「安装更新」打开安装',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                        config: MarkdownConfig(
                          configs: [
                            PConfig(
                              textStyle: tt.bodySmall ?? const TextStyle(),
                            ),
                            H1Config(
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            H2Config(
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            H3Config(
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            CodeConfig(
                              style: TextStyle(
                                backgroundColor: cs.surfaceContainerHighest,
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                            PreConfig(
                              textStyle:
                                  tt.bodySmall?.copyWith(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ) ??
                                  const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (!dl.downloading && dl.savedPath == null)
              M3ETextButton(
                onPressed: () => Navigator.pop(context),
                size: M3EButtonSize.md,
                shape: M3EButtonShape.round,
                child: const Text('稍后再说'),
              ),
            if (dl.downloading)
              M3ETextButton(
                onPressed: null,
                size: M3EButtonSize.md,
                shape: M3EButtonShape.round,
                child: const Text('下载中...'),
              )
            else if (dl.savedPath != null)
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
                  final url = Uri.parse(
                    buildDownloadUrl(widget.updateInfo.latestVersion),
                  );
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                  if (context.mounted) Navigator.pop(context);
                },
              ),
          ],
        );
      },
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '下载本地应用 v$v',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Gitee 镜像速度更快，GitHub 作为备选',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            for (final asset in assets) ...[
              DownloadAssetTile(
                label: asset.label,
                filename: asset.filename,
                version: v,
                primaryUrl: giteeUrl(v, asset.filename),
                fallbackUrl: ghUrl(v, asset.filename),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}
