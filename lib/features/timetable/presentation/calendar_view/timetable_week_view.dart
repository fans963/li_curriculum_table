import 'package:infinite_calendar_view/infinite_calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:li_curriculum_table/features/timetable/presentation/calendar_view/calendar_view_adapter.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/course_occurrence.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/timetable_appointment_card.dart';
import 'package:li_curriculum_table/features/timetable/presentation/providers/timetable_providers.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/teaching_week_scheduler.dart';

class TimetableWeekView extends ConsumerStatefulWidget {
  const TimetableWeekView({
    super.key,
    required this.startHour,
    required this.endHour,
    required this.pixelsPerMinute,
    required this.now,
    this.onPageChange,
  });

  final int startHour;
  final int endHour;
  final double pixelsPerMinute;
  final DateTime now;
  final void Function(DateTime, int)? onPageChange;

  @override
  ConsumerState<TimetableWeekView> createState() => TimetableWeekViewState();
}

class TimetableWeekViewState extends ConsumerState<TimetableWeekView> {
  GlobalKey<EventsPlannerState> _plannerKey = GlobalKey<EventsPlannerState>();
  DateTime? _lastTermStart;

  @override
  void initState() {
    super.initState();
    _handleInitialJump();
  }

  void _handleInitialJump() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(timetableControllerProvider);
      final anchor = state.termStartMonday;
      if (anchor != null) {
        final targetDate = anchor.add(Duration(days: (state.displayWeek - 1) * 7));
        _plannerKey.currentState?.jumpToDate(targetDate);
      }
    });
  }

  void jumpToDate(DateTime date) {
    _plannerKey.currentState?.jumpToDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(infiniteTimetableEventControllerProvider);
    final timetableState = ref.watch(timetableControllerProvider);
    final termStart = timetableState.termStartMonday;

    if (termStart != _lastTermStart) {
      _lastTermStart = termStart;
      _plannerKey = GlobalKey<EventsPlannerState>();
      _handleInitialJump();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    const headerHeight = 64.0;

    // Dynamic boundaries relative to termStart (Week 1 Monday)
    final int maxPreviousDays = (1 - timetableState.minWeek) * 7;
    final int maxNextDays = (timetableState.maxWeek - 1) * 7;

    return Container(
      color: colorScheme.surface,
      child: KeyedSubtree(
        key: ValueKey(termStart),
        child: EventsPlanner(
          key: _plannerKey,
          controller: controller,
          daysShowed: 7,
          initialDate: termStart ?? DateTime.now().withoutTime,
          heightPerMinute: widget.pixelsPerMinute,
          initialVerticalScrollOffset: (widget.startHour * 60).toDouble() * widget.pixelsPerMinute,
          maxPreviousDays: maxPreviousDays,
          maxNextDays: maxNextDays,
          onDayChange: (date) {
          if (widget.onPageChange != null) {
            final anchor = termStart;
            if (anchor != null) {
              final week = calculateWeekIndex(date, anchor);
              widget.onPageChange!(date, week);
            }
          }
        },
        dayParam: DayParam(
          dayEventBuilder: (event, height, width, heightPerMinute) {
            final occurrence = event.data as CourseOccurrence?;
            if (occurrence == null) return const SizedBox.shrink();
            return buildTimetableAppointmentCard(
              context: context,
              occurrence: occurrence,
              now: widget.now,
            );
          },
        ),
        daysHeaderParam: DaysHeaderParam(
          daysHeaderHeight: headerHeight,
          dayHeaderBuilder: (date, isToday) {
            final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  bottom: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      weekdays[date.weekday - 1],
                      style: textTheme.labelMedium?.copyWith(
                        color: isToday ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: isToday ? BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ) : null,
                      child: Text(
                        '${date.day}',
                        style: textTheme.titleMedium?.copyWith(
                          color: isToday ? colorScheme.onPrimary : colorScheme.onSurface,
                          fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        timesIndicatorsParam: const TimesIndicatorsParam(
          timesIndicatorsWidth: 0,
        ),
      ),
    ));
  }
}
