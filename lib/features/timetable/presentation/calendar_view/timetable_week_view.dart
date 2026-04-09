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
          initialVerticalScrollOffset: 480 * widget.pixelsPerMinute,
          minVerticalScrollOffset: 480 * widget.pixelsPerMinute,
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
          dayTopPadding: 0,
          dayColor: colorScheme.surface,
          dayEventBuilder: (event, height, width, heightPerMinute) {
            final occurrence = event.data as CourseOccurrence?;
            if (occurrence == null) return const SizedBox.shrink();
            return buildTimetableAppointmentCard(
              context: context,
              occurrence: occurrence,
              now: widget.now,
            );
          },
          dayCustomPainter: (heightPerMinute, isToday) => VerticalDashedSeparatorPainter(
            color: colorScheme.outlineVariant,
          ),
        ),
        offTimesParam: OffTimesParam(
          offTimesColor: colorScheme.surface,
        ),
        fullDayParam: const FullDayParam(
          fullDayEventsBarVisibility: false,
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
                  right: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
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
        timesIndicatorsParam: TimesIndicatorsParam(
          timesIndicatorsWidth: 0,
          timesIndicatorsCustomPainter: (_) => EmptyPainter(),
        ),
        currentHourIndicatorParam: CurrentHourIndicatorParam(
          currentHourIndicatorLineVisibility: true,
          currentHourIndicatorHourVisibility: false,
          currentHourIndicatorCustomPainter: (heightPerMinute, isToday) {
            return CurrentTimeIndicatorPainter(
              heightPerMinute: heightPerMinute,
              isToday: isToday,
              color: colorScheme.primary,
              now: widget.now,
            );
          },
        ),
        pinchToZoomParam: const PinchToZoomParameters(
          pinchToZoom: false,
        ),
      ),
    ));
  }
}

class VerticalDashedSeparatorPainter extends CustomPainter {
  final Color color;
  final double dashHeight;
  final double dashSpace;

  VerticalDashedSeparatorPainter({
    required this.color,
    this.dashHeight = 4.0,
    this.dashSpace = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    double y = 0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(size.width, y),
        Offset(size.width, y + dashHeight),
        paint,
      );
      y += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant VerticalDashedSeparatorPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class EmptyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {}
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class CurrentTimeIndicatorPainter extends CustomPainter {
  final double heightPerMinute;
  final bool isToday;
  final Color color;
  final DateTime now;

  CurrentTimeIndicatorPainter({
    required this.heightPerMinute,
    required this.isToday,
    required this.color,
    required this.now,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isToday) return;

    final absoluteMinutes = now.hour * 60 + now.minute;
    final y = absoluteMinutes * heightPerMinute;

    final paint = Paint()
      ..color = color.withOpacity(0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw the bright horizontal line indicating current time across the card zone
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);

    // Draw an elegant indicator dot on the left side
    final circlePaintOuter = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(4, y), 5.0, circlePaintOuter);

    final circlePaintInner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(4, y), 2.0, circlePaintInner);
  }

  @override
  bool shouldRepaint(covariant CurrentTimeIndicatorPainter oldDelegate) {
    return oldDelegate.heightPerMinute != heightPerMinute ||
        oldDelegate.isToday != isToday ||
        oldDelegate.now != now ||
        oldDelegate.color != color;
  }
}
