import 'package:flutter/material.dart';

import 'package:li_curriculum_table/features/settings/presentation/pages/tabs/settings_tab.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/tabs/timetable_tab.dart';
import 'package:li_curriculum_table/util/util.dart';
import 'package:li_curriculum_table/features/timetable/presentation/bar/title_bar.dart';
import 'package:li_curriculum_table/features/classroom/presentation/pages/classroom_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    TimetableTab(),
    ClassroomTab(),
    SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (isDesktop) const TitleBar(),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _tabs,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
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
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
