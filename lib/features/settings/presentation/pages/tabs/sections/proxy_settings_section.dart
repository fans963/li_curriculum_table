import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_helpers.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';

import '../settings_sections.dart';

class ProxySettingsSection extends StatelessWidget {
  const ProxySettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = sl<SettingsController>().state.value;
    final notifier = sl<SettingsController>();
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final ds = settings.designStyle;

    return SectionCard(
      icon: AppIcons.lan(ds),
      title: '网络代理',
      subtitle: '允许其他设备通过此应用中转教务系统请求',
      child: Column(
        children: [
          if (!kIsWeb) ...[
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              secondary: Icon(
                AppIcons.router(ds),
                size: 20,
                color: cs.onSurfaceVariant,
              ),
              title: const Text('开启本地代理网关'),
              subtitle: const Text('其他设备或本机网页版可通过此应用共享会话'),
              value: settings.proxyEnabled,
              onChanged: (v) => notifier.setProxyEnabled(v),
            ),
            SettingsTile(
              icon: AppIcons.numbers(ds),
              title: '监听端口',
              subtitle: '${settings.proxyPort}（重启后生效）',
              onTap: () => _showPortDialog(
                context,
                settings.proxyPort,
                (p) => notifier.setProxyPort(p),
              ),
            ),
          ] else ...[
            SettingsTile(
              icon: AppIcons.radar(ds),
              title: 'Native 代理探测端口',
              subtitle: '${settings.proxyPort}（刷新后生效）',
              onTap: () => _showPortDialog(
                context,
                settings.proxyPort,
                (p) => notifier.setProxyPort(p),
              ),
            ),
          ],
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(AppIcons.info(ds), size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '设置正确的端口可让网页版自动识别并使用手机端的登录状态，无需重复验证。',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPortDialog(
    BuildContext context,
    int current,
    Function(int) onSave,
  ) async {
    final result = await showAdaptiveInputDialog(
      context,
      designStyle: sl<SettingsController>().designStyle.value,
      title: '设置代理端口',
      placeholder: '默认 9999',
      initialValue: current.toString(),
      keyboardType: TextInputType.number,
      confirmText: '保存',
      cancelText: '取消',
    );
    if (result != null) {
      final port = int.tryParse(result);
      if (port != null && port >= 1024 && port <= 65535) onSave(port);
    }
  }
}
