import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signals/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:li_curriculum_table/core/presentation/adaptive_helpers.dart';
import 'package:li_curriculum_table/core/presentation/styles/styles.dart';
import 'package:li_curriculum_table/core/presentation/update/download_asset_tiles.dart';
import 'package:li_curriculum_table/core/presentation/update/update_constants.dart';
import 'package:li_curriculum_table/core/rust/api/update.dart' as rust;
import 'package:li_curriculum_table/core/services/update_service.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';

class LiquidGlassUpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;
  const LiquidGlassUpdateDialog({super.key, required this.updateInfo});

  @override
  State<LiquidGlassUpdateDialog> createState() =>
      _LiquidGlassUpdateDialogState();
}

class _LiquidGlassUpdateDialogState extends State<LiquidGlassUpdateDialog> {
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
        showAdaptiveMessage(
          context,
          designStyle: DesignStyle.cupertino,
          message: '无法打开文件: $e',
        );
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
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final canDownload =
            defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS;

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 36,
          ),
          child: GlassContainer(
            shape: const LiquidRoundedSuperellipse(borderRadius: 28),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.system_update_rounded,
                          color: cs.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '发现新版本',
                        style: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Version indicator capsule
                  GlassContainer(
                    shape: const LiquidRoundedSuperellipse(borderRadius: 14),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'v${widget.updateInfo.currentVersion}',
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: cs.primary,
                          ),
                        ),
                        Text(
                          'v${widget.updateInfo.latestVersion}',
                          style: tt.titleMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Downloading progress
                  if (dl.downloading) ...[
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: GlassProgressIndicator.linear(
                        value: dl.progress.isNaN ? null : dl.progress,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dl.total > 0
                          ? '${formatBytes(dl.received)} / ${formatBytes(dl.total)}'
                          : '正在下载...',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],

                  // Error notice
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

                  // Saved path notice
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
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Release notes
                  if (widget.updateInfo.releaseNotes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      '更新日志',
                      style: tt.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 220),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.08),
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
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
                  const SizedBox(height: 20),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!dl.downloading && dl.savedPath == null)
                        adaptiveButton(
                          context: context,
                          designStyle: DesignStyle.cupertino,
                          style: UiButtonStyle.text,
                          onPressed: () => Navigator.pop(context),
                          child: const Text('稍后再说'),
                        ),
                      const SizedBox(width: 10),
                      if (dl.downloading)
                        adaptiveButton(
                          context: context,
                          designStyle: DesignStyle.cupertino,
                          style: UiButtonStyle.text,
                          onPressed: null,
                          child: const Text('下载中...'),
                        )
                      else if (dl.savedPath != null)
                        adaptiveButton(
                          context: context,
                          designStyle: DesignStyle.cupertino,
                          style: UiButtonStyle.filled,
                          onPressed: _installOrOpen,
                          child: const Text('安装更新'),
                        )
                      else if (canDownload)
                        adaptiveButton(
                          context: context,
                          designStyle: DesignStyle.cupertino,
                          style: UiButtonStyle.filled,
                          onPressed: _startDownload,
                          child: const Text('下载更新'),
                        )
                      else if (kIsWeb)
                        adaptiveButton(
                          context: context,
                          designStyle: DesignStyle.cupertino,
                          style: UiButtonStyle.filled,
                          onPressed: () => _showWebDownloadSheet(context),
                          child: const Text('下载本地应用'),
                        )
                      else
                        adaptiveButton(
                          context: context,
                          designStyle: DesignStyle.cupertino,
                          style: UiButtonStyle.filled,
                          onPressed: () async {
                            final url = Uri.parse(
                              buildDownloadUrl(widget.updateInfo.latestVersion),
                            );
                            if (await canLaunchUrl(url)) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: const Text('前往下载'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showWebDownloadSheet(BuildContext context) {
    final v = widget.updateInfo.latestVersion;
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return GlassContainer(
          shape: const LiquidRoundedSuperellipse(borderRadius: 24),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '下载移动端或桌面端 (v$v)',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
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
        );
      },
    );
  }
}
