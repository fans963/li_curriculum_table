part of '../settings_cupertino.dart';

class _AccountCard extends SignalStatefulWidget {
  final dynamic state;
  final TextEditingController usernameController;
  final TextEditingController passwordController;

  const _AccountCard({
    required this.state,
    required this.usernameController,
    required this.passwordController,
  });

  @override
  State<_AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<_AccountCard> {
  @override
  Widget build(BuildContext context) {
    final settingsCtrl = sl<SettingsController>();
    final timetableCtrl = sl<TimetableController>();
    final termStart = timetableCtrl.termStartMonday.value;
    final state = widget.state;

    return _iosCard(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: CupertinoTextField(
              controller: widget.usernameController,
              placeholder: '学号',
              prefix: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(CupertinoIcons.person, size: 20),
              ),
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
              prefix: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(CupertinoIcons.lock, size: 20),
              ),
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
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
              borderRadius: BorderRadius.circular(10),
              onPressed: () => _pickSemester(context, settingsCtrl),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.book,
                    size: 20,
                    color: settingsCtrl.currentTerm.value.isNotEmpty
                        ? CupertinoColors.label.resolveFrom(context)
                        : CupertinoColors.placeholderText.resolveFrom(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    settingsCtrl.currentTerm.value.isNotEmpty
                        ? '学期: ${settingsCtrl.currentTerm.value}'
                        : '当前学期 (点击设置)',
                    style: TextStyle(
                      fontSize: 16,
                      color: settingsCtrl.currentTerm.value.isNotEmpty
                          ? CupertinoColors.label.resolveFrom(context)
                          : CupertinoColors.placeholderText.resolveFrom(
                              context,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Term start date
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
              borderRadius: BorderRadius.circular(10),
              onPressed: () =>
                  _pickTermStartDate(context, timetableCtrl, termStart),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.calendar,
                    size: 20,
                    color: termStart != null
                        ? CupertinoColors.label.resolveFrom(context)
                        : CupertinoColors.placeholderText.resolveFrom(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    termStart != null
                        ? '开学: ${termStart.year}-${termStart.month.toString().padLeft(2, '0')}-${termStart.day.toString().padLeft(2, '0')}'
                        : '本学期开学日期 (点击设置)',
                    style: TextStyle(
                      fontSize: 16,
                      color: termStart != null
                          ? CupertinoColors.label.resolveFrom(context)
                          : CupertinoColors.placeholderText.resolveFrom(
                              context,
                            ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    termStart != null
                        ? '推算第 ${state.displayWeek ?? '?'} 周'
                        : '',
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.systemBlue.resolveFrom(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _iosTile(
            context,
            icon: state.isLoading
                ? CupertinoIcons.arrow_clockwise
                : CupertinoIcons.cloud_download,
            iconColor: CupertinoColors.systemBlue,
            title: '同步课表',
            trailing: state.isLoading
                ? const CupertinoActivityIndicator()
                : Icon(
                    CupertinoIcons.chevron_forward,
                    size: 16,
                    color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                  ),
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
                    await sl<TimetableController>().fetchAndBuild(
                      username: u,
                      password: p,
                    );
                  },
          ),
        ],
      ),
    );
  }

  void _pickTermStartDate(
    BuildContext context,
    TimetableController controller,
    DateTime? initial,
  ) {
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

  List<String> _getSemesterOptions() {
    final now = DateTime.now();
    final int currentStartYear = now.month >= 9 ? now.year : now.year - 1;
    final List<String> options = [];
    for (int y = currentStartYear + 1; y >= currentStartYear - 4; y--) {
      options.add('$y-${y + 1}-3');
      options.add('$y-${y + 1}-2');
      options.add('$y-${y + 1}-1');
    }
    return options;
  }

  void _pickSemester(BuildContext context, SettingsController settingsCtrl) {
    final options = _getSemesterOptions();
    final current = settingsCtrl.currentTerm.value;
    if (current.isNotEmpty && !options.contains(current)) {
      options.insert(0, current);
    }

    final int initialIndex = options.indexOf(current);
    final selectedIndex = signal(initialIndex >= 0 ? initialIndex : 0);

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('选择当前学期'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: SizedBox(
            height: 180,
            child: CupertinoPicker(
              scrollController: FixedExtentScrollController(
                initialItem: selectedIndex.value,
              ),
              itemExtent: 36.0,
              onSelectedItemChanged: (index) => selectedIndex.value = index,
              children: options
                  .map(
                    (opt) => Center(
                      child: Text(opt, style: const TextStyle(fontSize: 18)),
                    ),
                  )
                  .toList(),
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
              if (selectedIndex.value >= 0 &&
                  selectedIndex.value < options.length) {
                settingsCtrl.setCurrentTerm(options[selectedIndex.value]);
              }
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
      context,
      child: _iosTile(
        context,
        icon: state.isLoading
            ? CupertinoIcons.arrow_clockwise
            : (state.data != null
                  ? CupertinoIcons.check_mark_circled
                  : CupertinoIcons.xmark_circle),
        iconColor: state.isLoading
            ? CupertinoColors.systemOrange
            : (state.data != null
                  ? CupertinoColors.systemGreen
                  : CupertinoColors.systemRed),
        title: statusText(state),
        trailing: state.data != null
            ? Text(
                '第 ${state.displayWeek} 周',
                style: TextStyle(
                  fontSize: 15,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              )
            : null,
        showDivider: false,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Feedback & About Cards
// ═══════════════════════════════════════════════════════════════════════════

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard();

  @override
  Widget build(BuildContext context) {
    return _iosCard(
      context,
      child: _iosTile(
        context,
        icon: CupertinoIcons.chat_bubble_2,
        title: '发送反馈',
        subtitle: '遇到问题或有建议？支持截图标注',
        showDivider: false,
        onTap: () => BetterFeedback.of(
          context,
        ).show((feedback) => FeedbackHandler.shareFeedback(feedback)),
      ),
    );
  }
}

class _CupertinoAboutCard extends StatelessWidget {
  const _CupertinoAboutCard();

  @override
  Widget build(BuildContext context) {
    return _iosCard(
      context,
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
                exitApp();
              }
            },
          ),
          _iosTile(
            context,
            icon: CupertinoIcons.globe,
            title: 'GitHub',
            subtitle: '查看源代码',
            onTap: () => launchUrl(
              Uri.parse('https://github.com/fans963/--table'),
              mode: LaunchMode.externalApplication,
            ),
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
      final info = await sl<UpdateService>().checkForUpdate();
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      if (context.mounted)
        await showUpdateDialogIfNeeded(context, info, silent: false);
    } catch (_) {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      if (context.mounted)
        showAdaptiveMessage(
          context,
          designStyle: DesignStyle.cupertino,
          message: '检查更新失败，请稍后重试',
        );
    }
  }
}

class _CupertinoAppInfoCard extends StatelessWidget {
  const _CupertinoAppInfoCard();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '...';
        final buildNumber = snapshot.data?.buildNumber ?? '';
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
              context,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: CupertinoColors.separator
                  .resolveFrom(context)
                  .withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.systemBlue
                          .resolveFrom(context)
                          .withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset('assets/icon/icon.png'),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '🍐 课表',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'v$version${buildNumber.isNotEmpty ? ' ($buildNumber)' : ''}',
                style: TextStyle(
                  fontSize: 15,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '一款轻盈优雅的跨平台本地安全课表应用',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CupertinoWebDownloadCard extends StatelessWidget {
  const _CupertinoWebDownloadCard();

  static const _owner = 'fans963';
  static const _repo = 'li_curriculum_table';
  static const _assets = [
    ('app-arm64-v8a-release.apk', 'Android ARM64'),
    ('app-armeabi-v7a-release.apk', 'Android ARM32'),
    ('app-x86_64-release.apk', 'Android x86_64'),
    ('li-curriculum-table-unsigned.ipa', 'iOS (IPA)'),
  ];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '';
        return _iosCard(
          context,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.device_phone_portrait,
                      size: 18,
                      color: CupertinoColors.systemBlue.resolveFrom(context),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      '下载本地应用',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              for (var i = 0; i < _assets.length; i++)
                _iosTile(
                  context,
                  icon: i == 0
                      ? CupertinoIcons.device_phone_portrait
                      : CupertinoIcons.download_circle,
                  title: _assets[i].$2,
                  subtitle: _assets[i].$1,
                  showDivider: i < _assets.length - 1,
                  onTap: () async {
                    final gitee = Uri.parse(
                      'https://gitee.com/$_owner/$_repo/releases/download/v$version/${_assets[i].$1}',
                    );
                    final gh = Uri.parse(
                      'https://github.com/$_owner/$_repo/releases/download/v$version/${_assets[i].$1}',
                    );
                    for (final uri in [gitee, gh]) {
                      try {
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.platformDefault,
                          );
                          return;
                        }
                      } catch (_) {}
                    }
                    if (context.mounted) {
                      showAdaptiveMessage(
                        context,
                        designStyle: DesignStyle.cupertino,
                        message: '无法打开下载链接',
                      );
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

// statusText & themeModeLabel extracted to cupertino_settings_utils.dart
