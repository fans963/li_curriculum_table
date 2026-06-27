import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signals/signals_flutter.dart';
import 'package:li_curriculum_table/core/presentation/update/update_constants.dart';
import 'package:li_curriculum_table/core/presentation/update/download_asset_tiles.dart';
import 'package:li_curriculum_table/core/rust/api/update.dart' as rust;
import 'package:li_curriculum_table/core/services/update_service.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class CupertinoUpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;
  const CupertinoUpdateDialog({super.key, required this.updateInfo});

  @override
  State<CupertinoUpdateDialog> createState() => _CupertinoUpdateDialogState();
}

class _CupertinoUpdateDialogState extends State<CupertinoUpdateDialog> {
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
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            content: Text('无法打开文件: $e'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('好的'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final dl = _dl.value;
        final labelColor = CupertinoColors.label.resolveFrom(context);
        final secondaryLabel = CupertinoColors.secondaryLabel.resolveFrom(
          context,
        );
        final accent = CupertinoColors.systemBlue.resolveFrom(context);
        final bgColor = CupertinoColors.systemGroupedBackground.resolveFrom(
          context,
        );
        final cardColor = CupertinoColors.secondarySystemGroupedBackground
            .resolveFrom(context);
        final canDownload =
            defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS;

        final screenHeight = MediaQuery.of(context).size.height;
        final sheetHeight = screenHeight * 0.85;

        return Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 48, 8, 32),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: sheetHeight,
                  maxWidth: 480,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: CupertinoPageScaffold(
                    backgroundColor: bgColor,
                    navigationBar: CupertinoNavigationBar(
                      backgroundColor: bgColor,
                      border: null,
                      leading: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: dl.downloading
                            ? null
                            : () => Navigator.pop(context),
                        child: Text(
                          dl.downloading ? '下载中...' : '稍后再说',
                          style: TextStyle(
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                          ),
                        ),
                      ),
                      middle: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.arrow_down_circle_fill,
                            color: accent,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          const Text('发现新版本', style: TextStyle(fontSize: 17)),
                        ],
                      ),
                      trailing: dl.downloading
                          ? CupertinoActivityIndicator(radius: 10)
                          : dl.savedPath != null
                          ? CupertinoButton.filled(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              minimumSize: const Size(0, 32),
                              onPressed: _installOrOpen,
                              child: const Text(
                                '安装',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: CupertinoColors.white,
                                ),
                              ),
                            )
                          : canDownload
                          ? CupertinoButton.filled(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              minimumSize: const Size(0, 32),
                              onPressed: _startDownload,
                              child: const Text(
                                '下载',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: CupertinoColors.white,
                                ),
                              ),
                            )
                          : kIsWeb
                          ? CupertinoButton.filled(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              minimumSize: const Size(0, 32),
                              onPressed: () => _showWebDownloadSheet(context),
                              child: const Text(
                                '本地应用',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: CupertinoColors.white,
                                ),
                              ),
                            )
                          : CupertinoButton.filled(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              minimumSize: const Size(0, 32),
                              onPressed: () async {
                                final url = Uri.parse(
                                  buildDownloadUrl(
                                    widget.updateInfo.latestVersion,
                                  ),
                                );
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(
                                    url,
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                                if (context.mounted) Navigator.pop(context);
                              },
                              child: const Text(
                                '下载',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: CupertinoColors.white,
                                ),
                              ),
                            ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        '当前版本',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: secondaryLabel,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'v${widget.updateInfo.currentVersion}',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: secondaryLabel,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Icon(
                                      CupertinoIcons.arrow_right,
                                      size: 18,
                                      color: secondaryLabel,
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        '最新版本',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: secondaryLabel,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'v${widget.updateInfo.latestVersion}',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: accent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (dl.downloading) ...[
                              const SizedBox(height: 16),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: dl.progress.isNaN ? null : dl.progress,
                                  minHeight: 6,
                                  backgroundColor: CupertinoColors.systemGrey5
                                      .resolveFrom(context),
                                  color: accent,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                dl.total > 0
                                    ? '${formatBytes(dl.received)} / ${formatBytes(dl.total)}'
                                    : '正在下载...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: secondaryLabel,
                                ),
                              ),
                            ],
                            if (dl.error != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.destructiveRed
                                      .resolveFrom(context)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      CupertinoIcons.exclamationmark_triangle,
                                      size: 18,
                                      color: CupertinoColors.destructiveRed
                                          .resolveFrom(context),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        dl.error!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: CupertinoColors.destructiveRed
                                              .resolveFrom(context),
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
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemGreen
                                      .resolveFrom(context)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      CupertinoIcons.checkmark_circle,
                                      size: 18,
                                      color: CupertinoColors.systemGreen
                                          .resolveFrom(context),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '下载完成，点击「安装」打开安装',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: CupertinoColors.systemGreen
                                              .resolveFrom(context),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (widget.updateInfo.releaseNotes.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 4,
                                  bottom: 8,
                                ),
                                child: Text(
                                  '更新日志',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: secondaryLabel,
                                  ),
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: MarkdownWidget(
                                  data: widget.updateInfo.releaseNotes,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  config: MarkdownConfig(
                                    configs: [
                                      PConfig(
                                        textStyle: TextStyle(
                                          fontSize: 14,
                                          color: labelColor,
                                          height: 1.6,
                                        ),
                                      ),
                                      H1Config(
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: labelColor,
                                          height: 2,
                                        ),
                                      ),
                                      H2Config(
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          color: labelColor,
                                          height: 1.8,
                                        ),
                                      ),
                                      H3Config(
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: labelColor,
                                          height: 1.6,
                                        ),
                                      ),
                                      CodeConfig(
                                        style: TextStyle(
                                          backgroundColor: CupertinoColors
                                              .systemGrey5
                                              .resolveFrom(context),
                                          fontFamily: 'monospace',
                                          fontSize: 13,
                                        ),
                                      ),
                                      PreConfig(
                                        textStyle: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 13,
                                          color: labelColor,
                                          height: 1.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: CupertinoColors.systemGrey5
                                              .resolveFrom(context),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      ImgConfig(
                                        builder: (url, attributes) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              url,
                                              fit: BoxFit.contain,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          16,
                                                        ),
                                                    alignment: Alignment.center,
                                                    child: Icon(
                                                      CupertinoIcons.photo,
                                                      color: CupertinoColors
                                                          .systemGrey
                                                          .resolveFrom(context),
                                                      size: 32,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      BlockquoteConfig(
                                        sideColor: accent,
                                        textColor: secondaryLabel,
                                      ),
                                    ],
                                  ),
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
      },
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
                  Text(
                    '下载本地应用 v$v',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
              child: Text(
                'Gitee 镜像速度更快，GitHub 作为备选',
                style: TextStyle(fontSize: 13, color: secondaryLabel),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: assets.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final asset = assets[i];
                  return CupertinoAssetRow(
                    label: asset.label,
                    filename: asset.filename,
                    primaryUrl: giteeUrl(v, asset.filename),
                    fallbackUrl: ghUrl(v, asset.filename),
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
