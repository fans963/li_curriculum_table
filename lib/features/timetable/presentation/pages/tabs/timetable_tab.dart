import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:li_curriculum_table/features/timetable/domain/services/teaching_week_scheduler.dart';
import 'package:li_curriculum_table/features/timetable/presentation/calendar_view/timetable_week_view.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/timetable_page_sections.dart';
import 'package:li_curriculum_table/features/timetable/presentation/providers/timetable_providers.dart';
import 'package:li_curriculum_table/features/timetable/presentation/state/timetable_controller.dart';
import 'package:li_curriculum_table/util/util.dart';

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

    // Restore cached data on startup
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(timetableControllerProvider.notifier);
      await notifier.restoreCachedTimetable();
      await notifier.restoreCachedTeachingWeekBaseline();
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
              child: AnimatedSwitcher(
                duration: kDefaultAnimationDuration,
                switchInCurve: kDefaultAnimationCurve,
                switchOutCurve: kDefaultAnimationCurve,
                child: state.needsLogin
                    ? _NeedsLoginView(
                        key: const ValueKey('needs_login'),
                        onSync: () => ref
                            .read(timetableControllerProvider.notifier)
                            .syncFromCache(),
                      )
                    : ScrollConfiguration(
                        key: const ValueKey('timetable_view'),
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

class _NeedsLoginView extends StatelessWidget {
  final VoidCallback onSync;
  const _NeedsLoginView({super.key, required this.onSync});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_view_week_rounded,
                size: 64, color: colorScheme.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              '暂无课表数据',
              style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              '请先前往「设置」页面输入账号密码，\n然后点击下方「同步课表」按钮。',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
