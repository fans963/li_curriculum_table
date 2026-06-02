import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_helpers.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
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
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:signals/signals_flutter.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final PageController _pageController;
  final _nav = sl<NavigationController>();
  final _sync = sl<GlobalSyncController>();
  final _settings = sl<SettingsController>();

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    _pageController = PageController(initialPage: _nav.currentIndex.value);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    try {
      final updateInfo = await sl<UpdateService>().checkForUpdate();
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
    return SignalBuilder(builder: (context) {
      final currentIndex = _nav.currentIndex.value;
      final isSyncing = _sync.isSyncing.value;
      final settings = _settings.state.value;
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
            : isCupertino
                ? _buildCupertinoSyncButton(context, isSyncing)
                : FloatingActionButton(
                    onPressed: isSyncing
                        ? null
                        : () => _sync.syncGlobal(),
                    child: isSyncing
                        ? adaptiveActivityIndicator(
                            designStyle: ds,
                            size: 24,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          )
                        : const Icon(Icons.refresh),
                  ),
        bottomNavigationBar: isCupertino
            ? CupertinoTabBar(
                currentIndex: currentIndex,
                onTap: (index) {
                  _nav.setIndex(index);
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
                  _nav.setIndex(index);
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
    });
  }

  Widget _buildCupertinoSyncButton(BuildContext context, bool isSyncing) {
    return CupertinoButton.filled(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(50),
      onPressed: isSyncing ? null : () => _sync.syncGlobal(),
      child: isSyncing
          ? const CupertinoActivityIndicator(
              radius: 12,
              color: CupertinoColors.white,
            )
          : const Icon(
              CupertinoIcons.arrow_clockwise,
              color: CupertinoColors.white,
              size: 22,
            ),
    );
  }
}
