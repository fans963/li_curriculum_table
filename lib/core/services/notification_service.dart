import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:li_curriculum_table/features/exam_schedule/domain/models/exam.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/course_occurrence.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/teaching_week_scheduler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Channel IDs
  static const _courseChannelId = 'course_reminders';
  static const _examChannelId = 'exam_reminders';
  static const _gradeChannelId = 'grade_updates';

  // Notification ID ranges
  // Course: 10000 - 19999
  // Exam 1-day: 20000 - 20999
  // Exam 2-hour: 21000 - 21999

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open',
    );
    final initSettings = InitializationSettings(
      android: kIsWeb ? null : androidSettings,
      linux: kIsWeb ? null : linuxSettings,
    );

    await _plugin.initialize(settings: initSettings);

    // Create notification channels
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _courseChannelId,
          '课程提醒',
          description: '课前20分钟提醒',
          importance: Importance.high,
        ));

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _examChannelId,
          '考试提醒',
          description: '考前1天和2小时提醒',
          importance: Importance.high,
        ));

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _gradeChannelId,
          '成绩通知',
          description: '新成绩发布时提醒',
          importance: Importance.high,
        ));
  }

  /// Request notification permission (Android 13+). Other platforms return true.
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true; // Non-Android: no permission needed
    final granted = await android.requestNotificationsPermission();
    return granted ?? false;
  }

  /// Show an immediate notification for newly published grades.
  /// [newCourses] is the list of new course names.
  Future<void> notifyNewGrades(List<String> newCourses) async {
    if (newCourses.isEmpty) return;

    final title = '🎉 新成绩发布';
    final body = newCourses.length <= 3
        ? '新出成绩：${newCourses.join('、')}'
        : '新出${newCourses.length}门成绩：${newCourses.take(3).join('、')}等';

    await _plugin.show(
      id: 30000,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _gradeChannelId,
          '成绩通知',
          channelDescription: '新成绩发布时提醒',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
      ),
    );

    if (kDebugMode) {
      print('[NotificationService] New grade notification: ${newCourses.join(', ')}');
    }
  }

  /// Schedule course reminders for the upcoming week.
  /// Calls [spreadOccurrencesByTeachingWeek] to anchor occurrences to real dates,
  /// then schedules a notification 20 minutes before each class.
  Future<void> scheduleCourseReminders({
    required List<CourseOccurrence> templates,
    required DateTime termStartMonday,
    required int currentTeachingWeek,
  }) async {
    // Cancel all existing course notifications
    await _cancelNotificationsInRange(10000, 19999);

    if (templates.isEmpty) return;

    // Spread occurrences for current and next week
    final allOccurrences = <CourseOccurrence>[];
    for (var week = currentTeachingWeek;
        week <= currentTeachingWeek + 1;
        week++) {
      if (week < 1) continue;
      allOccurrences.addAll(spreadOccurrencesByTeachingWeek(
        templates: templates,
        termStartMonday: termStartMonday,
        currentTeachingWeek: week,
      ));
    }

    final now = DateTime.now();
    var scheduled = 0;

    for (final occ in allOccurrences) {
      // Only schedule future occurrences
      final reminderTime = occ.start.subtract(const Duration(minutes: 20));
      if (reminderTime.isBefore(now)) continue;

      // Skip if more than 7 days away (to avoid excessive notifications)
      if (reminderTime.difference(now).inDays > 7) continue;

      final id = _courseNotificationId(occ);
      final body = '${occ.courseName}\n${occ.teacher} · ${occ.location}';

      await _scheduleNotification(
        id: id,
        title: '📋 20分钟后有课',
        body: body,
        scheduledTime: reminderTime,
        channelId: _courseChannelId,
      );
      scheduled++;
    }

    if (kDebugMode) {
      print('[NotificationService] Scheduled $scheduled course reminders');
    }
  }

  /// Schedule a notification for a custom schedule event at the specified time.
  /// Uses notification ID range 30000-39999.
  Future<void> scheduleEventReminder({
    required int id,
    required String title,
    required String body,
    required DateTime notifyTime,
  }) async {
    final reminderTime = notifyTime.isBefore(DateTime.now())
        ? notifyTime.add(const Duration(days: 1))
        : notifyTime;

    await _scheduleNotification(
      id: 30000 + (id % 10000),
      title: title,
      body: body,
      scheduledTime: reminderTime,
      channelId: _courseChannelId,
    );
  }

  /// Cancel a schedule event notification by its ID.
  Future<void> cancelEventReminder(int id) async {
    await _plugin.cancel(id: 30000 + (id % 10000));
  }

  /// Schedule exam reminders: 1 day before and 2 hours before each exam.
  Future<void> scheduleExamReminders(List<ExamEntity> exams) async {
    // Cancel all existing exam notifications
    await _cancelNotificationsInRange(20000, 21999);

    final now = DateTime.now();
    var scheduled = 0;

    for (var i = 0; i < exams.length; i++) {
      final exam = exams[i];
      if (exam.isExpired) continue;

      final startTime = exam.startTime;
      if (startTime == null) continue;

      // 1-day reminder
      final oneDayBefore = startTime.subtract(const Duration(days: 1));
      if (oneDayBefore.isAfter(now)) {
        await _scheduleNotification(
          id: 20000 + i,
          title: '📝 明天有考试',
          body: '${exam.courseName}\n${exam.timeRange} · ${exam.location}',
          scheduledTime: oneDayBefore,
          channelId: _examChannelId,
        );
        scheduled++;
      }

      // 2-hour reminder
      final twoHoursBefore = startTime.subtract(const Duration(hours: 2));
      if (twoHoursBefore.isAfter(now)) {
        await _scheduleNotification(
          id: 21000 + i,
          title: '⏰ 2小时后考试',
          body:
              '${exam.courseName}\n${exam.timeRange} · ${exam.location} · 座位${exam.seatNumber}',
          scheduledTime: twoHoursBefore,
          channelId: _examChannelId,
        );
        scheduled++;
      }
    }

    if (kDebugMode) {
      print('[NotificationService] Scheduled $scheduled exam reminders');
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String channelId,
  }) async {
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzTime,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId == _courseChannelId ? '课程提醒' : '考试提醒',
          channelDescription:
              channelId == _courseChannelId ? '课前20分钟提醒' : '考前1天和2小时提醒',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Generate a deterministic notification ID from course occurrence.
  int _courseNotificationId(CourseOccurrence occ) {
    final hash =
        '${occ.courseName}_${occ.start.weekday}_${occ.start.hour}_${occ.start.minute}'
            .hashCode
            .toUnsigned(31);
    return 10000 + (hash % 10000);
  }

  /// Cancel all notifications with IDs in [start, end].
  Future<void> _cancelNotificationsInRange(int start, int end) async {
    for (var id = start; id <= end; id++) {
      await _plugin.cancel(id: id);
    }
  }

  /// Cancel all scheduled notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
