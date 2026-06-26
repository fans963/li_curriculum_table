part of '../settings_cupertino.dart';

class _AccountCard extends StatelessWidget {
  final dynamic state;
  final TextEditingController usernameController;
  final TextEditingController passwordController;

  const _AccountCard({required this.state, required this.usernameController, required this.passwordController});

  @override
  Widget build(BuildContext context) {
    return _iosCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: CupertinoTextField(
              controller: usernameController,
              placeholder: '学号',
              prefix: const Padding(padding: EdgeInsets.only(left: 8), child: Icon(CupertinoIcons.person, size: 20)),
              decoration: BoxDecoration(
                color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
                borderRadius: BorderRadius.circular(10),
              ),
              clearButtonMode: OverlayVisibilityMode.editing,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: CupertinoTextField(
              controller: passwordController,
              placeholder: '密码',
              obscureText: true,
              prefix: const Padding(padding: EdgeInsets.only(left: 8), child: Icon(CupertinoIcons.lock, size: 20)),
              decoration: BoxDecoration(
                color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
                borderRadius: BorderRadius.circular(10),
              ),
              clearButtonMode: OverlayVisibilityMode.editing,
            ),
          ),
          _iosTile(
            context,
            icon: state.isLoading ? CupertinoIcons.arrow_clockwise : CupertinoIcons.cloud_download,
            iconColor: CupertinoColors.systemBlue,
            title: '同步课表',
            trailing: state.isLoading
                ? const CupertinoActivityIndicator()
                : Icon(CupertinoIcons.chevron_forward, size: 16, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
            showDivider: false,
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
                          actions: [CupertinoDialogAction(isDefaultAction: true, child: const Text('好的'), onPressed: () => Navigator.pop(ctx))],
                        ),
                      );
                      return;
                    }
                    FocusScope.of(context).unfocus();
                    await sl<TimetableController>().fetchAndBuild(username: u, password: p);
                  },
          ),
        ],
      ),
    );
  }
}

class _SyncStatusCard extends StatelessWidget {
  final dynamic state;
  const _SyncStatusCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return _iosCard(
      child: _iosTile(
        context,
        icon: state.isLoading
            ? CupertinoIcons.arrow_clockwise
            : (state.data != null ? CupertinoIcons.check_mark_circled : CupertinoIcons.xmark_circle),
        iconColor: state.isLoading
            ? CupertinoColors.systemOrange
            : (state.data != null ? CupertinoColors.systemGreen : CupertinoColors.systemRed),
        title: statusText(state),
        trailing: state.data != null
            ? Text('第 ${state.displayWeek} 周', style: TextStyle(fontSize: 15, color: CupertinoColors.secondaryLabel.resolveFrom(context)))
            : null,
        showDivider: false,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Theme Card
// ═══════════════════════════════════════════════════════════════════════════

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return _iosCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _iosTile(
            context,
            icon: CupertinoIcons.arrow_down_circle,
            title: '检查更新',
            onTap: () => _checkUpdate(context),
          ),
          _iosTile(
            context,
            icon: CupertinoIcons.globe,
            title: 'GitHub',
            subtitle: '查看源代码',
            onTap: () => launchUrl(Uri.parse('https://github.com/fans963/--table'), mode: LaunchMode.externalApplication),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Future<void> _checkUpdate(BuildContext context) async {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CupertinoAlertDialog(
        content: Padding(
          padding: EdgeInsets.only(top: 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [CupertinoActivityIndicator(), SizedBox(height: 12), Text('正在检查更新...')]),
        ),
      ),
    );
    try {
      final info = await sl<UpdateService>().checkForUpdate();
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      if (context.mounted) await showUpdateDialogIfNeeded(context, info, silent: false);
    } catch (_) {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      if (context.mounted) showAdaptiveMessage(context, designStyle: DesignStyle.cupertino, message: '检查更新失败，请稍后重试');
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Utilities
// ═══════════════════════════════════════════════════════════════════════════

String statusText(dynamic state) {
  if (state.isLoading) return '正在同步...';
  if (state.data != null) return '已同步';
  return '未同步';
}

String themeModeLabel(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.system: return '跟随系统';
    case ThemeMode.light: return '浅色';
    case ThemeMode.dark: return '深色';
  }
}
