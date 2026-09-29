import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/presentation/styles/styles.dart';
import 'package:li_curriculum_table/core/presentation/platform_exit.dart';
import 'package:li_curriculum_table/core/presentation/terms_of_service.dart';
import 'package:li_curriculum_table/core/presentation/widgets/initial_theme_dialog.dart';
import 'package:li_curriculum_table/core/presentation/update_dialog.dart';
import 'package:li_curriculum_table/core/services/update_service.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/navigation/presentation/state/global_sync_controller.dart';
import 'package:li_curriculum_table/features/navigation/presentation/state/navigation_controller.dart';
import 'package:li_curriculum_table/features/book/presentation/pages/book_tab.dart';
import 'package:li_curriculum_table/features/classroom/presentation/pages/classroom_tab.dart';
import 'package:li_curriculum_table/features/exam_schedule/presentation/pages/exam_schedule_tab.dart';
import 'package:li_curriculum_table/features/grades/presentation/pages/grades_tab.dart';
import 'package:li_curriculum_table/features/settings/presentation/pages/tabs/settings_tab.dart';
import 'package:li_curriculum_table/features/timetable/presentation/bar/title_bar.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/tabs/timetable_tab.dart';
import 'package:li_curriculum_table/util/util.dart';
import 'package:signals/signals_flutter.dart';

class MainScreen extends SignalStatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  late final PageController _pageController;
  late final EffectCleanup _syncSelectedPage;
  final _pageViewKey = GlobalKey();
  final _nav = sl<NavigationController>();
  final _sync = sl<GlobalSyncController>();
  final _settings = sl<SettingsController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(initialPage: _nav.currentIndex.value);
    _syncSelectedPage = effect(() {
      final index = _nav.currentIndex.value;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) return;
        if (_pageController.page?.round() != index) {
          _pageController.jumpToPage(index);
        }
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _showFirstRunDialogs();
      if (mounted && _settings.termsAccepted.value) {
        await _checkForUpdate();
      }
    });
  }

  Future<void> _showFirstRunDialogs() async {
    if (!mounted) return;
    if (!_settings.termsAccepted.value) {
      final agreed = await showTermsOfServiceDialog(
        context,
        designStyle: _settings.designStyle.value,
      );
      if (!agreed) {
        exitApp();
        return;
      }
      if (!mounted) return;
      await _settings.setTermsAccepted(true);
    }
    if (!mounted || _settings.themeOnboardingCompleted.value) return;
    final originalStyle = _settings.designStyle.value;
    final originalMode = _settings.themeMode.value;
    final choice = await showInitialThemeDialog(
      context,
      designStyle: originalStyle,
      themeMode: originalMode,
      onPreview: (selection) => _settings.previewAppearance(
        designStyle: selection.designStyle,
        themeMode: selection.themeMode,
      ),
    );
    if (!mounted) return;
    if (choice == null) {
      _settings.previewAppearance(
        designStyle: originalStyle,
        themeMode: originalMode,
      );
      return;
    }
    await _settings.completeThemeOnboarding(
      designStyle: choice.designStyle,
      themeMode: choice.themeMode,
    );
  }

  @override
  void didChangePlatformBrightness() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncSelectedPage();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkForUpdate() async {
    if (kIsWeb) return;
    try {
      final updateInfo = await sl<UpdateService>().checkForUpdate();
      if (mounted) {
        await showUpdateDialogIfNeeded(context, updateInfo, silent: true);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Update check error: $e');
    }
  }

  Widget _buildPageContent({double paddingBottom = 0}) {
    return Column(
      key: _pageViewKey,
      children: [
        if (isDesktop) const TitleBar(),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: paddingBottom),
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                TimetableTab(),
                ClassroomTab(),
                GradesTab(),
                ExamScheduleTab(),
                BookTab(),
                SettingsTab(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _nav.currentIndex.value;
    final isSyncing = _sync.isSyncing.value;
    final settings = _settings.state.value;
    final ds = settings.designStyle;
    final style = UiStyleRegistry.resolve(ds);
    final resolvedBrightness = switch (settings.themeMode) {
      ThemeMode.dark => Brightness.dark,
      ThemeMode.light => Brightness.light,
      ThemeMode.system =>
        WidgetsBinding.instance.platformDispatcher.platformBrightness,
    };

    final items = [
      NavigationItemConfig(
        icon: Icon(AppIcons.timetableOutline(ds)),
        selectedIcon: Icon(AppIcons.timetable(ds)),
        label: '课表',
      ),
      NavigationItemConfig(
        icon: Icon(AppIcons.classroomOutline(ds)),
        selectedIcon: Icon(AppIcons.classroom(ds)),
        label: '空闲教室',
      ),
      NavigationItemConfig(
        icon: Icon(AppIcons.gradeOutline(ds)),
        selectedIcon: Icon(AppIcons.grade(ds)),
        label: '成绩',
      ),
      NavigationItemConfig(
        icon: Icon(AppIcons.examOutline(ds)),
        selectedIcon: Icon(AppIcons.exam(ds)),
        label: '考试',
      ),
      NavigationItemConfig(
        icon: Icon(AppIcons.bookOutline(ds)),
        selectedIcon: Icon(AppIcons.book(ds)),
        label: '图书',
      ),
      NavigationItemConfig(
        icon: Icon(AppIcons.settingsOutline(ds)),
        selectedIcon: Icon(AppIcons.settings(ds)),
        label: '设置',
      ),
    ];

    Widget? actionButton;
    if (currentIndex < 4) {
      actionButton = style.buildNavigationActionButton(
        context: context,
        icon: isSyncing
            ? style.buildActivityIndicator(context: context, size: 20)
            : Icon(style.icons.refresh, size: 20),
        label: '同步数据',
        onPressed: isSyncing ? null : () => _sync.syncGlobal(),
      );
    }

    return style.buildNavigationShell(
      context: context,
      brightness: resolvedBrightness,
      currentIndex: currentIndex,
      onIndexChanged: (index) {
        FocusScope.of(context).unfocus();
        _nav.setIndex(index);
        _pageController.jumpToPage(index);
      },
      items: items,
      body: _buildPageContent(
        paddingBottom: style.usesAmbientBackground ? 112 : 0,
      ),
      actionButton: actionButton,
    );
  }
}
