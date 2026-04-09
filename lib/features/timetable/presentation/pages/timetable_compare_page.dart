import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart' as sf;

import 'package:li_curriculum_table/features/timetable/domain/entities/course_occurrence.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/timetable_data.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/teaching_week_scheduler.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/timetable_appointment_card.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/timetable_page_sections.dart';
import 'package:li_curriculum_table/features/timetable/presentation/providers/timetable_providers.dart';

const double _calendarStartHour = 7.84;
const double _calendarEndHour = 22;

class TimetableComparePage extends ConsumerStatefulWidget {
  const TimetableComparePage({super.key});

  @override
  ConsumerState<TimetableComparePage> createState() =>
      _TimetableComparePageState();
}

class _TimetableComparePageState extends ConsumerState<TimetableComparePage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  ProviderSubscription? _controllerSubscription;
  Timer? _nowTicker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _nowTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _now = DateTime.now();
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref
          .read(timetableControllerProvider.notifier)
          .restoreCachedTimetable();
      await ref
          .read(timetableControllerProvider.notifier)
          .restoreCachedTeachingWeekBaseline();
      await _restoreCachedCredentials();
    });

    _controllerSubscription = ref.listenManual(timetableControllerProvider, (
      previous,
      next,
    ) {
      // Reserved for future side-effects.
    });
  }

  Future<void> _restoreCachedCredentials() async {
    try {
      final loadCachedCredentials = ref.read(
        loadCachedCredentialsUseCaseProvider,
      );
      final cached = await loadCachedCredentials();
      if (!mounted || cached == null) {
        return;
      }

      _usernameController.text = cached.username;
      _passwordController.text = cached.password;
    } catch (_) {
      // Ignore cache-read failures to keep page startup resilient.
    }
  }

  @override
  void dispose() {
    _nowTicker?.cancel();
    _controllerSubscription?.close();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = ref.watch(timetableControllerProvider);
    final data = state.data;
    final currentTeachingWeek = state.currentTeachingWeek;

    final templateOccurrences = data?.occurrences ?? const <CourseOccurrence>[];
    final occurrences = spreadOccurrencesByTeachingWeek(
      templates: templateOccurrences,
      currentTeachingWeek: currentTeachingWeek,
    );
    final displayWeekStart = mondayOfDate(DateTime.now());

    final sfAppointments = occurrences
        .map(
          (occurrence) => sf.Appointment(
            startTime: occurrence.start,
            endTime: occurrence.end,
            subject: [
              occurrence.courseName,
              _formatOccurrenceTimeRange(occurrence),
              if (occurrence.teacher.trim().isNotEmpty)
                occurrence.teacher.trim(),
              if (occurrence.location.trim().isNotEmpty)
                occurrence.location.trim(),
            ].join('\n'),
            notes:
                '学分: ${occurrence.credit}\n类型: ${occurrence.courseType}\n阶段: ${occurrence.stage}\n周次: ${_formatWeekLabel(occurrence)}',
            color: resolveAppointmentTone(
              colorScheme,
              seedText: occurrence.courseName,
            ).background,
          ),
        )
        .toList(growable: false);

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
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: TimetableControlPanel(
                usernameController: _usernameController,
                passwordController: _passwordController,
                isLoading: state.isLoading,
                currentTeachingWeek: currentTeachingWeek,
                onTeachingWeekChanged: (week) {
                  ref
                      .read(timetableControllerProvider.notifier)
                      .setCurrentTeachingWeek(week);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TimetableStatusBanner(
                status: state.status,
                isLoading: state.isLoading,
                hasData: occurrences.isNotEmpty,
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
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: occurrences.isEmpty
                      ? const TimetableEmptyCalendarTip()
                      : sf.SfCalendar(
                          key: ValueKey(
                            'sf-${currentTeachingWeek}-${occurrences.length}',
                          ),
                          view: sf.CalendarView.week,
                          firstDayOfWeek: DateTime.monday,
                          initialDisplayDate: displayWeekStart,
                          showCurrentTimeIndicator: true,
                          showDatePickerButton: true,
                          dataSource: _SfCourseDataSource(sfAppointments),
                          appointmentBuilder: (context, details) {
                            return buildTimetableAppointmentCard(
                              context: context,
                              details: details,
                              now: _now,
                            );
                          },
                          timeSlotViewSettings: const sf.TimeSlotViewSettings(
                            startHour: _calendarStartHour,
                            endHour: _calendarEndHour,
                            timeInterval: Duration(minutes: 10),
                            timeFormat: 'HH:mm',
                          ),
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
    ref
        .read(timetableControllerProvider.notifier)
        .fetchAndBuild(
          username: _usernameController.text,
          password: _passwordController.text,
        );
  }
}

class _SfCourseDataSource extends sf.CalendarDataSource {
  _SfCourseDataSource(List<sf.Appointment> source) {
    appointments = source;
  }
}

String _formatWeekLabel(CourseOccurrence occurrence) {
  final weekText = occurrence.weekText.trim();
  if (weekText.isNotEmpty) {
    return weekText;
  }

  final startWeek = occurrence.startWeek;
  final endWeek = occurrence.endWeek;
  if (startWeek == null || endWeek == null) {
    return '周次未知';
  }

  if (startWeek == endWeek) {
    return '$startWeek周';
  }
  return '$startWeek-$endWeek周';
}

String _formatOccurrenceTimeRange(CourseOccurrence occurrence) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  final start =
      '${twoDigits(occurrence.start.hour)}:${twoDigits(occurrence.start.minute)}';
  final end =
      '${twoDigits(occurrence.end.hour)}:${twoDigits(occurrence.end.minute)}';
  return '$start-$end';
}
