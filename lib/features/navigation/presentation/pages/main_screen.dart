import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_helpers.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/presentation/platform_exit.dart';
import 'package:li_curriculum_table/core/presentation/terms_of_service.dart';
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

class _MainScreenState extends State<MainScreen> {
  late final PageController _pageController;
  final _pageViewKey = GlobalKey();
  final _nav = sl<NavigationController>();
  final _sync = sl<GlobalSyncController>();
  final _settings = sl<SettingsController>();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _nav.currentIndex.value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTermsIfNeeded();
      _checkForUpdate();
    });
  }

  Future<void> _showTermsIfNeeded() async {
    if (_settings.termsAccepted.value) return;
    if (!mounted) return;
    final agreed = await showTermsOfServiceDialog(context);
    if (agreed && mounted) {
      await _settings.setTermsAccepted(true);
    } else if (!agreed) {
      exitApp();
    }
  }

  @override
  void dispose() {
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

  Widget _buildPageContent() {
    return Column(
      key: _pageViewKey,
      children: [
        if (isDesktop) const TitleBar(),
        Expanded(
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _nav.currentIndex.value;
    final isSyncing = _sync.isSyncing.value;

    return Scaffold(
      body: _buildPageContent(),
      floatingActionButton: (currentIndex == 4 || currentIndex == 5)
          ? null
          : M3EFab(
              onPressed: isSyncing ? null : () => _sync.syncGlobal(),
              tooltip: '同步数据',
              color: M3EFabColor.secondary,
              icon: isSyncing
                  ? adaptiveActivityIndicator(
                      size: 24,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    )
                  : const Icon(Icons.refresh),
            ),
      bottomNavigationBar: _buildMaterialNavBar(currentIndex),
    );
  }

  Widget _buildMaterialNavBar(int currentIndex) {
    return M3ENavigationBar(
      selectedIndex: currentIndex,
      indicatorStyle: M3ENavBarIndicatorStyle.pill,
      labelBehavior: M3ENavBarLabelBehavior.alwaysShow,
      shapeFamily: M3ENavBarShapeFamily.square,
      onDestinationSelected: (index) {
        FocusScope.of(context).unfocus();
        _nav.setIndex(index);
        _pageController.jumpToPage(index);
      },
      destinations: [
        M3ENavigationBarDestination(
          icon: Icon(AppIcons.timetableOutline(null)),
          selectedIcon: Icon(AppIcons.timetable(null)),
          label: '课表',
        ),
        M3ENavigationBarDestination(
          icon: Icon(AppIcons.classroomOutline(null)),
          selectedIcon: Icon(AppIcons.classroom(null)),
          label: '空闲教室',
        ),
        M3ENavigationBarDestination(
          icon: Icon(AppIcons.gradeOutline(null)),
          selectedIcon: Icon(AppIcons.grade(null)),
          label: '成绩',
        ),
        M3ENavigationBarDestination(
          icon: Icon(AppIcons.examOutline(null)),
          selectedIcon: Icon(AppIcons.exam(null)),
          label: '考试',
        ),
        M3ENavigationBarDestination(
          icon: Icon(AppIcons.bookOutline(null)),
          selectedIcon: Icon(AppIcons.book(null)),
          label: '图书',
        ),
        M3ENavigationBarDestination(
          icon: Icon(AppIcons.settingsOutline(null)),
          selectedIcon: Icon(AppIcons.settings(null)),
          label: '设置',
        ),
      ],
    );
  }
}
