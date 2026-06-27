import 'dart:async';

import 'package:app_bar_m3e/app_bar_m3e.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:signals/signals_flutter.dart';

import 'package:feedback/feedback.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/platform_exit.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/login_credentials.dart';
import 'package:li_curriculum_table/features/timetable/domain/repositories/credentials_repository.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/timetable_page_sections.dart';
import 'package:li_curriculum_table/features/timetable/presentation/state/timetable_controller.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_helpers.dart';
import 'package:li_curriculum_table/core/services/cache_backup_service.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/course_color_service.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/presentation/terms_of_service.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/util/feedback_handler.dart';
import 'package:li_curriculum_table/features/settings/presentation/pages/tabs/settings_cupertino.dart';
import 'package:li_curriculum_table/features/settings/presentation/pages/tabs/sections/material_about_card.dart';
import 'package:li_curriculum_table/features/settings/presentation/pages/tabs/sections/material_web_download_card.dart';
import 'package:li_curriculum_table/features/settings/presentation/pages/tabs/settings_sections.dart';

class SettingsTab extends SignalStatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

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
        sl<CredentialsRepository>().cacheCredentials(
          LoginCredentials(username: u, password: p),
        );
      }
    });
  }

  Future<void> _restoreCachedCredentials() async {
    try {
      final cached = await sl<CredentialsRepository>().loadCredentials();
      if (!mounted || cached == null) return;
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
    super.build(context);
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
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Material
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMaterial(
    BuildContext context,
    dynamic state,
    AppSettings settings,
  ) {
    final cs = Theme.of(context).colorScheme;
    final ds = settings.designStyle;

    return Scaffold(
      appBar: const AppBarM3E(
        title: Text('设置'),
        centerTitle: true,
        shapeFamily: AppBarM3EShapeFamily.square,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
              children: [
                // ── Account ──
                SectionCard(
                  icon: AppIcons.vpnKey(ds),
                  title: '账号',
                  subtitle: '登录教务系统以同步课表数据',
                  child: _buildLoginPanel(context, state),
                ),
                const SizedBox(height: sectionSpacing),
                SectionCard(
                  icon: AppIcons.syncIcon(ds),
                  title: '同步状态',
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: TimetableStatusBanner(
                      status: state.status,
                      isLoading: state.isLoading,
                      hasData: state.data != null,
                    ),
                  ),
                ),

                // ── Appearance ──
                const SizedBox(height: 24),
                _buildSectionHeader(context, '外观', Icons.palette_rounded),
                const SizedBox(height: sectionSpacing),
                const ThemeSettingsSection(),

                // ── Behavior ──
                const SizedBox(height: 24),
                _buildSectionHeader(context, '交互', Icons.touch_app_rounded),
                const SizedBox(height: sectionSpacing),
                const TimetableDisplaySettingsSection(),

                // ── Advanced ──
                const SizedBox(height: 24),
                _buildSectionHeader(context, '高级', Icons.tune_rounded),
                const SizedBox(height: sectionSpacing),
                const ProxySettingsSection(),
                const SizedBox(height: sectionSpacing),
                SectionCard(
                  icon: AppIcons.storage(ds),
                  title: '存储',
                  child: Column(
                    children: [
                      SettingsTile(
                        icon: Icons.upload_rounded,
                        title: '导出缓存',
                        subtitle: '将本地数据导出为 JSON 文件分享',
                        onTap: () => _exportCache(context),
                      ),
                      const Divider(height: 1),
                      SettingsTile(
                        icon: Icons.download_rounded,
                        title: '导入缓存',
                        subtitle: '从 JSON 文件导入数据',
                        onTap: () => _importCache(context),
                      ),
                      const Divider(height: 1),
                      SettingsTile(
                        icon: AppIcons.deleteSweep(ds),
                        title: '清除所有缓存',
                        subtitle: '删除本地课表、教室、成绩等缓存，保留登录凭据',
                        onTap: () => _confirmClearCache(context),
                        iconColor: cs.error,
                      ),
                    ],
                  ),
                ),

                // ── About ──
                const SizedBox(height: 24),
                _buildSectionHeader(context, '关于', Icons.info_outline_rounded),
                const SizedBox(height: sectionSpacing),
                SectionCard(
                  icon: AppIcons.feedback(ds),
                  title: '反馈',
                  child: SettingsTile(
                    icon: AppIcons.markUnread(ds),
                    title: '发送反馈',
                    subtitle: '遇到问题或有建议？支持截图标注',
                    onTap: () => BetterFeedback.of(context).show(
                      (feedback) => FeedbackHandler.shareFeedback(feedback),
                    ),
                  ),
                ),
                const SizedBox(height: sectionSpacing),
                SectionCard(
                  icon: Icons.policy_outlined,
                  title: '条款与隐私',
                  child: SettingsTile(
                    icon: Icons.description_outlined,
                    title: '使用条款与隐私政策',
                    subtitle: '查看本应用的使用条款和隐私声明',
                    onTap: () async {
                      final agreed = await showTermsOfServiceDialog(
                        context,
                        designStyle: ds,
                        barrierDismissible: true,
                      );
                      if (!agreed && mounted) {
                        await sl<SettingsController>().setTermsAccepted(false);
                        // Allow secure storage to flush before exiting
                        await Future.delayed(const Duration(milliseconds: 200));
                        if (mounted) _exitApp();
                      }
                    },
                  ),
                ),
                if (kIsWeb) ...[
                  const SizedBox(height: sectionSpacing),
                  const MaterialWebDownloadCard(),
                ],
                const SizedBox(height: sectionSpacing),
                const MaterialAboutCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPanel(BuildContext context, dynamic state) {
    return TimetableControlPanel(
      usernameController: _usernameController,
      passwordController: _passwordController,
      onTermStartDateChanged: (date) =>
          sl<TimetableController>().setTermStartDate(date),
      onCurrentTermChanged: (term) =>
          sl<SettingsController>().setCurrentTerm(term),
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
        await sl<TimetableController>().fetchAndBuild(username: u, password: p);
      },
    );
  }

  void _exitApp() => exitApp();

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
    if (confirmed && mounted) await sl<TimetableController>().clearAllCache();
  }

  Future<void> _exportCache(BuildContext context) async {
    final ds = sl<SettingsController>().designStyle.value;
    try {
      await sl<CacheBackupService>().exportAndShare();
    } catch (_) {
      if (context.mounted) {
        showAdaptiveMessage(context, designStyle: ds, message: '导出失败');
      }
    }
  }

  Future<void> _importCache(BuildContext context) async {
    final ds = sl<SettingsController>().designStyle.value;
    try {
      final count = await sl<CacheBackupService>().importFromFile();
      if (count == null) return; // user cancelled
      if (!context.mounted) return;
      showAdaptiveMessage(context, designStyle: ds, message: '已导入 $count 条数据');
      // Reload all cached data to reflect imported state
      await sl<SettingsController>().init();
      await sl<TimetableController>().restoreCachedTimetable();
      await sl<TimetableController>().restoreCachedTeachingWeekBaseline();
      await sl<CourseColorService>().reload();
    } on FormatException catch (e) {
      if (context.mounted) {
        showAdaptiveMessage(context, designStyle: ds, message: e.message);
      }
    } catch (_) {
      if (context.mounted) {
        showAdaptiveMessage(context, designStyle: ds, message: '导入失败');
      }
    }
  }
}

// Extracted components moved to sections/material_about_card.dart
// and sections/material_web_download_card.dart
