import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loading_indicator_m3e/loading_indicator_m3e.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_helpers.dart';
import 'package:li_curriculum_table/core/presentation/update_dialog.dart';
import 'package:li_curriculum_table/core/services/update_service.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';

/// Material styled "关于" card with app icon, version, update check and GitHub link.
class MaterialAboutCard extends StatelessWidget {
  const MaterialAboutCard({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            final version = snapshot.data?.version ?? '...';
            final buildNumber = snapshot.data?.buildNumber ?? '';

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset('assets/icon/icon.png'),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '🍐 课表',
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'v$version${buildNumber.isNotEmpty ? ' ($buildNumber)' : ''}',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Text(
                  '一款轻盈优雅的跨平台本地安全课表应用',
                  textAlign: TextAlign.center,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    M3EFilledButton.tonalIcon(
                      icon: const Icon(Icons.system_update_rounded, size: 18),
                      label: const Text('检查更新'),
                      size: M3EButtonSize.md,
                      shape: M3EButtonShape.round,
                      onPressed: () => _checkForUpdateManually(context),
                    ),
                    M3EOutlinedButton.icon(
                      icon: const Icon(Icons.code_rounded, size: 18),
                      label: const Text('GitHub'),
                      size: M3EButtonSize.md,
                      shape: M3EButtonShape.round,
                      onPressed: () => launchUrl(
                        Uri.parse('https://github.com/fans963/--table'),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _checkForUpdateManually(BuildContext context) async {
    final ds = sl<SettingsController>().designStyle.value;
    final isCupertino = AdaptiveStyle.isCupertino(ds);

    if (isCupertino) {
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const CupertinoAlertDialog(
          content: Padding(
            padding: EdgeInsets.only(top: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoActivityIndicator(),
                SizedBox(height: 12),
                Text('正在检查更新...'),
              ],
            ),
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LoadingIndicatorM3E(),
                  SizedBox(height: 16),
                  Text('正在检查更新...'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    try {
      final updateInfo = await sl<UpdateService>().checkForUpdate();
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      if (context.mounted) {
        await showUpdateDialogIfNeeded(context, updateInfo, silent: false);
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      if (!context.mounted) return;
      showAdaptiveMessage(context, designStyle: ds, message: '检查更新失败，请稍后重试');
    }
  }
}
