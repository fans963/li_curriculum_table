import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:li_curriculum_table/features/settings/presentation/pages/tabs/settings_sections.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Material 3 Expressive styled web download tile.
class M3EDownloadTile extends StatelessWidget {
  final String label;
  final String filename;
  final String version;
  final String giteeUrl;
  final String ghUrl;

  const M3EDownloadTile({
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
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        title: Text(label),
        subtitle: Text(
          filename,
          style: TextStyle(fontSize: 11, color: cs.outline),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            M3EIconButton(
              icon: const Icon(Icons.cloud_download_outlined),
              variant: M3EIconButtonVariant.standard,
              shape: M3EIconButtonShapeVariant.round,
              tooltip: 'Gitee 下载',
              onPressed: () => launchUrl(Uri.parse(giteeUrl)),
            ),
            M3EIconButton(
              icon: const Icon(Icons.open_in_new),
              variant: M3EIconButtonVariant.standard,
              shape: M3EIconButtonShapeVariant.round,
              tooltip: 'GitHub 下载',
              onPressed: () => launchUrl(Uri.parse(ghUrl)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Material 3 Expressive styled "下载本地应用" section card.
class M3EWebDownloadCard extends StatelessWidget {
  const M3EWebDownloadCard({super.key});

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
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '';
        return SectionCard(
          icon: Icons.phone_android_rounded,
          title: '下载本地应用',
          subtitle: '在手机或电脑上安装原生版本',
          child: Column(
            children: [
              for (var i = 0; i < _assets.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                M3EDownloadTile(
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
