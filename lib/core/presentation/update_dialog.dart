import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:li_curriculum_table/core/services/update_service.dart';

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

// ─── Material Update Dialog ──────────────────────────────────────────────────

class _MaterialUpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;

  const _MaterialUpdateDialog({required this.updateInfo});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Row(
        children: [
          Icon(Icons.system_update_rounded, color: colorScheme.primary),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'v${updateInfo.currentVersion}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.arrow_forward_rounded,
                        size: 18, color: colorScheme.primary),
                  ),
                  Text(
                    'v${updateInfo.latestVersion}',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (updateInfo.releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('更新日志', style: textTheme.labelLarge),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 260),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: MarkdownWidget(
                    data: updateInfo.releaseNotes,
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    config: MarkdownConfig(configs: [
                      PConfig(
                          textStyle:
                              textTheme.bodySmall ?? const TextStyle()),
                      H1Config(
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                      H2Config(
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                      H3Config(
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                      CodeConfig(
                        style: TextStyle(
                          backgroundColor:
                              colorScheme.surfaceContainerHighest,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                      PreConfig(
                        textStyle: textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ) ??
                            const TextStyle(
                                fontFamily: 'monospace', fontSize: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('稍后再说'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.download_rounded, size: 18),
          label: const Text('前往下载'),
          onPressed: () async {
            try {
              final url = Uri.parse(updateInfo.releaseUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            } catch (e) {
              debugPrint('Failed to launch URL: $e');
            }
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

// ─── Cupertino Update Dialog ─────────────────────────────────────────────────

class _CupertinoUpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;

  const _CupertinoUpdateDialog({required this.updateInfo});

  @override
  Widget build(BuildContext context) {
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryLabel =
        CupertinoColors.secondaryLabel.resolveFrom(context);
    final accent = CupertinoColors.systemBlue.resolveFrom(context);
    final bgColor = CupertinoColors.systemGroupedBackground.resolveFrom(context);
    final cardColor =
        CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);

    final screenHeight = MediaQuery.of(context).size.height;
    final sheetHeight = screenHeight * 0.85;

    return Padding(
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
                  onPressed: () => Navigator.pop(context),
                  child: Text('稍后再说',
                      style: TextStyle(
                          color: CupertinoColors.secondaryLabel
                              .resolveFrom(context))),
                ),
                middle: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.arrow_down_circle_fill,
                        color: accent, size: 20),
                    const SizedBox(width: 6),
                    const Text('发现新版本',
                        style: TextStyle(fontSize: 17)),
                  ],
                ),
                trailing: CupertinoButton.filled(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  minimumSize: const Size(0, 32),
                  onPressed: () async {
                    try {
                      final url = Uri.parse(updateInfo.releaseUrl);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url,
                            mode: LaunchMode.externalApplication);
                      }
                    } catch (e) {
                      debugPrint('Failed to launch URL: $e');
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('下载',
                      style:
                          TextStyle(fontSize: 15, color: CupertinoColors.white)),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              children: [
                                Text('当前版本',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: secondaryLabel)),
                                const SizedBox(height: 2),
                                Text('v${updateInfo.currentVersion}',
                                    style: TextStyle(
                                        fontSize: 15,
                                        color: secondaryLabel)),
                              ],
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Icon(CupertinoIcons.arrow_right,
                                  size: 18, color: secondaryLabel),
                            ),
                            Column(
                              children: [
                                Text('最新版本',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: secondaryLabel)),
                                const SizedBox(height: 2),
                                Text('v${updateInfo.latestVersion}',
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: accent)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Release notes
                      if (updateInfo.releaseNotes.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text('更新日志',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: secondaryLabel)),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: MarkdownWidget(
                            data: updateInfo.releaseNotes,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            config: MarkdownConfig(configs: [
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
                                      height: 2)),
                              H2Config(
                                  style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: labelColor,
                                      height: 1.8)),
                              H3Config(
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: labelColor,
                                      height: 1.6)),
                              CodeConfig(
                                style: TextStyle(
                                  backgroundColor:
                                      CupertinoColors.systemGrey5
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
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              ImgConfig(
                                builder: (url, attributes) {
                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        url,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            padding: const EdgeInsets.all(16),
                                            alignment: Alignment.center,
                                            child: Icon(
                                              CupertinoIcons.photo,
                                              color: CupertinoColors
                                                  .systemGrey
                                                  .resolveFrom(context),
                                              size: 32,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                              BlockquoteConfig(
                                sideColor: accent,
                                textColor: secondaryLabel,
                              ),
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
    );
  }
}
