part of '../settings_cupertino.dart';

class _InteractionCard extends StatelessWidget {
  final AppSettings settings;
  final SettingsController notifier;

  const _InteractionCard({required this.settings, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final daysLabel = settings.weeklyScroll
        ? ''
        : ' — 屏幕显示 ${settings.daysVisibleCount} 天';
    return _iosCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _iosTile(
            context,
            icon: CupertinoIcons.textformat,
            title: '课表文字自适应',
            subtitle: '自动缩小字号以完整显示课程名和地点',
            trailing: CupertinoSwitch(value: settings.autoSizeText, onChanged: notifier.setAutoSizeText),
            onTap: () => notifier.setAutoSizeText(!settings.autoSizeText),
          ),
          if (settings.autoSizeText)
            _CupertinoAutoSizeSlider(settings: settings, notifier: notifier)
          else
            _CupertinoFixedTextSettings(settings: settings, notifier: notifier),
          _iosTile(
            context,
            icon: CupertinoIcons.rectangle_grid_1x2,
            title: '按星期滑动',
            subtitle: '以整周为单位左右对齐滑动$daysLabel',
            trailing: CupertinoSwitch(value: settings.weeklyScroll, onChanged: notifier.setWeeklyScroll),
            onTap: () => notifier.setWeeklyScroll(!settings.weeklyScroll),
          ),
          if (!settings.weeklyScroll)
            _iosTile(
              context,
              icon: CupertinoIcons.view_2d,
              title: '显示天数',
              subtitle: '屏幕内同时显示 ${settings.daysVisibleCount} 天课程',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${settings.daysVisibleCount} 天',
                    style: TextStyle(fontSize: 15, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
                  ),
                  const SizedBox(width: 8),
                  Icon(CupertinoIcons.chevron_forward, size: 16, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                ],
              ),
              onTap: () => _showDaysCountPicker(context),
            ),
          _iosTile(
            context,
            icon: CupertinoIcons.book,
            title: '图书馆检索封面',
            subtitle: '自动获取图书封面,目前数据库并不完善，仅有部分热门书籍封面信息',
            trailing: CupertinoSwitch(value: settings.enableBookCover, onChanged: notifier.setEnableBookCover),
            onTap: () => notifier.setEnableBookCover(!settings.enableBookCover),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  void _showDaysCountPicker(BuildContext context) {
    const options = [1, 3, 5, 7];
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('屏幕内显示天数'),
        message: const Text('选择课表视图同时显示几天的课程'),
        actions: options.map((days) {
          final selected = settings.daysVisibleCount == days;
          return CupertinoActionSheetAction(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$days 天${days == 7 ? ' (默认)' : ''}'),
                if (selected) ...[
                  const SizedBox(width: 8),
                  const Icon(CupertinoIcons.check_mark, size: 18, color: CupertinoColors.systemBlue),
                ],
              ],
            ),
            onPressed: () {
              notifier.setDaysVisibleCount(days);
              Navigator.pop(ctx);
            },
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          child: const Text('取消'),
          onPressed: () => Navigator.pop(ctx),
        ),
      ),
    );
  }
}

/// Slider for minimum font size when auto-size is ON (Cupertino style).
class _CupertinoAutoSizeSlider extends StatelessWidget {
  final AppSettings settings;
  final SettingsController notifier;

