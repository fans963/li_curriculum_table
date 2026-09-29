import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_helpers.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/features/settings/presentation/pages/tabs/settings_sections.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// iOS 26 Liquid Glass styled web download tile.
class LiquidGlassDownloadTile extends StatelessWidget {
  final String label;
  final String filename;
  final String version;
  final String giteeUrl;
  final String ghUrl;

  const LiquidGlassDownloadTile({
    super.key,
    required this.label,
    required this.filename,
    required this.version,
    required this.giteeUrl,
    required this.ghUrl,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  filename,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.outline,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              adaptiveIconButton(
                designStyle: DesignStyle.cupertino,
                icon: const Icon(CupertinoIcons.arrow_down_to_line, size: 18),
                tooltip: 'Gitee 下载',
                onPressed: () => launchUrl(Uri.parse(giteeUrl)),
              ),
              const SizedBox(width: 4),
              adaptiveIconButton(
                designStyle: DesignStyle.cupertino,
                icon: const Icon(CupertinoIcons.arrow_up_right, size: 18),
                tooltip: 'GitHub 下载',
                onPressed: () => launchUrl(Uri.parse(ghUrl)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// iOS 26 Liquid Glass styled "下载本地应用" section card.
class LiquidGlassWebDownloadCard extends StatelessWidget {
  const LiquidGlassWebDownloadCard({super.key});

  static const _owner = 'fans963';
  static const _repo = 'li_curriculum_table';
  static const _assets = [
    ('app-arm64-v8a-release.apk', 'Android ARM64'),
    ('app-armeabi-v7a-release.apk', 'Android ARM32'),
    ('app-x86_64-release.apk', 'Android x86_64'),
    ('li-curriculum-table-unsigned.ipa', 'iOS (IPA)'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '';
        return SectionCard(
          icon: CupertinoIcons.device_phone_portrait,
          title: '下载本地应用',
          subtitle: '在手机或电脑上安装原生版本',
          designStyle: DesignStyle.cupertino,
          child: Column(
            children: [
              for (var i = 0; i < _assets.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                  ),
                LiquidGlassDownloadTile(
                  label: _assets[i].$2,
                  filename: _assets[i].$1,
                  version: version,
                  giteeUrl:
                      'https://gitee.com/$_owner/$_repo/releases/download/v$version/${_assets[i].$1}',
                  ghUrl:
                      'https://github.com/$_owner/$_repo/releases/download/v$version/${_assets[i].$1}',
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
