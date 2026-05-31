import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:li_curriculum_table/core/services/update_service.dart';

/// Shows update dialog if [updateInfo] indicates a new version is available.
/// Returns true if an update dialog was shown, false otherwise.
Future<bool> showUpdateDialogIfNeeded(
  BuildContext context,
  UpdateInfo? updateInfo, {
  bool silent = true,
}) async {
  if (updateInfo == null || !updateInfo.hasUpdate) {
    if (!silent && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前已是最新版本 ✨')),
      );
    }
    return false;
  }

  if (!context.mounted) return false;

  await showDialog(
    context: context,
    builder: (_) => UpdateDialog(updateInfo: updateInfo),
  );
  return true;
}

class UpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.system_update_rounded, color: colorScheme.primary),
          const SizedBox(width: 10),
          const Text('发现新版本'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Version info
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color:
                      colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
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
              const SizedBox(height: 16),
              // Release notes
              if (updateInfo.releaseNotes.isNotEmpty) ...[
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
                    child: Markdown(
                      data: updateInfo.releaseNotes,
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(12),
                      styleSheet: MarkdownStyleSheet(
                        p: textTheme.bodySmall,
                        h1: textTheme.titleSmall,
                        h2: textTheme.titleSmall,
                        h3: textTheme.titleSmall,
                        code: textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          backgroundColor:
                              colorScheme.surfaceContainerHighest,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
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
            final url = Uri.parse(updateInfo.releaseUrl);
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