  const _CupertinoAutoSizeSlider({required this.settings, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(CupertinoIcons.textformat_size, size: 20, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('最小字号', style: TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel.resolveFrom(context))),
                CupertinoSlider(
                  value: settings.autoSizeMinFontSize,
                  min: 4,
                  max: 14,
                  divisions: 10,
                  onChanged: (v) => notifier.setAutoSizeMinFontSize(v),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              settings.autoSizeMinFontSize.toStringAsFixed(1),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CupertinoColors.systemBlue.resolveFrom(context)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Controls for font size and max lines when auto-size is OFF (Cupertino style).
class _CupertinoFixedTextSettings extends StatelessWidget {
  final AppSettings settings;
  final SettingsController notifier;

  const _CupertinoFixedTextSettings({required this.settings, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Font size slider
          Row(
            children: [
              Icon(CupertinoIcons.textformat_size, size: 20, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('字体大小', style: TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel.resolveFrom(context))),
                    CupertinoSlider(
                      value: settings.timetableTextFontSize,
                      min: 5,
                      max: 20,
                      divisions: 15,
                      onChanged: (v) => notifier.setTimetableTextFontSize(v),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  settings.timetableTextFontSize.toStringAsFixed(1),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CupertinoColors.systemBlue.resolveFrom(context)),
                ),
              ),
            ],
          ),
          // Max lines selector
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(CupertinoIcons.text_alignleft, size: 20, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
                const SizedBox(width: 12),
                Text('最大行数', style: TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel.resolveFrom(context))),
                const Spacer(),
                CupertinoSlidingSegmentedControl<int>(
                  groupValue: settings.timetableTextMaxLines,
                  onValueChanged: (v) { if (v != null) notifier.setTimetableTextMaxLines(v); },
                  children: const {
                    1: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('1')),
                    2: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('2')),
                    3: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('3')),
                    4: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('4')),
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Proxy Card
// ═══════════════════════════════════════════════════════════════════════════

class _ProxyCard extends StatelessWidget {
  final AppSettings settings;
  final SettingsController notifier;
  final TextEditingController proxyController;

  const _ProxyCard({required this.settings, required this.notifier, required this.proxyController});

  @override
  Widget build(BuildContext context) {
    return _iosCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _iosTile(
            context,
            icon: CupertinoIcons.wifi,
            title: '开启本地代理网关',
            subtitle: '其他设备可通过此应用共享会话',
            trailing: CupertinoSwitch(value: settings.proxyEnabled, onChanged: notifier.setProxyEnabled),
            onTap: () => notifier.setProxyEnabled(!settings.proxyEnabled),
          ),
          _iosTile(
            context,
            icon: CupertinoIcons.number,
            title: '监听端口',
            trailing: Row(
               mainAxisSize: MainAxisSize.min,
               children: [
                 Text('${settings.proxyPort}', style: TextStyle(fontSize: 15, color: CupertinoColors.secondaryLabel.resolveFrom(context))),
                 const SizedBox(width: 8),
                 Icon(CupertinoIcons.chevron_forward, size: 16, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
               ],
            ),
            onTap: () {
              proxyController.text = settings.proxyPort.toString();
              showCupertinoDialog(
                context: context,
                builder: (ctx) => CupertinoAlertDialog(
                  title: const Text('设置代理端口'),
                  content: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: CupertinoTextField(
                      controller: proxyController,
                      keyboardType: TextInputType.number,
                      placeholder: '端口号 (1024-65535)',
                      autofocus: true,
                      decoration: BoxDecoration(color: CupertinoColors.tertiarySystemFill.resolveFrom(ctx), borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  actions: [
                    CupertinoDialogAction(child: const Text('取消'), onPressed: () => Navigator.pop(ctx)),
                    CupertinoDialogAction(
                      isDefaultAction: true,
                      child: const Text('保存'),
                      onPressed: () {
                        final port = int.tryParse(proxyController.text);
                        if (port != null && port >= 1024 && port <= 65535) { notifier.setProxyPort(port); Navigator.pop(ctx); }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(CupertinoIcons.info, size: 14, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '设置正确的端口可让网页版自动识别并使用手机端的登录状态。',
                    style: TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Storage & About Cards
// ═══════════════════════════════════════════════════════════════════════════

class _StorageCard extends StatelessWidget {
  final Future<void> Function() onClearCache;
  final bool mounted;

  const _StorageCard({required this.onClearCache, required this.mounted});

  @override
  Widget build(BuildContext context) {
    return _iosCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _iosTile(
            context,
            icon: CupertinoIcons.share,
            title: '导出缓存',
            subtitle: '将本地数据导出为 JSON 文件分享',
            onTap: () async {
              try {
                await sl<CacheBackupService>().exportAndShare();
              } catch (_) {
                if (context.mounted) {
                  showAdaptiveMessage(context, designStyle: DesignStyle.cupertino, message: '导出失败');
                }
              }
            },
          ),
          _iosTile(
            context,
            icon: CupertinoIcons.doc,
            title: '导入缓存',
            subtitle: '从 JSON 文件导入数据',
            onTap: () async {
              try {
                final count = await sl<CacheBackupService>().importFromFile();
                if (count == null) return;
                if (!context.mounted) return;
                showAdaptiveMessage(context, designStyle: DesignStyle.cupertino, message: '已导入 $count 条数据');
                await sl<SettingsController>().init();
                await sl<TimetableController>().restoreCachedTimetable();
                await sl<TimetableController>().restoreCachedTeachingWeekBaseline();
                await sl<CourseColorService>().reload();
              } on FormatException catch (e) {
                if (context.mounted) showAdaptiveMessage(context, designStyle: DesignStyle.cupertino, message: e.message);
              } catch (_) {
                if (context.mounted) showAdaptiveMessage(context, designStyle: DesignStyle.cupertino, message: '导入失败');
              }
            },
          ),
          _iosTile(
            context,
            icon: CupertinoIcons.delete,
            iconColor: CupertinoColors.systemRed,
            title: '清除所有缓存',
            showDivider: false,
            onTap: () async {
              final confirmed = await showCupertinoDialog<bool>(
                context: context,
                builder: (ctx) => CupertinoAlertDialog(
                  title: const Text('确认清除缓存？'),
                  content: const Text('将删除所有离线课表和缓存数据。您仍将保持登录状态，但需要重新同步以加载数据。'),
                  actions: [
                    CupertinoDialogAction(child: const Text('取消'), onPressed: () => Navigator.pop(ctx, false)),
                    CupertinoDialogAction(isDestructiveAction: true, child: const Text('清除'), onPressed: () => Navigator.pop(ctx, true)),
                  ],
                ),
              );
              if (confirmed == true && mounted) await onClearCache();
            },
          ),
        ],
      ),
    );
  }
}

