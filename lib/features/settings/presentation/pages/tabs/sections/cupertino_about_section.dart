part of '../settings_cupertino.dart';

class _AccountCard extends SignalStatefulWidget {
  final dynamic state;
  final TextEditingController usernameController;
  final TextEditingController passwordController;

  const _AccountCard({required this.state, required this.usernameController, required this.passwordController});

  @override
  State<_AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<_AccountCard> {
  late final _termController = TextEditingController(
    text: sl<SettingsController>().currentTerm.value,
  );

  @override
  void dispose() {
    _termController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsCtrl = sl<SettingsController>();
    final timetableCtrl = sl<TimetableController>();
    final termStart = timetableCtrl.termStartMonday.value;
    final state = widget.state;

    return _iosCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: CupertinoTextField(
              controller: widget.usernameController,
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
              controller: widget.passwordController,
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
          // Semester
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: CupertinoTextField(
              controller: _termController,
              placeholder: '当前学期 (如 2025-2026-1)',
              prefix: const Padding(padding: EdgeInsets.only(left: 8), child: Icon(CupertinoIcons.book, size: 20)),
              decoration: BoxDecoration(
                color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
                borderRadius: BorderRadius.circular(10),
              ),
              clearButtonMode: OverlayVisibilityMode.editing,
              onSubmitted: (v) => settingsCtrl.setCurrentTerm(v.trim()),
            ),
          ),
          // Term start date
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
              borderRadius: BorderRadius.circular(10),
              onPressed: () => _pickTermStartDate(context, timetableCtrl, termStart),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(CupertinoIcons.calendar, size: 20, color: termStart != null ? CupertinoColors.label.resolveFrom(context) : CupertinoColors.placeholderText.resolveFrom(context)),
                  const SizedBox(width: 8),
                  Text(
                    termStart != null
                        ? '开学: ${termStart.year}-${termStart.month.toString().padLeft(2, '0')}-${termStart.day.toString().padLeft(2, '0')}'
                        : '本学期开学日期 (点击设置)',
                    style: TextStyle(
                      fontSize: 16,
                      color: termStart != null
                          ? CupertinoColors.label.resolveFrom(context)
                          : CupertinoColors.placeholderText.resolveFrom(context),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    termStart != null ? '推算第 ${state.displayWeek ?? '?'} 周' : '',
                    style: TextStyle(fontSize: 13, color: CupertinoColors.systemBlue.resolveFrom(context)),
                  ),
                ],
              ),
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
                    final u = widget.usernameController.text.trim();
                    final p = widget.passwordController.text;
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

  void _pickTermStartDate(BuildContext context, TimetableController controller, DateTime? initial) {
    final selectedDate = signal(initial ?? DateTime.now());
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('选择开学日期'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: SizedBox(
            height: 180,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: selectedDate.value,
              minimumDate: DateTime(selectedDate.value.year - 1),
              maximumDate: DateTime(selectedDate.value.year + 1),
              onDateTimeChanged: (d) => selectedDate.value = d,
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('确定'),
            onPressed: () {
              controller.setTermStartDate(selectedDate.value);
              Navigator.pop(ctx);
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
            icon: CupertinoIcons.doc_text,
            title: '使用条款与隐私政策',
            onTap: () async {
              final agreed = await showTermsOfServiceDialog(
                context,
                designStyle: DesignStyle.cupertino,
                barrierDismissible: true,
              );
              if (!agreed && context.mounted) {
                await sl<SettingsController>().setTermsAccepted(false);
                await Future.delayed(const Duration(milliseconds: 200));
                exit(0);
              }
            },
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
