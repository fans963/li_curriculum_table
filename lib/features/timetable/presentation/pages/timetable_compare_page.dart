import 'dart:typed_data';

import 'package:li_curriculum_table/features/timetable/domain/entities/course_occurrence.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/course_mapper.dart';
import 'package:li_curriculum_table/features/timetable/presentation/providers/timetable_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalender/kalender.dart' as k;
import 'package:syncfusion_flutter_calendar/calendar.dart' as sf;

class TimetableComparePage extends ConsumerStatefulWidget {
  const TimetableComparePage({super.key});

  @override
  ConsumerState<TimetableComparePage> createState() =>
      _TimetableComparePageState();
}

class _TimetableComparePageState extends ConsumerState<TimetableComparePage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final k.DefaultEventsController _kalenderEventsController =
      k.DefaultEventsController();
  final k.CalendarController _kalenderController = k.CalendarController();

  @override
  void initState() {
    super.initState();
    ref.listenManual(timetableControllerProvider, (previous, next) {
      final occurrences = next.data?.occurrences ?? const <CourseOccurrence>[];
      _syncKalenderEvents(occurrences);
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _kalenderEventsController.dispose();
    _kalenderController.dispose();
    super.dispose();
  }

  void _syncKalenderEvents(List<CourseOccurrence> occurrences) {
    _kalenderEventsController
      ..clearEvents()
      ..addEvents(
        occurrences
            .map(
              (e) => CourseKalenderEvent(
                dateTimeRange: DateTimeRange(start: e.start, end: e.end),
                title: e.courseName,
                subtitle:
                    '${e.teacher} · ${e.location.isEmpty ? '未填教室' : e.location}',
                color: e.color,
              ),
            )
            .toList(growable: false),
      );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timetableControllerProvider);
    final weekStart = mondayOfCurrentWeek();
    final occurrences = state.data?.occurrences ?? const <CourseOccurrence>[];
    final sfAppointments = occurrences
        .map(
          (e) => sf.Appointment(
            startTime: e.start,
            endTime: e.end,
            subject:
                '${e.courseName}\n${e.teacher}  ${e.location.isEmpty ? '未填教室' : e.location}',
            color: e.color,
            notes: '学分:${e.credit}  ${e.courseType}  ${e.stage}',
          ),
        )
        .toList(growable: false);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('课表组件对比'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Syncfusion'),
              Tab(text: 'Kalender'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Column(
                children: [
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: '账号',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '密码',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state.isLoading
                          ? null
                          : () {
                              ref
                                  .read(timetableControllerProvider.notifier)
                                  .fetchAndBuild(
                                    username: _usernameController.text,
                                    password: _passwordController.text,
                                  );
                            },
                      child: Text(state.isLoading ? '抓取中...' : '抓取并对比'),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if ((state.data?.captchaBytes ?? Uint8List(0)).isNotEmpty)
                    _CaptchaPreview(
                      captchaBytes: state.data!.captchaBytes,
                      verifyCode: state.data!.verifyCode,
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      state.status,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  if ((state.data?.networkLogs ?? const <String>[]).isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 160),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          (state.data?.networkLogs ?? const <String>[]).join('\n'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  occurrences.isEmpty
                      ? const Center(child: Text('暂无课表数据，先执行抓取'))
                      : sf.SfCalendar(
                          view: sf.CalendarView.week,
                          firstDayOfWeek: DateTime.monday,
                          initialDisplayDate: weekStart,
                          showDatePickerButton: true,
                          dataSource: _SfCourseDataSource(sfAppointments),
                          timeSlotViewSettings: const sf.TimeSlotViewSettings(
                            startHour: 8,
                            endHour: 22,
                            timeIntervalHeight: 60,
                          ),
                        ),
                  occurrences.isEmpty
                      ? const Center(child: Text('暂无课表数据，先执行抓取'))
                      : k.CalendarView(
                          eventsController: _kalenderEventsController,
                          calendarController: _kalenderController,
                          viewConfiguration: k.MultiDayViewConfiguration.week(
                            initialDateTime: weekStart,
                          ),
                          header: const k.CalendarHeader(),
                          body: k.CalendarBody(
                            multiDayTileComponents: k.TileComponents(
                              tileBuilder: (event, _) {
                                final e = event as CourseKalenderEvent;
                                return Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: e.color.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: DefaultTextStyle(
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        final h = constraints.maxHeight;
                                        final showSubtitle = h >= 34;
                                        final titleLines = h < 26 ? 1 : 2;

                                        return ClipRect(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                e.title,
                                                maxLines: titleLines,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (showSubtitle) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  e.subtitle,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptchaPreview extends StatelessWidget {
  const _CaptchaPreview({required this.captchaBytes, required this.verifyCode});

  final Uint8List captchaBytes;
  final String verifyCode;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('本次抓取验证码预览:'),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.all(4),
            child: Image.memory(
              captchaBytes,
              width: 124,
              height: 44,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              filterQuality: FilterQuality.none,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('OCR识别结果: $verifyCode'),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class CourseKalenderEvent extends k.CalendarEvent {
  CourseKalenderEvent({
    required super.dateTimeRange,
    required this.title,
    required this.subtitle,
    required this.color,
    super.interaction,
  });

  final String title;
  final String subtitle;
  final Color color;

  @override
  CourseKalenderEvent copyWith({
    DateTimeRange? dateTimeRange,
    k.EventInteraction? interaction,
  }) {
    final updated = CourseKalenderEvent(
      dateTimeRange: dateTimeRange ?? this.dateTimeRange,
      interaction: interaction ?? this.interaction,
      title: title,
      subtitle: subtitle,
      color: color,
    );
    updated.id = id;
    return updated;
  }
}

class _SfCourseDataSource extends sf.CalendarDataSource {
  _SfCourseDataSource(List<sf.Appointment> source) {
    appointments = source;
  }
}
