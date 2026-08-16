import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Material styled web download asset tile.
class DownloadAssetTile extends StatelessWidget {
  final String label;
  final String filename;
  final String version;
  final String primaryUrl;
  final String fallbackUrl;

  const DownloadAssetTile({
    super.key,
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
                    Text(
                      label,
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      filename,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Gitee',
                      style: tt.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '备选 GitHub',
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.download_rounded,
                size: 20,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchWithFallback(BuildContext context) async {
    final primary = Uri.parse(primaryUrl);
    try {
      if (await canLaunchUrl(primary)) {
        await launchUrl(primary, mode: LaunchMode.platformDefault);
        return;
      }
    } catch (_) {}
    final fallback = Uri.parse(fallbackUrl);
    if (await canLaunchUrl(fallback)) {
      await launchUrl(fallback, mode: LaunchMode.platformDefault);
    }
  }
}

/// Cupertino styled web download asset row.
class CupertinoAssetRow extends StatelessWidget {
  final String label;
  final String filename;
  final String primaryUrl;
  final String fallbackUrl;

  const CupertinoAssetRow({
    super.key,
    required this.label,
    required this.filename,
    required this.primaryUrl,
    required this.fallbackUrl,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = CupertinoColors.secondarySystemGroupedBackground
        .resolveFrom(context);
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
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    filename,
                    style: TextStyle(fontSize: 11, color: secondaryLabel),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Gitee',
                style: TextStyle(
                  fontSize: 12,
                  color: accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              CupertinoIcons.cloud_download,
              size: 18,
              color: secondaryLabel,
            ),
          ],
        ),
      ),
    );
  }
}
