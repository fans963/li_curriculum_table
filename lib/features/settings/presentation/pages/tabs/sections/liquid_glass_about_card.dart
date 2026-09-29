import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_helpers.dart';
import 'package:li_curriculum_table/core/presentation/styles/styles.dart';
import 'package:li_curriculum_table/core/presentation/update_dialog.dart';
import 'package:li_curriculum_table/core/services/update_service.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';

/// iOS 26 Liquid Glass styled "关于" card.
class LiquidGlassAboutCard extends StatelessWidget {
  const LiquidGlassAboutCard({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final cardContent = FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '...';
        final buildNumber = snapshot.data?.buildNumber ?? '';

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassContainer(
              shape: const LiquidRoundedSuperellipse(borderRadius: 22),
              clipBehavior: Clip.antiAlias,
              padding: const EdgeInsets.all(4),
              child: SizedBox(
                width: 68,
                height: 68,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset('assets/icon/icon.png'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '🍐 课表',
              style: tt.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'v$version${buildNumber.isNotEmpty ? ' ($buildNumber)' : ''}',
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '一款轻盈优雅的跨平台本地安全课表应用',
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                GlassButton.custom(
                  onTap: () => _checkForUpdateManually(context),
                  shape: const LiquidRoundedSuperellipse(borderRadius: 16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.arrow_2_circlepath,
                          size: 16,
                          color: cs.onPrimary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '检查更新',
                          style: TextStyle(
                            color: cs.onPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GlassButton.custom(
                  onTap: () => launchUrl(
                    Uri.parse('https://github.com/fans963/--table'),
                    mode: LaunchMode.externalApplication,
                  ),
                  shape: const LiquidRoundedSuperellipse(borderRadius: 16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.chevron_left_slash_chevron_right,
                          size: 16,
                          color: cs.onSurface,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'GitHub',
                          style: TextStyle(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    final style = UiStyleRegistry.resolve(DesignStyle.cupertino);
    return style.buildCard(
      context: context,
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: cardContent,
    );
  }

  Future<void> _checkForUpdateManually(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: GlassContainer(
          shape: const LiquidRoundedSuperellipse(borderRadius: 24),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlassProgressIndicator.circular(size: 32, color: cs.primary),
              const SizedBox(height: 18),
              Text(
                '正在检查更新...',
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final updateInfo = await sl<UpdateService>().checkForUpdate();
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      if (context.mounted) {
        await showUpdateDialogIfNeeded(context, updateInfo, silent: false);
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      if (!context.mounted) return;
      showAdaptiveMessage(context, message: '检查更新失败，请稍后重试');
    }
  }
}
