import 'dart:typed_data';

import 'package:li_curriculum_table/features/timetable/domain/entities/course_occurrence.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/course_mapper.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/section_time_mapping.dart';
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
  ProviderSubscription? _controllerSubscription;

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreCachedCredentials();
    });
    _controllerSubscription = ref.listenManual(timetableControllerProvider, (
      previous,
      next,
    ) {
      final occurrences = next.data?.occurrences ?? const <CourseOccurrence>[];
      _syncKalenderEvents(occurrences);
    });
  }

  @override
  void dispose() {
    _controllerSubscription?.close();
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
    final colorScheme = Theme.of(context).colorScheme;
    final state = ref.watch(timetableControllerProvider);
    final weekStart = mondayOfCurrentWeek();
    final occurrences = state.data?.occurrences ?? const <CourseOccurrence>[];
    final rows = state.data?.rows ?? const [];
    final networkLogs = state.data?.networkLogs ?? const <String>[];
    final hasCaptcha = (state.data?.captchaBytes ?? Uint8List(0)).isNotEmpty;
    final uniqueCourseCount = occurrences
        .map((e) => e.courseName.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .length;
    final totalHours = occurrences.fold<double>(
      0,
      (sum, e) => sum + e.end.difference(e.start).inMinutes / 60,
    );
    final summaryItems = <({String label, String value})>[
      (label: '原始行', value: '${rows.length}'),
      (label: '排课时段', value: '${occurrences.length}'),
      (label: '课程数', value: '$uniqueCourseCount'),
      (label: '总学时', value: totalHours.toStringAsFixed(1)),
    ];
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
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: _ControlPanel(
                  usernameController: _usernameController,
                  passwordController: _passwordController,
                  isLoading: state.isLoading,
                  onFetch: () {
                    ref
                        .read(timetableControllerProvider.notifier)
                        .fetchAndBuild(
                          username: _usernameController.text,
                          password: _passwordController.text,
                        );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _StatusBanner(
                  status: state.status,
                  isLoading: state.isLoading,
                  hasData: occurrences.isNotEmpty,
                ),
              ),
              if (occurrences.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: summaryItems
                        .map(
                          (item) => _SummaryChip(
                            label: item.label,
                            value: item.value,
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              if (hasCaptcha)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: _CaptchaPreview(
                    captchaBytes: state.data!.captchaBytes,
                    verifyCode: state.data!.verifyCode,
                  ),
                ),
              if (networkLogs.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: _NetworkLogPanel(logs: networkLogs),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: TabBarView(
                    children: [
                      occurrences.isEmpty
                          ? const _EmptyCalendarTip()
                          : sf.SfCalendar(
                              view: sf.CalendarView.week,
                              firstDayOfWeek: DateTime.monday,
                              initialDisplayDate: weekStart,
                              showDatePickerButton: true,
                              dataSource: _SfCourseDataSource(sfAppointments),
                              timeSlotViewSettings: sf.TimeSlotViewSettings(
                                startHour: timetableDisplayStartHour,
                                endHour: timetableDisplayEndHour,
                                timeIntervalHeight: 60,
                              ),
                            ),
                      occurrences.isEmpty
                          ? const _EmptyCalendarTip()
                          : k.CalendarView(
                              eventsController: _kalenderEventsController,
                              calendarController: _kalenderController,
                              viewConfiguration:
                                  k.MultiDayViewConfiguration.week(
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
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.usernameController,
    required this.passwordController,
    required this.isLoading,
    required this.onFetch,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onFetch;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 860;
        final usernameField = TextField(
          controller: usernameController,
          enabled: !isLoading,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: '账号',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        );
        final passwordField = TextField(
          controller: passwordController,
          enabled: !isLoading,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (!isLoading) {
              onFetch();
            }
          },
          decoration: const InputDecoration(
            labelText: '密码',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        );
        final fetchButton = SizedBox(
          height: 44,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : onFetch,
            icon: isLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            label: Text(isLoading ? '抓取中...' : '抓取并对比'),
          ),
        );

        if (wide) {
          return Row(
            children: [
              Expanded(child: usernameField),
              const SizedBox(width: 10),
              Expanded(child: passwordField),
              const SizedBox(width: 10),
              fetchButton,
            ],
          );
        }

        return Column(
          children: [
            usernameField,
            const SizedBox(height: 8),
            passwordField,
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: fetchButton),
          ],
        );
      },
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.status,
    required this.isLoading,
    required this.hasData,
  });

  final String status;
  final bool isLoading;
  final bool hasData;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isError = _looksLikeError(status);
    final backgroundColor = isError
        ? colorScheme.errorContainer
        : hasData
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final foregroundColor = isError
        ? colorScheme.onErrorContainer
        : hasData
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            isLoading
                ? Icons.hourglass_top_rounded
                : isError
                ? Icons.error_outline
                : Icons.info_outline,
            size: 18,
            color: foregroundColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              status,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _looksLikeError(String value) {
    const keywords = ['失败', '错误', '异常', '不可用', 'timeout', 'error'];
    final lower = value.toLowerCase();
    return keywords.any((k) => lower.contains(k));
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NetworkLogPanel extends StatelessWidget {
  const _NetworkLogPanel({required this.logs});

  final List<String> logs;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      collapsedBackgroundColor: colorScheme.surfaceContainerLow,
      backgroundColor: colorScheme.surfaceContainerLow,
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      title: Text(
        '网络日志 (${logs.length})',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 220),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(8),
          child: SingleChildScrollView(
            child: SelectableText(
              logs.join('\n'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyCalendarTip extends StatelessWidget {
  const _EmptyCalendarTip();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_note, size: 34, color: Colors.grey.shade500),
          const SizedBox(height: 8),
          Text('暂无课表数据', style: textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('请先输入账号密码并执行抓取。', style: textTheme.bodySmall),
        ],
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
