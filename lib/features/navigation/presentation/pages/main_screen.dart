import 'package:cupertino_liquid_glass/cupertino_liquid_glass.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_helpers.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/presentation/update_dialog.dart';
import 'package:li_curriculum_table/core/services/update_service.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
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

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final PageController _pageController;
  // GlobalKey lets Flutter reuse the PageView even when its parent
  // widget tree changes between Material and Cupertino layouts.
  final _pageViewKey = GlobalKey();
  final _nav = sl<NavigationController>();
  final _sync = sl<GlobalSyncController>();
  final _settings = sl<SettingsController>();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _nav.currentIndex.value);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkForUpdate() async {
    try {
      final updateInfo = await sl<UpdateService>().checkForUpdate();
      if (mounted) {
        await showUpdateDialogIfNeeded(context, updateInfo, silent: true);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Update check error: $e');
    }
  }

  /// Build the page content once with a GlobalKey so Flutter can match it
  /// across design style changes regardless of parent widget tree shape.
  Widget _buildPageContent() {
    return Column(
      key: _pageViewKey,
      children: [
        if (isDesktop) TitleBar(),
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
    return SignalBuilder(builder: (context) {
      final currentIndex = _nav.currentIndex.value;
      final isSyncing = _sync.isSyncing.value;
      final settings = _settings.state.value;
      final ds = settings.designStyle;
      final isCupertino = AdaptiveStyle.isCupertino(ds);

      if (isCupertino) {
        // Cupertino: liquid glass bar floats OVER the content
        return Scaffold(
          body: Stack(
            children: [
              _buildPageContent(),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildCupertinoTabBar(
                  context, currentIndex, ds, isSyncing,
                ),
              ),
            ],
          ),
        );
      }

      // Material: standard Scaffold with bottomNavigationBar + FAB
      return Scaffold(
        body: _buildPageContent(),
        floatingActionButton: (currentIndex == 4 || currentIndex == 5)
            ? null
            : FloatingActionButton(
                onPressed: isSyncing ? null : () => _sync.syncGlobal(),
                tooltip: '同步数据',
                child: isSyncing
                    ? adaptiveActivityIndicator(
                        designStyle: ds,
                        size: 24,
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                      )
                    : const Icon(Icons.refresh),
              ),
        bottomNavigationBar: _buildMaterialNavBar(currentIndex, ds),
      );
    });
  }

  Widget _buildMaterialNavBar(int currentIndex, DesignStyle ds) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        _nav.setIndex(index);
        _pageController.jumpToPage(index);
      },
      destinations: [
        NavigationDestination(
          icon: Icon(AppIcons.timetableOutline(ds)),
          selectedIcon: Icon(AppIcons.timetable(ds)),
          label: '课表',
        ),
        NavigationDestination(
          icon: Icon(AppIcons.classroomOutline(ds)),
          selectedIcon: Icon(AppIcons.classroom(ds)),
          label: '空闲教室',
        ),
        NavigationDestination(
          icon: Icon(AppIcons.gradeOutline(ds)),
          selectedIcon: Icon(AppIcons.grade(ds)),
          label: '成绩',
        ),
        NavigationDestination(
          icon: Icon(AppIcons.examOutline(ds)),
          selectedIcon: Icon(AppIcons.exam(ds)),
          label: '考试',
        ),
        NavigationDestination(
          icon: Icon(AppIcons.bookOutline(ds)),
          selectedIcon: Icon(AppIcons.book(ds)),
          label: '图书',
        ),
        NavigationDestination(
          icon: Icon(AppIcons.settingsOutline(ds)),
          selectedIcon: Icon(AppIcons.settings(ds)),
          label: '设置',
        ),
      ],
    );
  }

  Widget _buildCupertinoTabBar(
    BuildContext context,
    int currentIndex,
    DesignStyle ds,
    bool isSyncing,
  ) {
    return CupertinoLiquidGlassBottomBar(
      theme: LiquidGlassThemeData.light().copyWith(tintOpacity: 0.3),
      currentIndex: currentIndex,
      onTap: (index) {
        _nav.setIndex(index);
        _pageController.jumpToPage(index);
      },
      items: [
        LiquidGlassBottomBarItem(
          icon: AppIcons.timetableOutline(ds),
          activeIcon: AppIcons.timetable(ds),
          label: '课表',
        ),
        LiquidGlassBottomBarItem(
          icon: AppIcons.classroomOutline(ds),
          activeIcon: AppIcons.classroom(ds),
          label: '空闲教室',
        ),
        LiquidGlassBottomBarItem(
          icon: AppIcons.gradeOutline(ds),
          activeIcon: AppIcons.grade(ds),
          label: '成绩',
        ),
        LiquidGlassBottomBarItem(
          icon: AppIcons.examOutline(ds),
          activeIcon: AppIcons.exam(ds),
          label: '考试',
        ),
        LiquidGlassBottomBarItem(
          icon: AppIcons.bookOutline(ds),
          activeIcon: AppIcons.book(ds),
          label: '图书',
        ),
        LiquidGlassBottomBarItem(
          icon: AppIcons.settingsOutline(ds),
          activeIcon: AppIcons.settings(ds),
          label: '设置',
        ),
      ],
      detachedButton: (currentIndex >= 4)
          ? null
          : LiquidGlassDetachedButton(
              onTap: isSyncing ? null : () => _sync.syncGlobal(),
              child: isSyncing
                  ? const CupertinoActivityIndicator(
                      radius: 10,
                      color: CupertinoColors.systemBlue,
                    )
                  : Icon(
                      CupertinoIcons.arrow_2_circlepath,
                      color: CupertinoColors.systemBlue.resolveFrom(context),
                      size: 20,
                    ),
            ),
    );
  }
}
