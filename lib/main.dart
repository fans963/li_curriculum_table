import 'package:curriculum_table/src/table_getter/pachong.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kalender/kalender.dart' as k;
import 'package:syncfusion_flutter_calendar/calendar.dart' as sf;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TimetableCompareApp());
}

class TimetableCompareApp extends StatelessWidget {
  const TimetableCompareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '课表组件对比',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const TimetableComparePage(),
    );
  }
}

class TimetableComparePage extends StatefulWidget {
  const TimetableComparePage({super.key});

  @override
  State<TimetableComparePage> createState() => _TimetableComparePageState();
}

class _TimetableComparePageState extends State<TimetableComparePage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  final k.DefaultEventsController _kalenderEventsController =
      k.DefaultEventsController();
  final k.CalendarController _kalenderController = k.CalendarController();

  List<CourseOccurrence> _occurrences = <CourseOccurrence>[];
  List<sf.Appointment> _sfAppointments = <sf.Appointment>[];
  Uint8List? _captchaPreviewBytes;
  String? _recognizedCaptcha;
  bool _loading = false;
  String _status = '请输入账号密码并点击“抓取并对比”。';

  static const String _proxyBaseUrl =
      'https://project-k70ln.vercel.app/';
  static const String _loginBaseUrl = 'http://202.119.81.112:8080';
  static const String _targetUrl =
      'http://202.119.81.112:9080/njlgdx/xskb/xskb_list.do?Ves632DSdyV=NEW_XSD_PYGL';

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _kalenderEventsController.dispose();
    _kalenderController.dispose();
    super.dispose();
  }

  Future<void> _fetchAndBuild() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _status = '账号和密码不能为空。';
      });
      return;
    }

    setState(() {
      _loading = true;
      _recognizedCaptcha = null;
      _status = '正在爬取课表并生成对比视图...';
    });

    final directClient = PachongClient(
      loginBaseUrl: _loginBaseUrl,
      targetUrl: _targetUrl,
      proxyBaseUrl: _proxyBaseUrl,
    );

    try {
      final result = await directClient.loginAndFetchSchedule(
        username: username,
        password: password,
      );

      final courseRows = result.rows
          .map(CourseRow.fromParsed)
          .whereType<CourseRow>()
          .toList(growable: false);
      final occurrences = buildCourseOccurrences(courseRows);

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

      if (!mounted) {
        return;
      }
      setState(() {
        _occurrences = occurrences;
        _sfAppointments = sfAppointments;
        _captchaPreviewBytes = result.captchaBytes.isEmpty
            ? null
            : result.captchaBytes;
        _recognizedCaptcha = result.verifyCode;
        _status = '抓取完成: 表格行=${result.rows.length}，可展示时段=${occurrences.length}';
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      final err = e.toString();
      var message = '抓取失败: $e';
      final loweredErr = err.toLowerCase();
      final isConnRefused =
          RegExp(r'errno\s*[:=]\s*111\b').hasMatch(err) ||
          loweredErr.contains('connection refused') ||
          err.contains('errno=111') ||
          err.contains('errno:111');
      if (isConnRefused) {
        final modeText = kIsWeb ? 'Web 代理模式' : '桌面/移动直连模式';
        message =
            '抓取失败: 连接被拒绝（errno=111）。\n'
            '当前模式: $modeText\n'
          '代理地址: $_proxyBaseUrl\n'
            '当前登录地址: $_loginBaseUrl\n'
            '当前课表地址: $_targetUrl\n'
            '请确认手机网络可访问这些地址（通常需校园网或校内VPN）。';
      }
      setState(() {
        _status = message;
      });
    } finally {
      await directClient.close();
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekStart = mondayOfCurrentWeek();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('课表组件对比（自动爬取）'),
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
                      onPressed: _loading ? null : _fetchAndBuild,
                      child: Text(_loading ? '抓取中...' : '抓取并对比'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _occurrences.isEmpty
                      ? const Center(child: Text('暂无课表数据，先执行抓取'))
                      : sf.SfCalendar(
                          view: sf.CalendarView.week,
                          firstDayOfWeek: DateTime.monday,
                          initialDisplayDate: weekStart,
                          showDatePickerButton: true,
                          dataSource: _SfCourseDataSource(_sfAppointments),
                          timeSlotViewSettings: const sf.TimeSlotViewSettings(
                            startHour: 8,
                            endHour: 22,
                            timeIntervalHeight: 60,
                          ),
                        ),
                  _occurrences.isEmpty
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
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          e.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          e.subtitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
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

class CourseRow {
  const CourseRow({
    required this.courseId,
    required this.order,
    required this.courseName,
    required this.teacher,
    required this.timeText,
    required this.credit,
    required this.location,
    required this.courseType,
    required this.stage,
  });

  final String courseId;
  final String order;
  final String courseName;
  final String teacher;
  final String timeText;
  final String credit;
  final String location;
  final String courseType;
  final String stage;

  static CourseRow? fromParsed(List<String> row) {
    if (row.length < 10) {
      return null;
    }

    return CourseRow(
      courseId: row[1],
      order: row[2],
      courseName: row[3],
      teacher: row[4],
      timeText: row[5],
      credit: row[6],
      location: row[7],
      courseType: row[8],
      stage: row[9],
    );
  }
}

class CourseOccurrence {
  const CourseOccurrence({
    required this.courseName,
    required this.teacher,
    required this.location,
    required this.credit,
    required this.courseType,
    required this.stage,
    required this.start,
    required this.end,
    required this.color,
  });

  final String courseName;
  final String teacher;
  final String location;
  final String credit;
  final String courseType;
  final String stage;
  final DateTime start;
  final DateTime end;
  final Color color;
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

DateTime mondayOfCurrentWeek() {
  final now = DateTime.now();
  return DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: now.weekday - DateTime.monday));
}

List<CourseOccurrence> buildCourseOccurrences(List<CourseRow> rows) {
  final weekStart = mondayOfCurrentWeek();
  final reg = RegExp(r'星期([一二三四五六日天])\((\d{2})-(\d{2})小节\)');
  final dedup = <String>{};
  final result = <CourseOccurrence>[];

  for (final row in rows) {
    final matches = reg.allMatches(row.timeText).toList(growable: false);
    for (var i = 0; i < matches.length; i++) {
      final m = matches[i];
      final weekday = _weekdayFromChinese(m.group(1)!);
      final startSection = int.parse(m.group(2)!);
      final endSection = int.parse(m.group(3)!);
      final startClock = _sectionStartClock[startSection];
      final endClock = _sectionEndClock[endSection];
      if (weekday == null || startClock == null || endClock == null) {
        continue;
      }

      final day = weekStart.add(Duration(days: weekday - DateTime.monday));
      final start = DateTime(
        day.year,
        day.month,
        day.day,
        startClock.$1,
        startClock.$2,
      );
      final end = DateTime(
        day.year,
        day.month,
        day.day,
        endClock.$1,
        endClock.$2,
      );

      final key =
          '${row.courseId}|${row.courseName}|$weekday|$startSection|$endSection';
      if (!dedup.add(key)) {
        continue;
      }

      result.add(
        CourseOccurrence(
          courseName: row.courseName,
          teacher: row.teacher,
          location: _locationAt(row.location, i),
          credit: row.credit,
          courseType: row.courseType,
          stage: row.stage,
          start: start,
          end: end,
          color: _colorFromCourseId(row.courseId),
        ),
      );
    }
  }

  result.sort((a, b) => a.start.compareTo(b.start));
  return result;
}

String _locationAt(String raw, int index) {
  final items = raw
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList(growable: false);
  if (items.isEmpty) {
    return '';
  }
  if (index < items.length) {
    return items[index];
  }
  return items.last;
}

Color _colorFromCourseId(String courseId) {
  const palette = <Color>[
    Color(0xFF00695C),
    Color(0xFF2E7D32),
    Color(0xFFEF6C00),
    Color(0xFF6A1B9A),
    Color(0xFF1565C0),
    Color(0xFFAD1457),
    Color(0xFF5D4037),
    Color(0xFF00838F),
    Color(0xFF283593),
    Color(0xFF37474F),
  ];

  var hash = 0;
  for (final code in courseId.codeUnits) {
    hash = (hash * 31 + code) & 0x7fffffff;
  }
  return palette[hash % palette.length];
}

int? _weekdayFromChinese(String c) {
  switch (c) {
    case '一':
      return DateTime.monday;
    case '二':
      return DateTime.tuesday;
    case '三':
      return DateTime.wednesday;
    case '四':
      return DateTime.thursday;
    case '五':
      return DateTime.friday;
    case '六':
      return DateTime.saturday;
    case '日':
    case '天':
      return DateTime.sunday;
    default:
      return null;
  }
}

const Map<int, (int, int)> _sectionStartClock = <int, (int, int)>{
  1: (8, 0),
  2: (8, 50),
  3: (9, 50),
  4: (10, 40),
  5: (11, 30),
  6: (14, 0),
  7: (14, 50),
  8: (15, 50),
  9: (16, 40),
  10: (17, 30),
  11: (19, 0),
  12: (19, 50),
  13: (20, 40),
  14: (21, 30),
};

const Map<int, (int, int)> _sectionEndClock = <int, (int, int)>{
  1: (8, 45),
  2: (9, 35),
  3: (10, 35),
  4: (11, 25),
  5: (12, 15),
  6: (14, 45),
  7: (15, 35),
  8: (16, 35),
  9: (17, 25),
  10: (18, 15),
  11: (19, 45),
  12: (20, 35),
  13: (21, 25),
  14: (22, 15),
};
