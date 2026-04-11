import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:li_curriculum_table/features/timetable/domain/entities/login_credentials.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/timetable_page_sections.dart';
import 'package:li_curriculum_table/features/timetable/presentation/providers/timetable_providers.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/app/app.dart';

class SettingsTab extends ConsumerStatefulWidget {
  const SettingsTab({super.key});

  @override
  ConsumerState<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<SettingsTab> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  Timer? _saveDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(timetableControllerProvider.notifier);
      await notifier.restoreCachedTimetable();
      await notifier.restoreCachedTeachingWeekBaseline();
      await _restoreCachedCredentials();

      // Auto-save credentials when user types (debounced)
      _usernameController.addListener(_onCredentialsChanged);
      _passwordController.addListener(_onCredentialsChanged);
    });
  }

  void _onCredentialsChanged() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 800), () {
      final u = _usernameController.text.trim();
      final p = _passwordController.text;
      if (u.isNotEmpty && p.isNotEmpty) {
        final cacheCredentials = ref.read(cacheCredentialsUseCaseProvider);
        cacheCredentials(LoginCredentials(username: u, password: p));
      }
    });
  }

  Future<void> _restoreCachedCredentials() async {
    try {
      final loadCachedCredentials =
          ref.read(loadCachedCredentialsUseCaseProvider);
      final cached = await loadCachedCredentials();
      if (!mounted || cached == null) return;
      _usernameController.text = cached.username;
      _passwordController.text = cached.password;
    } catch (_) {}
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timetableControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                const _SectionHeader(
                  title: '教务系统登录',
                  icon: Icons.vpn_key_outlined,
                ),
                const SizedBox(height: 8),
                TimetableControlPanel(
                  usernameController: _usernameController,
                  passwordController: _passwordController,
                  isLoading: state.isLoading,
                  currentTeachingWeek: state.currentTeachingWeek,
                  minWeek: state.minWeek,
                  maxWeek: state.maxWeek,
                  onTeachingWeekChanged: (week) {
                    ref
                        .read(timetableControllerProvider.notifier)
                        .setCurrentTeachingWeek(week);
                  },
                ),
                const SizedBox(height: 24),
                const _SectionHeader(
                  title: '数据同步状态',
                  icon: Icons.sync_problem_rounded,
                ),
                const SizedBox(height: 8),
                TimetableStatusBanner(
                  status: state.status,
                  isLoading: state.isLoading,
                  hasData: state.data != null,
                ),
                const SizedBox(height: 32),
                const _SectionHeader(
                  title: '存储与缓存',
                  icon: Icons.storage_rounded,
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: const Text('清除所有缓存'),
                  subtitle: const Text('删除本地存储的课表、教室、成绩等缓存数据，保留登录凭据'),
                  leading: const Icon(Icons.delete_sweep_rounded),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _confirmClearCache(context),
                ),
                const SizedBox(height: 32),
                const _SectionHeader(
                  title: '增强功能：本地代理',
                  icon: Icons.lan_outlined,
                ),
                const SizedBox(height: 8),
                const _ProxySettingsSection(),
                const SizedBox(height: 32),
                _buildInfoSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClearCache(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除缓存？'),
        content: const Text('这将删除所有离线课表和缓存数据。您仍将保持登录状态，但需要重新同步以加载数据。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(timetableControllerProvider.notifier).clearAllCache();
    }
  }

  Widget _buildInfoSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        const Divider(height: 1),
      ],
    );
  }
}

class _ProxySettingsSection extends ConsumerWidget {
  const _ProxySettingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final notifier = ref.read(settingsControllerProvider.notifier);

    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        if (!isWeb) ...[
          SwitchListTile(
            title: const Text('开启本地代理网关'),
            subtitle: const Text('允许其他设备（或本机的网页版）通过此应用中转教务系统请求，实现会话共享与加速。'),
            value: settings.proxyEnabled,
            onChanged: (val) => notifier.setProxyEnabled(val),
            secondary: const Icon(Icons.router_rounded),
          ),
          ListTile(
            title: const Text('服务端监听端口'),
            subtitle: Text('当前设置: ${settings.proxyPort} (重启服务后生效)'),
            leading: const Icon(Icons.numbers_rounded),
            onTap: () => _showPortDialog(context, settings.proxyPort, (p) => notifier.setProxyPort(p)),
          ),
        ] else ...[
          ListTile(
            title: const Text('Native 代理探测端口'),
            subtitle: Text('当前设置: ${settings.proxyPort} (刷新网页后生效)'),
            leading: const Icon(Icons.radar_rounded),
            onTap: () => _showPortDialog(context, settings.proxyPort, (p) => notifier.setProxyPort(p)),
          ),
        ],
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '注：设置正确的端口可让网页版自动识别并使用手机端的登录状态，无需重复验证。',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  void _showPortDialog(BuildContext context, int currentPort, Function(int) onSave) {
    final controller = TextEditingController(text: currentPort.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置代理端口'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '端口号 (1024-65535)',
            hintText: '默认 9999',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              final port = int.tryParse(controller.text);
              if (port != null && port >= 1024 && port <= 65535) {
                onSave(port);
                Navigator.pop(context);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
