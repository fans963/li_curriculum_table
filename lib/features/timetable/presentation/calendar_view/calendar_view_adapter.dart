
import 'package:flutter/painting.dart';
import 'package:infinite_calendar_view/infinite_calendar_view.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/course_occurrence.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/schedule_event.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/timetable_data.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/teaching_week_scheduler.dart';
import 'package:li_curriculum_table/features/timetable/presentation/state/timetable_controller.dart';
import 'package:signals/signals.dart';

/// Singleton EventsController for the Infinite Calendar.
final EventsController eventsController = _createEventsController();

EventsController _createEventsController() {
  final controller = EventsController();
  final timetable = sl<TimetableController>();

  // Track previous values to avoid redundant rebuilds
  TimetableData? prevData;
  DateTime? prevTermStart;
  int prevTeachingWeek = 0;
  List<ScheduleEvent> prevEvents = [];

  effect(() {
    final s = timetable.state.value;

    final dataChanged = !identical(s.data, prevData);
    final termStartChanged = s.termStartMonday != prevTermStart;
    final weekChanged = s.currentTeachingWeek != prevTeachingWeek;
    final eventsChanged = !identical(s.scheduleEvents, prevEvents);

    if (!dataChanged && !termStartChanged && !weekChanged && !eventsChanged) return;

    // Require at least termStartMonday OR schedule events — otherwise there's
    // nothing to show.
    if (s.termStartMonday == null && s.scheduleEvents.isEmpty) return;

    prevData = s.data;
    prevTermStart = s.termStartMonday;
    prevTeachingWeek = s.currentTeachingWeek;
    prevEvents = s.scheduleEvents;

    // Spread course occurrences only if we have data and a term start.
    final events = <Event>[];
    if (s.data != null && s.termStartMonday != null) {
      final occurrences = spreadOccurrencesByTeachingWeek(
        templates: s.data!.occurrences,
        termStartMonday: s.termStartMonday!,
        currentTeachingWeek: s.currentTeachingWeek,
      );
      events.addAll(occurrences.map((o) => o.toInfiniteCalendarEvent()));
    }

    // Inject schedule events — these always appear regardless of course data.
    for (final evt in s.scheduleEvents) {
      final occ = CourseOccurrence(
        courseName: evt.title,
        teacher: evt.teacher,
        location: evt.location,
        credit: '',
        courseType: '日程',
        stage: '',
        start: evt.start,
        end: evt.end,
        color: const Color(0xFF6750A4), // purple accent
      );
      events.add(occ.toInfiniteCalendarEvent());
    }

    controller.updateCalendarData((calendarData) {
      calendarData.clearAll();
      calendarData.addEvents(events);
    });
  });

  return controller;
}

extension CourseOccurrenceX on CourseOccurrence {
  /// Maps our domain entity to the infinite_calendar_view event entity.
  Event toInfiniteCalendarEvent() {
    return Event(
      startTime: start,
      endTime: end,
      title: courseName,
      description: location,
      data: this,
    );
  }
}
