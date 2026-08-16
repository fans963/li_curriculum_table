import 'package:material_ui/material_ui.dart';
import 'package:li_curriculum_table/features/settings/presentation/pages/tabs/settings_sections.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Material styled web download card for the settings tab.
class MaterialDownloadTile extends StatelessWidget {
  final String label;
  final String filename;
  final String version;
  final String giteeUrl;
  final String ghUrl;

  const MaterialDownloadTile({
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
    return ListTile(
      title: Text(label),
      subtitle: Text(
        filename,
        style: TextStyle(fontSize: 11, color: cs.outline),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.cloud_download_outlined),
            tooltip: 'Gitee 下载',
            onPressed: () => launchUrl(Uri.parse(giteeUrl)),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: 'GitHub 下载',
            onPressed: () => launchUrl(Uri.parse(ghUrl)),
          ),
        ],
      ),
    );
  }
}

/// Material styled "下载本地应用" section card.
class MaterialWebDownloadCard extends StatelessWidget {
  const MaterialWebDownloadCard({super.key});

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
                MaterialDownloadTile(
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
