import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:signals/signals_flutter.dart';

import 'package:feedback/feedback.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/update_dialog.dart';
import 'package:li_curriculum_table/core/services/update_service.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/login_credentials.dart';
import 'package:li_curriculum_table/features/timetable/domain/repositories/credentials_repository.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/timetable_page_sections.dart';
import 'package:li_curriculum_table/features/timetable/presentation/state/timetable_controller.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_helpers.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/util/feedback_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:li_curriculum_table/features/settings/presentation/pages/tabs/settings_cupertino.dart';
import 'package:li_curriculum_table/features/settings/presentation/pages/tabs/settings_sections.dart';

// ─── SettingsTab ─────────────────────────────────────────────────────────────

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  Timer? _saveDebounce;
  bool _listenersAttached = false;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onCredentialsChanged);
    _passwordController.addListener(_onCredentialsChanged);
    _listenersAttached = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = sl<TimetableController>();
      await controller.restoreCachedTimetable();
      await controller.restoreCachedTeachingWeekBaseline();
      await _restoreCachedCredentials();
    });
  }

  void _onCredentialsChanged() {
    if (!_listenersAttached) return;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 800), () {
      final u = _usernameController.text.trim();
      final p = _passwordController.text;
      if (u.isNotEmpty && p.isNotEmpty) {
        sl<CredentialsRepository>()
            .cacheCredentials(LoginCredentials(username: u, password: p));
      }
    });
  }

  Future<void> _restoreCachedCredentials() async {
    try {
      final repository = sl<CredentialsRepository>();
      final cached = await repository.loadCredentials();
      if (!mounted || cached == null) return;
      // Temporarily detach listeners to avoid saving restored values
      _usernameController.removeListener(_onCredentialsChanged);
      _passwordController.removeListener(_onCredentialsChanged);
      _listenersAttached = false;

      _usernameController.text = cached.username;
      _passwordController.text = cached.password;

      _usernameController.addListener(_onCredentialsChanged);
      _passwordController.addListener(_onCredentialsChanged);
      _listenersAttached = true;
    } catch (_) {}
  }

  @override
  void dispose() {
    _listenersAttached = false;
    _saveDebounce?.cancel();
    _usernameController.removeListener(_onCredentialsChanged);
    _passwordController.removeListener(_onCredentialsChanged);
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(builder: (context) {
      final state = sl<TimetableController>().state.value;
      final settings = sl<SettingsController>().state.value;

      if (AdaptiveStyle.isCupertino(settings.designStyle)) {
        return buildSettingsCupertino(
          context: context,
          state: state,
          settings: settings,
          usernameController: _usernameController,
          passwordController: _passwordController,
          mounted: mounted,
          onClearCache: () => sl<TimetableController>().clearAllCache(),
        );
      }
      return _buildMaterial(context, state, settings);
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Material implementation
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMaterial(BuildContext context, dynamic state, AppSettings settings) {
    final colorScheme = Theme.of(context).colorScheme;
    final ds = settings.designStyle;

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
                SectionCard(
                  icon: AppIcons.vpnKey(ds),
                  title: '教务系统登录',
                  subtitle: '登录以同步课表数据',
                  child: _buildLoginPanel(context, state),
                ),
                const SizedBox(height: sectionSpacing),
                SectionCard(
                  icon: AppIcons.syncIcon(ds),
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
                const SizedBox(height: sectionSpacing),
                const ThemeSettingsSection(),
                const SizedBox(height: sectionSpacing),
                const DesignStyleSection(),
                const SizedBox(height: sectionSpacing),
                const TimetableDisplaySettingsSection(),
                const SizedBox(height: sectionSpacing),
                const ProxySettingsSection(),
                const SizedBox(height: sectionSpacing),
                SectionCard(
                  icon: AppIcons.storage(ds),
                  title: '存储与缓存',
                  child: SettingsTile(
                    icon: AppIcons.deleteSweep(ds),
                    title: '清除所有缓存',
                    subtitle: '删除本地课表、教室、成绩等缓存，保留登录凭据',
                    onTap: () => _confirmClearCache(context),
                    iconColor: colorScheme.error,
                  ),
                ),
                const SizedBox(height: sectionSpacing),
                SectionCard(
                  icon: AppIcons.feedback(ds),
                  title: '反馈与建议',
                  child: SettingsTile(
                    icon: AppIcons.markUnread(ds),
                    title: '发送反馈',
                    subtitle: '遇到问题或有建议？点击这里告诉我们（支持截图标注）',
                    onTap: () {
                      BetterFeedback.of(context).show(
                        (feedback) => FeedbackHandler.shareFeedback(feedback),
                      );
                    },
                  ),
                ),
                const SizedBox(height: sectionSpacing),
                _buildAboutCard(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginPanel(BuildContext context, dynamic state) {
    return TimetableControlPanel(
      usernameController: _usernameController,
      passwordController: _passwordController,
      isLoading: state.isLoading,
      currentTeachingWeek: state.currentTeachingWeek,
      termStartMonday: state.termStartMonday,
      onTermStartDateChanged: (date) {
        sl<TimetableController>().setTermStartDate(date);
      },
      onLoginPressed: () async {
        final u = _usernameController.text.trim();
        final p = _passwordController.text;
        if (u.isEmpty || p.isEmpty) {
          showAdaptiveMessage(
            context,
            designStyle: sl<SettingsController>().designStyle.value,
            message: '请输入学号和密码',
          );
          return;
        }
        FocusScope.of(context).unfocus();
        await sl<TimetableController>()
            .fetchAndBuild(username: u, password: p);
      },
    );
  }

  Future<void> _confirmClearCache(BuildContext context) async {
    final confirmed = await showAdaptiveConfirmDialog(
      context,
      designStyle: sl<SettingsController>().designStyle.value,
      title: '确认清除缓存？',
      content: '将删除所有离线课表和缓存数据。您仍将保持登录状态，但需要重新同步以加载数据。',
      confirmText: '清除',
      cancelText: '取消',
      isDestructive: true,
    );

    if (confirmed && mounted) {
      await sl<TimetableController>().clearAllCache();
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
        padding: cardPadding,
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
                  icon: Icon(
                    AdaptiveStyle.isCupertino(
                      sl<SettingsController>().state.value.designStyle,
                    )
                        ? CupertinoIcons.arrow_down_circle
                        : Icons.system_update_rounded,
                    size: 18,
                  ),
                  label: const Text('检查更新'),
                  onPressed: () => _checkForUpdateManually(context),
                ),
                const SizedBox(height: 12),
                Text(
                  '一款轻盈优雅的跨平台课表应用',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.code_rounded, size: 18),
                  label: const Text('GitHub'),
                  onPressed: () => launchUrl(
                    Uri.parse('https://github.com/fans963/--table'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _checkForUpdateManually(BuildContext context) async {
    final ds = sl<SettingsController>().state.value.designStyle;
    final isCupertino = AdaptiveStyle.isCupertino(ds);

    // Show loading dialog — adaptive style
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
                  CircularProgressIndicator(),
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
      final updateInfo = await UpdateService().checkForUpdate();
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      if (context.mounted) {
        await showUpdateDialogIfNeeded(context, updateInfo, silent: false);
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      if (!context.mounted) return;
      showAdaptiveMessage(
        context,
        designStyle: ds,
        message: '检查更新失败，请稍后重试',
      );
    }
  }
}


