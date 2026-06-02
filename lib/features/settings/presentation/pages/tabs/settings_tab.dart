import 'dart:async';

import 'package:flutter/cupertino.dart';
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
import 'package:li_curriculum_table/core/presentation/adaptive_helpers.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
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
  bool _listenersAttached = false;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onCredentialsChanged);
    _passwordController.addListener(_onCredentialsChanged);
    _listenersAttached = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(timetableControllerProvider.notifier);
      await notifier.restoreCachedTimetable();
      await notifier.restoreCachedTeachingWeekBaseline();
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
    final state = ref.watch(timetableControllerProvider);
    final settings = ref.watch(settingsControllerProvider);

    if (AdaptiveStyle.isCupertino(settings.designStyle)) {
      return _buildCupertino(context, state, settings);
    }
    return _buildMaterial(context, state, settings);
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
                _SectionCard(
                  icon: AppIcons.vpnKey(ds),
                  title: '教务系统登录',
                  subtitle: '登录以同步课表数据',
                  child: _buildLoginPanel(context, state),
                ),
                const SizedBox(height: _sectionSpacing),
                _SectionCard(
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
                const SizedBox(height: _sectionSpacing),
                const _ThemeSettingsSection(),
                const SizedBox(height: _sectionSpacing),
                const _DesignStyleSection(),
                const SizedBox(height: _sectionSpacing),
                const _TimetableDisplaySettingsSection(),
                const SizedBox(height: _sectionSpacing),
                const _ProxySettingsSection(),
                const SizedBox(height: _sectionSpacing),
                _SectionCard(
                  icon: AppIcons.storage(ds),
                  title: '存储与缓存',
                  child: _SettingsTile(
                    icon: AppIcons.deleteSweep(ds),
                    title: '清除所有缓存',
                    subtitle: '删除本地课表、教室、成绩等缓存，保留登录凭据',
                    onTap: () => _confirmClearCache(context),
                    iconColor: colorScheme.error,
                  ),
                ),
                const SizedBox(height: _sectionSpacing),
                _SectionCard(
                  icon: AppIcons.feedback(ds),
                  title: '反馈与建议',
                  child: _SettingsTile(
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
                const SizedBox(height: _sectionSpacing),
                _buildAboutCard(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Cupertino implementation — native iOS Settings style
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCupertino(BuildContext context, dynamic state, AppSettings settings) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('设置'),
            backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
            border: null,
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                BetterFeedback.of(context).show(
                  (feedback) => FeedbackHandler.shareFeedback(feedback),
                );
              },
              child: const Icon(CupertinoIcons.mail, size: 22),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildCupertinoBody(context, state, settings),
          ),
        ],
      ),
    );
  }

  Widget _buildCupertinoBody(BuildContext context, dynamic state, AppSettings settings) {
    final notifier = ref.read(settingsControllerProvider.notifier);
    return SafeArea(
      top: false,
      child: Column(
        children: [
          // ── 教务系统登录 ──
          CupertinoListSection.insetGrouped(
            header: const Text('教务系统登录'),
            children: [
              CupertinoListTile(
                leading: const Icon(CupertinoIcons.person, size: 29),
                title: CupertinoTextField(
                  controller: _usernameController,
                  placeholder: '学号',
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(CupertinoIcons.person, size: 20),
                  ),
                  decoration: const BoxDecoration(),
                  clearButtonMode: OverlayVisibilityMode.editing,
                ),
              ),
              CupertinoListTile(
                leading: const Icon(CupertinoIcons.lock, size: 29),
                title: CupertinoTextField(
                  controller: _passwordController,
                  placeholder: '密码',
                  obscureText: true,
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(CupertinoIcons.lock, size: 20),
                  ),
                  decoration: const BoxDecoration(),
                  clearButtonMode: OverlayVisibilityMode.editing,
                ),
              ),
              CupertinoListTile(
                leading: Icon(
                  state.isLoading
                      ? CupertinoIcons.arrow_clockwise
                      : CupertinoIcons.cloud_download,
                  size: 29,
                  color: CupertinoColors.systemBlue,
                ),
                title: const Text('同步课表'),
                trailing: state.isLoading
                    ? const CupertinoActivityIndicator()
                    : const CupertinoListTileChevron(),
                onTap: state.isLoading
                    ? null
                    : () async {
                        final u = _usernameController.text.trim();
                        final p = _passwordController.text;
                        if (u.isEmpty || p.isEmpty) {
                          showCupertinoDialog(
                            context: context,
                            builder: (ctx) => CupertinoAlertDialog(
                              title: const Text('提示'),
                              content: const Text('请输入学号和密码'),
                              actions: [
                                CupertinoDialogAction(
                                  isDefaultAction: true,
                                  child: const Text('好的'),
                                  onPressed: () => Navigator.pop(ctx),
                                ),
                              ],
                            ),
                          );
                          return;
                        }
                        FocusScope.of(context).unfocus();
                        await ref
                            .read(timetableControllerProvider.notifier)
                            .fetchAndBuild(username: u, password: p);
                      },
              ),
            ],
          ),

          // ── 数据同步状态 ──
          CupertinoListSection.insetGrouped(
            header: const Text('同步状态'),
            children: [
              CupertinoListTile(
                leading: Icon(
                  state.isLoading
                      ? CupertinoIcons.arrow_clockwise
                      : (state.data != null
                          ? CupertinoIcons.check_mark_circled
                          : CupertinoIcons.xmark_circle),
                  size: 29,
                  color: state.isLoading
                      ? CupertinoColors.systemOrange
                      : (state.data != null
                          ? CupertinoColors.systemGreen
                          : CupertinoColors.systemRed),
                ),
                title: Text(_statusText(state)),
                additionalInfo: state.data != null
                    ? Text('第 ${state.displayWeek} 周')
                    : null,
              ),
            ],
          ),

          // ── 外观 ──
          _buildCupertinoThemeSection(context, settings, notifier),

          // ── 设计风格 ──
          _buildCupertinoDesignStyleSection(context, settings, notifier),

          // ── 课表显示 ──
          CupertinoListSection.insetGrouped(
            header: const Text('课表显示'),
            children: [
              CupertinoListTile(
                leading: const Icon(CupertinoIcons.rectangle_grid_1x2, size: 29),
                title: const Text('按星期滑动'),
                subtitle: const Text('以整周为单位左右对齐滑动'),
                trailing: CupertinoSwitch(
                  value: settings.weeklyScroll,
                  onChanged: (val) => notifier.setWeeklyScroll(val),
                ),
              ),
            ],
          ),

          // ── 本地代理 ──
          if (!isWeb)
            CupertinoListSection.insetGrouped(
              header: const Text('本地代理'),
              footer: const Text('允许其他设备通过此应用中转教务系统请求。设置正确的端口可让网页版自动识别并使用手机端的登录状态。'),
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.wifi, size: 29),
                  title: const Text('开启本地代理网关'),
                  trailing: CupertinoSwitch(
                    value: settings.proxyEnabled,
                    onChanged: (val) => notifier.setProxyEnabled(val),
                  ),
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.number, size: 29),
                  title: const Text('服务端监听端口'),
                  additionalInfo: Text('${settings.proxyPort}'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => _showCupertinoPortDialog(context, settings.proxyPort, (p) => notifier.setProxyPort(p)),
                ),
              ],
            ),

          // ── 存储与缓存 ──
          CupertinoListSection.insetGrouped(
            header: const Text('存储与缓存'),
            children: [
              CupertinoListTile(
                leading: const Icon(
                  CupertinoIcons.delete,
                  size: 29,
                  color: CupertinoColors.systemRed,
                ),
                title: const Text(
                  '清除所有缓存',
                  style: TextStyle(color: CupertinoColors.systemRed),
                ),
                onTap: () => _confirmClearCacheCupertino(context),
              ),
            ],
          ),

          // ── 反馈 ──
          CupertinoListSection.insetGrouped(
            header: const Text('反馈与建议'),
            children: [
              CupertinoListTile(
                leading: const Icon(CupertinoIcons.mail, size: 29),
                title: const Text('发送反馈'),
                subtitle: const Text('遇到问题或有建议？'),
                trailing: const CupertinoListTileChevron(),
                onTap: () {
                  BetterFeedback.of(context).show(
                    (feedback) => FeedbackHandler.shareFeedback(feedback),
                  );
                },
              ),
            ],
          ),

          // ── 关于 ──
          _buildCupertinoAboutSection(context),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCupertinoThemeSection(
    BuildContext context,
    AppSettings settings,
    dynamic notifier,
  ) {
    return CupertinoListSection.insetGrouped(
      header: const Text('外观'),
      children: [
        CupertinoListTile(
          leading: const Icon(CupertinoIcons.paintbrush, size: 29),
          title: const Text('主题模式'),
          additionalInfo: Text(_themeModeLabel(settings.themeMode)),
          trailing: const CupertinoListTileChevron(),
          onTap: () => _showCupertinoThemeModePicker(context, settings.themeMode, notifier),
        ),
        CupertinoListTile(
          leading: const Icon(CupertinoIcons.color_filter, size: 29),
          title: const Text('动态取色'),
          subtitle: const Text('从壁纸或系统提取主题色'),
          trailing: CupertinoSwitch(
            value: settings.useDynamicColor,
            onChanged: (val) => notifier.setUseDynamicColor(val),
          ),
        ),
        if (!settings.useDynamicColor)
          CupertinoListTile(
            leading: const Icon(CupertinoIcons.circle_fill, size: 29),
            title: const Text('主题色'),
            additionalInfo: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: settings.seedColor,
                shape: BoxShape.circle,
                border: Border.all(color: CupertinoColors.separator, width: 0.5),
              ),
            ),
            trailing: const CupertinoListTileChevron(),
            onTap: () => _showCupertinoColorPicker(context, settings.seedColor, notifier),
          ),
      ],
    );
  }

  Widget _buildCupertinoDesignStyleSection(
    BuildContext context,
    AppSettings settings,
    dynamic notifier,
  ) {
    return CupertinoListSection.insetGrouped(
      header: const Text('设计风格'),
      footer: const Text('切换界面设计风格。Material 为 Android 风格，Cupertino 为 iOS 风格。'),
      children: DesignStyle.values.map((style) {
        final isSelected = settings.designStyle == style;
        return CupertinoListTile(
          leading: Icon(
            style == DesignStyle.material
                ? CupertinoIcons.device_phone_portrait
                : (style == DesignStyle.cupertino
                    ? CupertinoIcons.device_phone_portrait
                    : CupertinoIcons.device_phone_portrait),
            size: 29,
          ),
          title: Text(style.label),
          trailing: isSelected
              ? const Icon(CupertinoIcons.check_mark, color: CupertinoColors.systemBlue, size: 20)
              : null,
          onTap: () => notifier.setDesignStyle(style),
        );
      }).toList(),
    );
  }

  Widget _buildCupertinoAboutSection(BuildContext context) {
    return CupertinoListSection.insetGrouped(
      header: const Text('关于'),
      children: [
        CupertinoListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset('assets/icon/icon.png', width: 29, height: 29),
          ),
          title: const Text('🍐 课表'),
          subtitle: const Text('一款轻盈优雅的跨平台课表应用'),
          additionalInfo: FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.data?.version ?? '...';
              return Text('v$version');
            },
          ),
        ),
        CupertinoListTile(
          leading: const Icon(CupertinoIcons.arrow_down_circle, size: 29),
          title: const Text('检查更新'),
          trailing: const CupertinoListTileChevron(),
          onTap: () => _checkForUpdateManually(context),
        ),
      ],
    );
  }

  void _showCupertinoThemeModePicker(
    BuildContext context,
    ThemeMode current,
    dynamic notifier,
  ) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('主题模式'),
        actions: [
          CupertinoActionSheetAction(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (current == ThemeMode.system) const Icon(CupertinoIcons.check_mark, size: 18),
                const SizedBox(width: 8),
                const Text('跟随系统'),
              ],
            ),
            onPressed: () {
              notifier.setThemeMode(ThemeMode.system);
              Navigator.pop(context);
            },
          ),
          CupertinoActionSheetAction(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (current == ThemeMode.light) const Icon(CupertinoIcons.check_mark, size: 18),
                const SizedBox(width: 8),
                const Text('浅色'),
              ],
            ),
            onPressed: () {
              notifier.setThemeMode(ThemeMode.light);
              Navigator.pop(context);
            },
          ),
          CupertinoActionSheetAction(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (current == ThemeMode.dark) const Icon(CupertinoIcons.check_mark, size: 18),
                const SizedBox(width: 8),
                const Text('深色'),
              ],
            ),
            onPressed: () {
              notifier.setThemeMode(ThemeMode.dark);
              Navigator.pop(context);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          child: const Text('取消'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _showCupertinoColorPicker(
    BuildContext context,
    Color current,
    dynamic notifier,
  ) {
    const colors = _ThemeSettingsSection._seedColors;
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('选择主题色'),
        actions: colors.map((color) {
          return CupertinoActionSheetAction(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: current.toARGB32() == color.toARGB32()
                          ? CupertinoColors.systemBlue
                          : CupertinoColors.separator,
                      width: current.toARGB32() == color.toARGB32() ? 3 : 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (current.toARGB32() == color.toARGB32())
                  const Icon(CupertinoIcons.check_mark, size: 18),
              ],
            ),
            onPressed: () {
              notifier.setSeedColor(color);
              Navigator.pop(context);
            },
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          child: const Text('取消'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _showCupertinoPortDialog(BuildContext context, int currentPort, Function(int) onSave) {
    final controller = TextEditingController(text: currentPort.toString());
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('设置代理端口'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            keyboardType: TextInputType.number,
            placeholder: '端口号 (1024-65535)',
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('保存'),
            onPressed: () {
              final port = int.tryParse(controller.text);
              if (port != null && port >= 1024 && port <= 65535) {
                onSave(port);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearCacheCupertino(BuildContext context) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('确认清除缓存？'),
        content: const Text('将删除所有离线课表和缓存数据。您仍将保持登录状态，但需要重新同步以加载数据。'),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('清除'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(timetableControllerProvider.notifier).clearAllCache();
    }
  }

  String _statusText(dynamic state) {
    if (state.isLoading) return '正在同步...';
    if (state.data != null) return '已同步';
    return '未同步';
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return '跟随系统';
      case ThemeMode.light:
        return '浅色';
      case ThemeMode.dark:
        return '深色';
    }
  }

  Widget _buildLoginPanel(BuildContext context, dynamic state) {
    return TimetableControlPanel(
      usernameController: _usernameController,
      passwordController: _passwordController,
      isLoading: state.isLoading,
      currentTeachingWeek: state.currentTeachingWeek,
      termStartMonday: state.termStartMonday,
      onTermStartDateChanged: (date) {
        ref.read(timetableControllerProvider.notifier).setTermStartDate(date);
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
                  icon: Icon(
                    AdaptiveStyle.isCupertino(
                      ProviderScope.containerOf(context).read(settingsControllerProvider).designStyle,
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
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _checkForUpdateManually(BuildContext context) async {
    final ds = ref.read(settingsControllerProvider).designStyle;
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
    final ds = settings.designStyle;

    return _SectionCard(
      icon: AppIcons.palette(ds),
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
            icon: AppIcons.colorLens(ds),
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

// ─── Design Style Settings ───────────────────────────────────────────────────

class _DesignStyleSection extends ConsumerWidget {
  const _DesignStyleSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final notifier = ref.read(settingsControllerProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ds = settings.designStyle;

    return _SectionCard(
      icon: Icons.phone_android,
      title: '设计风格',
      subtitle: '切换 Material 或 Cupertino 界面风格',
      child: Column(
        children: [
          ...DesignStyle.values.map((style) {
            final isSelected = settings.designStyle == style;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => notifier.setDesignStyle(style),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outlineVariant.withValues(alpha: 0.5),
                        width: isSelected ? 2 : 1,
                      ),
                      color: isSelected
                          ? colorScheme.primaryContainer.withValues(alpha: 0.15)
                          : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          style.icon,
                          size: 22,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                style.label,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                _styleDescription(style),
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            AppIcons.checkCircle(ds),
                            size: 20,
                            color: colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _styleDescription(DesignStyle style) {
    switch (style) {
      case DesignStyle.material:
        return 'Google Material Design 3 风格';
      case DesignStyle.cupertino:
        return 'Apple iOS/macOS 风格';
      case DesignStyle.system:
        return 'Android 用 Material，iOS 用 Cupertino';
    }
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
    final ds = settings.designStyle;

    return _SectionCard(
      icon: AppIcons.lan(ds),
      title: '本地代理',
      subtitle: '允许其他设备通过此应用中转教务系统请求',
      child: Column(
        children: [
          if (!isWeb) ...[
            _SettingsTile(
              icon: AppIcons.router(ds),
              title: '开启本地代理网关',
              subtitle: '其他设备或本机网页版可通过此应用共享会话',
              trailing: Switch(
                value: settings.proxyEnabled,
                onChanged: (val) => notifier.setProxyEnabled(val),
              ),
            ),
            _SettingsTile(
              icon: AppIcons.numbers(ds),
              title: '服务端监听端口',
              subtitle: '${settings.proxyPort}（重启服务后生效）',
              onTap: () =>
                  _showPortDialog(context, settings.proxyPort, (p) => notifier.setProxyPort(p)),
            ),
          ] else ...[
            _SettingsTile(
              icon: AppIcons.radar(ds),
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
                Icon(AppIcons.info(ds), size: 14, color: colorScheme.onSurfaceVariant),
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
    final ds = settings.designStyle;

    return _SectionCard(
      icon: AppIcons.viewWeek(ds),
      title: '课表显示',
      child: _SettingsTile(
        icon: AppIcons.swapHoriz(ds),
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
          ?trailing,
          if (trailing == null && onTap != null)
            Icon(
              AdaptiveStyle.isCupertino(
                ProviderScope.containerOf(context).read(settingsControllerProvider).designStyle,
              )
                  ? CupertinoIcons.chevron_right
                  : Icons.chevron_right_rounded,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
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
