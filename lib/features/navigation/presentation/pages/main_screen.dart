import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:li_curriculum_table/core/presentation/adaptive_helpers.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/presentation/update_dialog.dart';
import 'package:li_curriculum_table/core/services/update_service.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/settings/presentation/pages/tabs/settings_tab.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/tabs/timetable_tab.dart';
import 'package:li_curriculum_table/util/util.dart';
import 'package:li_curriculum_table/features/timetable/presentation/bar/title_bar.dart';
import 'package:li_curriculum_table/features/classroom/presentation/pages/classroom_tab.dart';
import 'package:li_curriculum_table/features/grades/presentation/pages/grades_tab.dart';
import 'package:li_curriculum_table/features/exam_schedule/presentation/pages/exam_schedule_tab.dart';
import 'package:li_curriculum_table/features/book/presentation/pages/book_tab.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:li_curriculum_table/features/navigation/presentation/state/navigation_controller.dart';

import 'package:li_curriculum_table/features/navigation/presentation/state/global_sync_controller.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    final initialIndex = ref.read(navigationControllerProvider);
    _pageController = PageController(initialPage: initialIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    try {
      final updateInfo = await UpdateService().checkForUpdate();
      if (mounted) {
        await showUpdateDialogIfNeeded(context, updateInfo, silent: true);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationControllerProvider);
    final syncState = ref.watch(globalSyncControllerProvider);
    final settings = ref.watch(settingsControllerProvider);
    final ds = settings.designStyle;
    final isCupertino = AdaptiveStyle.isCupertino(ds);

    return Scaffold(
      body: Column(
        children: [
          if (isDesktop) TitleBar(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
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
      ),
      floatingActionButton: (currentIndex == 4 || currentIndex == 5)
          ? null
          : FloatingActionButton(
              onPressed: syncState.isSyncing
                  ? null
                  : () => ref.read(globalSyncControllerProvider.notifier).syncGlobal(),
              child: syncState.isSyncing
                  ? adaptiveActivityIndicator(
                      designStyle: ds,
                      size: 24,
                      color: isCupertino
                          ? CupertinoColors.white
                          : Theme.of(context).colorScheme.onPrimaryContainer,
                    )
                  : Icon(isCupertino ? CupertinoIcons.arrow_clockwise : Icons.refresh),
            ),
      bottomNavigationBar: isCupertino
          ? CupertinoTabBar(
              currentIndex: currentIndex,
              onTap: (index) {
                ref.read(navigationControllerProvider.notifier).setIndex(index);
                _pageController.animateToPage(
                  index,
                  duration: kDefaultAnimationDuration,
                  curve: kDefaultAnimationCurve,
                );
              },
              items: [
                BottomNavigationBarItem(
                  icon: Icon(AppIcons.timetableOutline(ds)),
                  activeIcon: Icon(AppIcons.timetable(ds)),
                  label: '课表',
                ),
                BottomNavigationBarItem(
                  icon: Icon(AppIcons.classroomOutline(ds)),
                  activeIcon: Icon(AppIcons.classroom(ds)),
                  label: '空闲教室',
                ),
                BottomNavigationBarItem(
                  icon: Icon(AppIcons.gradeOutline(ds)),
                  activeIcon: Icon(AppIcons.grade(ds)),
                  label: '成绩',
                ),
                BottomNavigationBarItem(
                  icon: Icon(AppIcons.examOutline(ds)),
                  activeIcon: Icon(AppIcons.exam(ds)),
                  label: '考试',
                ),
                BottomNavigationBarItem(
                  icon: Icon(AppIcons.bookOutline(ds)),
                  activeIcon: Icon(AppIcons.book(ds)),
                  label: '图书',
                ),
                BottomNavigationBarItem(
                  icon: Icon(AppIcons.settingsOutline(ds)),
                  activeIcon: Icon(AppIcons.settings(ds)),
                  label: '设置',
                ),
              ],
            )
          : NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: (index) {
                ref.read(navigationControllerProvider.notifier).setIndex(index);
                _pageController.animateToPage(
                  index,
                  duration: kDefaultAnimationDuration,
                  curve: kDefaultAnimationCurve,
                );
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
            ),
    );
  }
}
