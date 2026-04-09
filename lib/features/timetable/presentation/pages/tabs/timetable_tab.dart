import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:li_curriculum_table/features/timetable/domain/services/teaching_week_scheduler.dart';
import 'package:li_curriculum_table/features/timetable/presentation/calendar_view/timetable_week_view.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/timetable_page_sections.dart';
import 'package:li_curriculum_table/features/timetable/presentation/providers/timetable_providers.dart';

// UI Constants
const double _pixelsPerMinute = 0.78;
const int _startDisplayHour = 8;
const int _endDisplayHour = 22;

class TimetableTab extends ConsumerStatefulWidget {
  const TimetableTab({super.key});

  @override
  ConsumerState<TimetableTab> createState() => _TimetableTabState();
}

class _TimetableTabState extends ConsumerState<TimetableTab> {
  final _calendarKey = GlobalKey<TimetableWeekViewState>();
  Timer? _nowTicker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _nowTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _nowTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = ref.watch(timetableControllerProvider);
    final displayWeek = state.displayWeek;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          state.data != null ? '第 $displayWeek 周' : '我的课表',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surface,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TimetableStatusBanner(
                status: state.status,
                isLoading: state.isLoading,
                hasData: state.data != null,
              ),
            ),
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) => true,
                  child: TimetableWeekView(
                    key: _calendarKey,
                    startHour: _startDisplayHour,
                    endHour: _endDisplayHour,
                    pixelsPerMinute: _pixelsPerMinute,
                    now: _now,
                    onPageChange: (date, page) {
                      _syncDisplayWeekFromDate(date);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _syncDisplayWeekFromDate(DateTime date) {
    final state = ref.read(timetableControllerProvider);
    final anchor = state.termStartMonday;
    if (anchor == null) return;

    final week = calculateWeekIndex(date, anchor);
    if (week > state.maxWeek || week < state.minWeek) return;
    
    if (week != state.displayWeek) {
      ref.read(timetableControllerProvider.notifier).updateDisplayWeek(week);
    }
  }
}
