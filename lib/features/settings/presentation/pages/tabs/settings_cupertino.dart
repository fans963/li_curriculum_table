import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:feedback/feedback.dart';

import 'package:li_curriculum_table/app/app.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_helpers.dart';
import 'package:li_curriculum_table/core/presentation/update_dialog.dart';
import 'package:li_curriculum_table/core/services/update_service.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/settings/presentation/pages/tabs/settings_sections.dart';
import 'package:li_curriculum_table/features/timetable/presentation/state/timetable_controller.dart';
import 'package:li_curriculum_table/util/feedback_handler.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Cupertino Settings — extracted top-level functions
// ═══════════════════════════════════════════════════════════════════════════════

/// Main entry point for the Cupertino (iOS-style) settings page.
Widget buildSettingsCupertino({
  required BuildContext context,
  required dynamic state,
  required AppSettings settings,
  required TextEditingController usernameController,
  required TextEditingController passwordController,
  required bool mounted,
  required Future<void> Function() onClearCache,
}) {
  return _buildCupertinoPage(
    context: context,
    state: state,
    settings: settings,
    usernameController: usernameController,
    passwordController: passwordController,
    mounted: mounted,
    onClearCache: onClearCache,
  );
}

// ─── Page scaffold ────────────────────────────────────────────────────────────

Widget _buildCupertinoPage({
  required BuildContext context,
  required dynamic state,
  required AppSettings settings,
  required TextEditingController usernameController,
  required TextEditingController passwordController,
  required bool mounted,
  required Future<void> Function() onClearCache,
}) {
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
          child: buildCupertinoBody(
            context: context,
            state: state,
            settings: settings,
            usernameController: usernameController,
            passwordController: passwordController,
            mounted: mounted,
            onClearCache: onClearCache,
          ),
        ),
      ],
    ),
  );
}

// ─── Body ─────────────────────────────────────────────────────────────────────

Widget buildCupertinoBody({
  required BuildContext context,
  required dynamic state,
  required AppSettings settings,
  required TextEditingController usernameController,
  required TextEditingController passwordController,
  required bool mounted,
  required Future<void> Function() onClearCache,
}) {
  final notifier = sl<SettingsController>();
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
                controller: usernameController,
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
                controller: passwordController,
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
                      final u = usernameController.text.trim();
                      final p = passwordController.text;
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
                      await sl<TimetableController>()
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
              title: Text(statusText(state)),
              additionalInfo: state.data != null
                  ? Text('第 ${state.displayWeek} 周')
                  : null,
            ),
          ],
        ),

        // ── 外观 ──
        buildCupertinoThemeSection(context, settings, notifier),

        // ── 设计风格 ──
        buildCupertinoDesignStyleSection(context, settings, notifier),

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
                onTap: () => showCupertinoPortDialog(context, settings.proxyPort, (p) => notifier.setProxyPort(p)),
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
              onTap: () => confirmClearCacheCupertino(context, mounted, onClearCache),
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
        buildCupertinoAboutSection(context),

        const SizedBox(height: 40),
      ],
    ),
  );
}

// ─── Theme section ────────────────────────────────────────────────────────────

Widget buildCupertinoThemeSection(
  BuildContext context,
  AppSettings settings,
  SettingsController notifier,
) {
  return CupertinoListSection.insetGrouped(
    header: const Text('外观'),
    children: [
      CupertinoListTile(
        leading: const Icon(CupertinoIcons.paintbrush, size: 29),
        title: const Text('主题模式'),
        additionalInfo: Text(themeModeLabel(settings.themeMode)),
        trailing: const CupertinoListTileChevron(),
        onTap: () => showCupertinoThemeModePicker(context, settings.themeMode, notifier),
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
          onTap: () => showCupertinoColorPicker(context, settings.seedColor, notifier),
        ),
    ],
  );
}

// ─── Design style section ─────────────────────────────────────────────────────

Widget buildCupertinoDesignStyleSection(
  BuildContext context,
  AppSettings settings,
  SettingsController notifier,
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

// ─── About section ────────────────────────────────────────────────────────────

Widget buildCupertinoAboutSection(BuildContext context) {
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
        onTap: () => checkForUpdateCupertino(context),
      ),
    ],
  );
}

// ─── Pickers & dialogs ────────────────────────────────────────────────────────

void showCupertinoThemeModePicker(
  BuildContext context,
  ThemeMode current,
  SettingsController notifier,
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

void showCupertinoColorPicker(
  BuildContext context,
  Color current,
  SettingsController notifier,
) {
  const colors = ThemeSettingsSection.seedColors;
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

void showCupertinoPortDialog(BuildContext context, int currentPort, Function(int) onSave) {
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

Future<void> confirmClearCacheCupertino(
  BuildContext context,
  bool mounted,
  Future<void> Function() onClearCache,
) async {
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
    await onClearCache();
  }
}

// ─── Utilities ────────────────────────────────────────────────────────────────

String statusText(dynamic state) {
  if (state.isLoading) return '正在同步...';
  if (state.data != null) return '已同步';
  return '未同步';
}

String themeModeLabel(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.system:
      return '跟随系统';
    case ThemeMode.light:
      return '浅色';
    case ThemeMode.dark:
      return '深色';
  }
}

// ─── Update check (Cupertino specific) ────────────────────────────────────────

Future<void> checkForUpdateCupertino(BuildContext context) async {
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
      designStyle: DesignStyle.cupertino,
      message: '检查更新失败，请稍后重试',
    );
  }
}
