import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:feedback/feedback.dart';
import 'package:li_curriculum_table/core/presentation/update_dialog.dart';
import 'package:li_curriculum_table/core/services/update_service.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/login_credentials.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/timetable_page_sections.dart';
import 'package:li_curriculum_table/features/timetable/presentation/providers/timetable_providers.dart';
import 'package:li_curriculum_table/features/timetable/presentation/state/timetable_controller.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/app/app.dart';
import 'package:li_curriculum_table/util/feedback_handler.dart';

// ─── Constants ───────────────────────────────────────────────────────────────

const _sectionSpacing = 20.0;
const _cardPadding = EdgeInsets.all(16);

// ─── SettingsTab ─────────────────────────────────────────────────────────────

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
        ref
            .read(credentialsRepositoryProvider)
            .cacheCredentials(LoginCredentials(username: u, password: p));
      }
    });
  }

  Future<void> _restoreCachedCredentials() async {
    try {
      final repository = ref.read(credentialsRepositoryProvider);
      final cached = await repository.loadCredentials();
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
    final colorScheme = Theme.of(context).colorScheme;

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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                // ── 教务系统登录 ──
                _SectionCard(
                  icon: Icons.vpn_key_outlined,
                  title: '教务系统登录',
                  subtitle: '登录以同步课表数据',
                  child: TimetableControlPanel(
                    usernameController: _usernameController,
                    passwordController: _passwordController,
                    isLoading: state.isLoading,
                    currentTeachingWeek: state.currentTeachingWeek,
                    termStartMonday: state.termStartMonday,
                    onTermStartDateChanged: (date) {
                      ref
                          .read(timetableControllerProvider.notifier)
                          .setTermStartDate(date);
                    },
                    onLoginPressed: () async {
                      final u = _usernameController.text.trim();
                      final p = _passwordController.text;
                      if (u.isEmpty || p.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('请输入学号和密码')),
                        );
                        return;
                      }
                      FocusScope.of(context).unfocus();
                      await ref
                          .read(timetableControllerProvider.notifier)
                          .fetchAndBuild(username: u, password: p);
                    },
                  ),
                ),
                const SizedBox(height: _sectionSpacing),

                // ── 数据同步状态 ──
                _SectionCard(
                  icon: Icons.sync_rounded,
                  title: '数据同步状态',
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: TimetableStatusBanner(
                      status: state.status,
                      isLoading: state.isLoading,
                      hasData: state.data != null,
                    ),
                  ),
                ),
                const SizedBox(height: _sectionSpacing),

                // ── 外观 ──
                const _ThemeSettingsSection(),
                const SizedBox(height: _sectionSpacing),

                // ── 课表显示 ──
                const _TimetableDisplaySettingsSection(),
                const SizedBox(height: _sectionSpacing),

                // ── 本地代理 ──
                const _ProxySettingsSection(),
                const SizedBox(height: _sectionSpacing),

                // ── 存储与缓存 ──
                _SectionCard(
                  icon: Icons.storage_outlined,
                  title: '存储与缓存',
                  child: _SettingsTile(
                    icon: Icons.delete_sweep_outlined,
                    title: '清除所有缓存',
                    subtitle: '删除本地课表、教室、成绩等缓存，保留登录凭据',
                    onTap: () => _confirmClearCache(context),
                    iconColor: colorScheme.error,
                  ),
                ),
                const SizedBox(height: _sectionSpacing),

                // ── 反馈 ──
                _SectionCard(
                  icon: Icons.feedback_outlined,
                  title: '反馈与建议',
                  child: _SettingsTile(
                    icon: Icons.mark_as_unread_outlined,
                    title: '发送反馈',
                    subtitle: '遇到问题或有建议？点击这里告诉我们（支持截图标注）',
                    onTap: () {
                      BetterFeedback.of(context).show(
                        (feedback) => FeedbackHandler.shareFeedback(feedback),
                      );
                    },
                  ),
                ),
                const SizedBox(height: _sectionSpacing),

                // ── 关于 ──
                _buildAboutCard(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClearCache(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除缓存？'),
        content: const Text('将删除所有离线课表和缓存数据。您仍将保持登录状态，但需要重新同步以加载数据。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
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

  Widget _buildAboutCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: _cardPadding,
        child: FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            final version = snapshot.data?.version ?? '...';
            final buildNumber = snapshot.data?.buildNumber ?? '';

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset('assets/icon/icon.png'),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '🍐 课表',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'v$version${buildNumber.isNotEmpty ? ' ($buildNumber)' : ''}',
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.system_update_rounded, size: 18),
                  label: const Text('检查更新'),
                  onPressed: () => _checkForUpdateManually(context),
                ),
                const SizedBox(height: 12),
                Text(
                  '一款轻盈优雅的跨平台课表应用',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _checkForUpdateManually(BuildContext context) async {
    final overlay = Overlay.of(context);

    late OverlayEntry loadingEntry;
    loadingEntry = OverlayEntry(
      builder: (_) => Center(
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('正在检查更新...'),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(loadingEntry);

    try {
      final updateInfo = await UpdateService().checkForUpdate();
      loadingEntry.remove();
      if (context.mounted) {
        await showUpdateDialogIfNeeded(context, updateInfo, silent: false);
      }
    } catch (e) {
      loadingEntry.remove();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('检查更新失败，请稍后重试')),
        );
      }
    }
  }
}

