
import 'package:infinite_calendar_view/infinite_calendar_view.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/course_occurrence.dart';
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

  effect(() {
    final s = timetable.state.value;

    // Only rebuild when the calendar-relevant fields actually change,
    // not on every isLoading / status / needsLogin toggle.
    final dataChanged = !identical(s.data, prevData);
    final termStartChanged = s.termStartMonday != prevTermStart;
    final weekChanged = s.currentTeachingWeek != prevTeachingWeek;

    if (!dataChanged && !termStartChanged && !weekChanged) return;
    if (s.data == null || s.termStartMonday == null) return;

    prevData = s.data;
    prevTermStart = s.termStartMonday;
    prevTeachingWeek = s.currentTeachingWeek;

    final occurrences = spreadOccurrencesByTeachingWeek(
      templates: s.data!.occurrences,
      termStartMonday: s.termStartMonday!,
      currentTeachingWeek: s.currentTeachingWeek,
    );

    final events =
        occurrences.map((o) => o.toInfiniteCalendarEvent()).toList();

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
