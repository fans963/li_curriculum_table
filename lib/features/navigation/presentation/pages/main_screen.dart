import 'package:flutter/material.dart';

import 'package:li_curriculum_table/features/settings/presentation/pages/tabs/settings_tab.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/tabs/timetable_tab.dart';
import 'package:li_curriculum_table/util/util.dart';
import 'package:li_curriculum_table/features/timetable/presentation/bar/title_bar.dart';
import 'package:li_curriculum_table/features/classroom/presentation/pages/classroom_tab.dart';
import 'package:li_curriculum_table/features/grades/presentation/pages/grades_tab.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:li_curriculum_table/features/settings/presentation/pages/tabs/settings_tab.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/tabs/timetable_tab.dart';
import 'package:li_curriculum_table/util/util.dart';
import 'package:li_curriculum_table/features/timetable/presentation/bar/title_bar.dart';
import 'package:li_curriculum_table/features/classroom/presentation/pages/classroom_tab.dart';
import 'package:li_curriculum_table/features/grades/presentation/pages/grades_tab.dart';
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

  final List<Widget> _tabs = [
    TimetableTab(),
    ClassroomTab(),
    GradesTab(),
    SettingsTab(),
  ];

  @override
  void initState() {
    super.initState();
    // Remove the native splash screen after the first frame
    FlutterNativeSplash.remove();
    
    final initialIndex = ref.read(navigationControllerProvider);
    _pageController = PageController(initialPage: initialIndex);
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
    
    return Scaffold(
      body: Column(
        children: [
          if (isDesktop) TitleBar(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: _tabs,
            ),
          ),
        ],
      ),
      floatingActionButton: (currentIndex == 3) // No refresh button on Settings
        ? null
        : FloatingActionButton(
            onPressed: syncState.isSyncing 
              ? null 
              : () => ref.read(globalSyncControllerProvider.notifier).syncGlobal(),
            child: syncState.isSyncing
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.refresh),
          ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(navigationControllerProvider.notifier).setIndex(index);
          _pageController.animateToPage(
            index,
            duration: kDefaultAnimationDuration,
            curve: kDefaultAnimationCurve,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_view_week_outlined),
            selectedIcon: Icon(Icons.calendar_view_week),
            label: '课表',
          ),
          NavigationDestination(
            icon: Icon(Icons.room_outlined),
            selectedIcon: Icon(Icons.room),
            label: '空闲教室',
          ),
          NavigationDestination(
            icon: Icon(Icons.grade_outlined),
            selectedIcon: Icon(Icons.grade),
            label: '成绩',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
