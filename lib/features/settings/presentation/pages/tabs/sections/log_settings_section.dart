import 'package:material_ui/material_ui.dart';

import 'package:li_curriculum_table/core/presentation/adaptive_helpers.dart';
import 'package:li_curriculum_table/core/services/app_logger.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';

import '../settings_sections.dart';

class LogSettingsSection extends StatelessWidget {
  const LogSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SectionCard(
      icon: Icons.article_outlined,
      title: '日志',
      subtitle: '查看或清除本地运行日志',
      child: Column(
        children: [
          SettingsTile(
            icon: Icons.visibility_outlined,
            title: '查看日志',
            subtitle: '查看当前应用运行日志',
            onTap: () => _viewLogs(context),
          ),
          const Divider(height: 1),
          SettingsTile(
            icon: Icons.delete_outline_rounded,
            title: '清除日志',
            subtitle: '删除本地日志文件',
            iconColor: cs.error,
            onTap: () => _confirmClear(context),
          ),
        ],
      ),
    );
  }

  Future<void> _viewLogs(BuildContext context) async {
    final logs = await AppLogger.instance.exportRecentLogs();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('运行日志'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 420, maxWidth: 560),
          child: logs.trim().isEmpty
              ? const Center(child: Text('暂无日志'))
              : SingleChildScrollView(
                  child: SelectableText(
                    logs,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      height: 1.35,
                    ),
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showAdaptiveConfirmDialog(
      context,
      designStyle: sl<SettingsController>().designStyle.value,
      title: '清除日志？',
      content: '删除后无法恢复，反馈历史日志也将被清空。',
      confirmText: '清除',
      cancelText: '取消',
      isDestructive: true,
    );
    if (!confirmed) return;

    await AppLogger.instance.clearLogs();
    if (context.mounted) {
      showAdaptiveMessage(
        context,
        designStyle: sl<SettingsController>().designStyle.value,
        message: '日志已清除',
      );
    }
  }
}
