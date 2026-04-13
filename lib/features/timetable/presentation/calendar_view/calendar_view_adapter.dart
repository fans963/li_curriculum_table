
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/course_occurrence.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/teaching_week_scheduler.dart';
import 'package:li_curriculum_table/features/timetable/presentation/state/timetable_controller.dart';
import 'package:infinite_calendar_view/infinite_calendar_view.dart';


/// Provider for the Infinite Calendar EventsController.
final infiniteTimetableEventControllerProvider = Provider<EventsController>((ref) {
  final controller = EventsController();
  
  // Listen to the main timetable state and update events automatically
  ref.listen(timetableControllerProvider, (previous, next) {
    if (next.data != null && next.termStartMonday != null) {
      final occurrences = spreadOccurrencesByTeachingWeek(
        templates: next.data!.occurrences,
        termStartMonday: next.termStartMonday!,
        currentTeachingWeek: next.currentTeachingWeek,
      );
      
      final events = occurrences.map((o) => o.toInfiniteCalendarEvent()).toList();
      
      controller.updateCalendarData((calendarData) {
        calendarData.clearAll();
        calendarData.addEvents(events);
      });
    }
  }, fireImmediately: true);

  return controller;
});

extension CourseOccurrenceX on CourseOccurrence {

  /// Maps our domain entity to the infinite_calendar_view event entity.
  Event toInfiniteCalendarEvent() {
    return Event(
      startTime: start,
      endTime: end,
      title: courseName,
      description: location,
      data: this, // Essential for the UI builder to access the occurrence
    );
  }
}
