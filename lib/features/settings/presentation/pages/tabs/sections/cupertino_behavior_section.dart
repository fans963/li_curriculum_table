part of '../settings_cupertino.dart';

class _InteractionCard extends StatelessWidget {
  final AppSettings settings;
  final SettingsController notifier;

  const _InteractionCard({required this.settings, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return _iosCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _iosTile(
            context,
            icon: CupertinoIcons.rectangle_grid_1x2,
            title: '按星期滑动',
            subtitle: '以整周为单位左右对齐滑动',
            trailing: IgnorePointer(child: CupertinoSwitch(value: settings.weeklyScroll, onChanged: notifier.setWeeklyScroll)),
          ),
          _iosTile(
            context,
            icon: CupertinoIcons.book,
            title: '图书馆检索封面',
            subtitle: '自动获取图书封面，开启将消耗更多流量',
            trailing: IgnorePointer(child: CupertinoSwitch(value: settings.enableBookCover, onChanged: notifier.setEnableBookCover)),
            showDivider: false,
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
            trailing: IgnorePointer(child: CupertinoSwitch(value: settings.proxyEnabled, onChanged: notifier.setProxyEnabled)),
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
      child: _iosTile(
        context,
        icon: CupertinoIcons.delete,
        iconColor: CupertinoColors.systemRed,
        title: '清除所有缓存',
        trailing: null,
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
    );
  }
}

