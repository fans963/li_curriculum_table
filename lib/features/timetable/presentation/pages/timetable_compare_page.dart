import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:li_curriculum_table/features/timetable/domain/services/teaching_week_scheduler.dart';
import 'package:li_curriculum_table/features/timetable/presentation/calendar_view/timetable_week_view.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/timetable_page_sections.dart';
import 'package:li_curriculum_table/features/timetable/presentation/providers/timetable_providers.dart';

// UI Constants
const double _pixelsPerMinute = 1.0;
const int _startDisplayHour = 8;
const int _endDisplayHour = 22;

class TimetableComparePage extends ConsumerStatefulWidget {
  const TimetableComparePage({super.key});

  @override
  ConsumerState<TimetableComparePage> createState() =>
      _TimetableComparePageState();
}

class _TimetableComparePageState extends ConsumerState<TimetableComparePage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(timetableControllerProvider.notifier);
      await notifier.restoreCachedTimetable();
      await notifier.restoreCachedTeachingWeekBaseline();
      await _restoreCachedCredentials();
    });
  }

  Future<void> _restoreCachedCredentials() async {
    try {
      final loadCachedCredentials = ref.read(loadCachedCredentialsUseCaseProvider);
      final cached = await loadCachedCredentials();
      if (!mounted || cached == null) return;
      _usernameController.text = cached.username;
      _passwordController.text = cached.password;
    } catch (_) {}
  }

  @override
  void dispose() {
    _nowTicker?.cancel();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = ref.watch(timetableControllerProvider);
    final displayWeek = state.displayWeek;

    return Scaffold(
        backgroundColor: colorScheme.surface,
        floatingActionButton: FloatingActionButton(
          onPressed: state.isLoading ? null : _triggerFetch,
          tooltip: state.isLoading ? '抓取中' : '刷新课表',
          child: state.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: TimetableControlPanel(
                  usernameController: _usernameController,
                  passwordController: _passwordController,
                  isLoading: state.isLoading,
                  currentTeachingWeek: state.currentTeachingWeek,
                  minWeek: state.minWeek,
                  maxWeek: state.maxWeek,
                  onTeachingWeekChanged: (week) {
                    // This is CALIBRATION: Fixes the anchor
                    ref.read(timetableControllerProvider.notifier).setCurrentTeachingWeek(week);
                    
                    // Also jump the calendar to that week
                    final anchor = state.termStartMonday;
                    if (anchor != null) {
                      final targetDate = anchor.add(Duration(days: (week - 1) * 7));
                      _calendarKey.currentState?.jumpToDate(targetDate);
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TimetableStatusBanner(
                        status: state.status,
                        isLoading: state.isLoading,
                        hasData: state.data != null,
                      ),
                    ),
                    if (state.data != null) ...[
                      const SizedBox(width: 8),
                      TimetableSummaryChip(
                        label: '正在查看',
                        value: '第$displayWeek周',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      children: [
                        // The Core Timetable View
                        Expanded(
                          child: ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context)
                                .copyWith(scrollbars: false),
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
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
    );
  }

  void _triggerFetch() {
    ref.read(timetableControllerProvider.notifier).fetchAndBuild(
          username: _usernameController.text,
          password: _passwordController.text,
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
