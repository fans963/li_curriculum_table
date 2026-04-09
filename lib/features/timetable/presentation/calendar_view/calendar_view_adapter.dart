import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/course_occurrence.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/teaching_week_scheduler.dart';
import 'package:li_curriculum_table/features/timetable/presentation/providers/timetable_providers.dart';
import 'package:infinite_calendar_view/infinite_calendar_view.dart';

/// Provider for the Calendar EventController.
/// This ensures the controller is decoupled from the page and can be tested or reused.
final timetableEventControllerProvider = Provider<EventController<CourseOccurrence>>((ref) {
  final controller = EventController<CourseOccurrence>();
  
  // Listen to the main timetable state and update events automatically
  ref.listen(timetableControllerProvider, (previous, next) {
    if (next.data != null && next.termStartMonday != null) {
      final occurrences = spreadOccurrencesByTeachingWeek(
        templates: next.data!.occurrences,
        termStartMonday: next.termStartMonday!,
        currentTeachingWeek: next.currentTeachingWeek,
      );
      
      final events = occurrences.map((o) => o.toCalendarEventData()).toList();
      
      controller.removeWhere((_) => true); // Clear existing
      controller.addAll(events);
    }
  }, fireImmediately: true);

  ref.onDispose(() => controller.dispose());
  return controller;
});

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
  /// Maps our domain entity to the calendar_view event entity.
  CalendarEventData<CourseOccurrence> toCalendarEventData() {
    return CalendarEventData<CourseOccurrence>(
      date: start,
      startTime: start,
      endTime: end,
      title: courseName,
      description: location,
      event: this, // Store the original object for custom builders
    );
  }

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