// ─── Theme Settings ──────────────────────────────────────────────────────────

class _ThemeSettingsSection extends ConsumerWidget {
  const _ThemeSettingsSection();

  static const _seedColors = [
    Color(0xFF0A7C6D), // Teal (default)
    Color(0xFF6750A4), // Purple
    Color(0xFF0061A4), // Blue
    Color(0xFF006E1C), // Green
    Color(0xFF904D00), // Orange
    Color(0xFFBA1A1A), // Red
    Color(0xFF5C6200), // Olive
    Color(0xFF006493), // Cyan
    Color(0xFF8B5000), // Amber
    Color(0xFF5E5B8E), // Indigo Grey
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final notifier = ref.read(settingsControllerProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return _SectionCard(
      icon: Icons.palette_outlined,
      title: '外观',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Theme mode
          Center(
            child: Text('主题模式',
                style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 10),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto_rounded),
                    label: Text('跟随系统'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_rounded),
                    label: Text('浅色'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_rounded),
                    label: Text('深色'),
                  ),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (modes) => notifier.setThemeMode(modes.first),
                showSelectedIcon: false,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Dynamic color toggle
          _SettingsTile(
            icon: Icons.color_lens_outlined,
            title: '动态取色',
            subtitle: '从壁纸或系统提取主题色（仅部分设备支持）',
            trailing: Switch(
              value: settings.useDynamicColor,
              onChanged: (val) => notifier.setUseDynamicColor(val),
            ),
          ),

          // Seed color picker
          if (!settings.useDynamicColor) ...[
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text('主题色', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _seedColors.map((color) {
                final isSelected = settings.seedColor.toARGB32() == color.toARGB32();
                return GestureDetector(
                  onTap: () => notifier.setSeedColor(color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: colorScheme.onSurface, width: 2.5)
                          : Border.all(
                              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                              width: 1,
                            ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.35),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? Icon(Icons.check_rounded,
                            color: color.computeLuminance() > 0.5
                                ? Colors.black87
                                : Colors.white,
                            size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Proxy Settings ──────────────────────────────────────────────────────────

class _ProxySettingsSection extends ConsumerWidget {
  const _ProxySettingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final notifier = ref.read(settingsControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return _SectionCard(
      icon: Icons.lan_outlined,
      title: '本地代理',
      subtitle: '允许其他设备通过此应用中转教务系统请求',
      child: Column(
        children: [
          if (!isWeb) ...[
            _SettingsTile(
              icon: Icons.router_outlined,
              title: '开启本地代理网关',
              subtitle: '其他设备或本机网页版可通过此应用共享会话',
              trailing: Switch(
                value: settings.proxyEnabled,
                onChanged: (val) => notifier.setProxyEnabled(val),
              ),
            ),
            _SettingsTile(
              icon: Icons.numbers_outlined,
              title: '服务端监听端口',
              subtitle: '${settings.proxyPort}（重启服务后生效）',
              onTap: () =>
                  _showPortDialog(context, settings.proxyPort, (p) => notifier.setProxyPort(p)),
            ),
          ] else ...[
            _SettingsTile(
              icon: Icons.radar_outlined,
              title: 'Native 代理探测端口',
              subtitle: '${settings.proxyPort}（刷新网页后生效）',
              onTap: () =>
                  _showPortDialog(context, settings.proxyPort, (p) => notifier.setProxyPort(p)),
            ),
          ],
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 14, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '设置正确的端口可让网页版自动识别并使用手机端的登录状态，无需重复验证。',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
          FilledButton(
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

// ─── Timetable Display Settings ──────────────────────────────────────────────

class _TimetableDisplaySettingsSection extends ConsumerWidget {
  const _TimetableDisplaySettingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final notifier = ref.read(settingsControllerProvider.notifier);

    return _SectionCard(
      icon: Icons.view_week_outlined,
      title: '课表显示',
      child: _SettingsTile(
        icon: Icons.swap_horiz_rounded,
        title: '按星期滑动',
        subtitle: '开启后，课表以整周为单位左右对齐滑动；关闭则自由无极滑动',
        trailing: Switch(
          value: settings.weeklyScroll,
          onChanged: (val) => notifier.setWeeklyScroll(val),
        ),
      ),
    );
  }
}

// ─── Shared UI Components ────────────────────────────────────────────────────

/// A card that wraps a settings section with a header.
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: _cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: colorScheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// A consistent settings list tile with icon, title, subtitle, and optional switch or chevron.
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle = '',
    this.trailing,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final effectiveIconColor = iconColor ?? colorScheme.onSurfaceVariant;

    final tile = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 20, color: effectiveIconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.bodyMedium),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
          if (trailing == null && onTap != null)
            Icon(Icons.chevron_right_rounded, size: 20, color: colorScheme.onSurfaceVariant),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: tile,
      );
    }
    return tile;
  }
}
