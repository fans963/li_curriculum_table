import 'package:infinite_calendar_view/infinite_calendar_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loading_indicator_m3e/loading_indicator_m3e.dart';
import 'package:signals/signals_flutter.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/timetable/presentation/calendar_view/calendar_view_adapter.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/course_occurrence.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/timetable_appointment_card.dart';
import 'package:li_curriculum_table/features/timetable/presentation/state/timetable_controller.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/teaching_week_scheduler.dart';

class TimetableWeekView extends SignalStatefulWidget {
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
  State<TimetableWeekView> createState() => TimetableWeekViewState();
}

class TimetableWeekViewState extends State<TimetableWeekView> {
  GlobalKey<EventsPlannerState> _plannerKey = GlobalKey<EventsPlannerState>();
  DateTime? _lastTermStart;

  @override
  void initState() {
    super.initState();
    _handleInitialJump();
  }

  void _handleInitialJump() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = sl<TimetableController>().state.value;
      final anchor = state.termStartMonday;
      if (anchor != null) {
        final targetDate = anchor.add(
          Duration(days: (state.displayWeek - 1) * 7),
        );
        _plannerKey.currentState?.jumpToDate(targetDate);
      }
    });
  }

  void jumpToDate(DateTime date) {
    _plannerKey.currentState?.jumpToDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final controller = eventsController;
    final timetableState = sl<TimetableController>().state.value;
      final termStart = timetableState.termStartMonday;
      final weeklyScroll = sl<SettingsController>().state.value.weeklyScroll;

      if (termStart != _lastTermStart) {
        _lastTermStart = termStart;
        _plannerKey = GlobalKey<EventsPlannerState>();
        _handleInitialJump();
      }

      final ds = sl<SettingsController>().state.value.designStyle;
      final isCupertino = AdaptiveStyle.isCupertino(ds);
      final colorScheme = Theme.of(context).colorScheme;
      final textTheme = Theme.of(context).textTheme;
      const headerHeight = 64.0;

      // Adaptive colors — use Cupertino system colors when in Cupertino mode
      final surfaceColor = isCupertino
          ? CupertinoColors.systemGroupedBackground.resolveFrom(context)
          : colorScheme.surface;
      final cardColor = isCupertino
          ? CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context)
          : colorScheme.surface;
      final separatorColor = isCupertino
          ? CupertinoColors.separator.resolveFrom(context)
          : colorScheme.outlineVariant;
      final primaryColor = isCupertino
          ? CupertinoColors.systemBlue.resolveFrom(context)
          : colorScheme.primary;
      final onSurfaceColor = isCupertino
          ? CupertinoColors.label.resolveFrom(context)
          : colorScheme.onSurface;
      final onSurfaceVariantColor = isCupertino
          ? CupertinoColors.secondaryLabel.resolveFrom(context)
          : colorScheme.onSurfaceVariant;
      final onPrimaryColor = isCupertino
          ? CupertinoColors.white
          : colorScheme.onPrimary;

      // Dynamic boundaries relative to termStart (Week 1 Monday)
      final int maxPreviousDays = ((1 - timetableState.minWeek) * 7).toInt();
      final int maxNextDays = ((timetableState.maxWeek - 1) * 7).toInt();

      return LayoutBuilder(
        builder: (context, constraints) {
          // Guard against unstable/negative constraints during initialization
          if (constraints.maxWidth < 120 || constraints.maxHeight < 100) {
            return Container(
              color: surfaceColor,
              child: Center(
                child: isCupertino
                    ? const CupertinoActivityIndicator()
                    : const LoadingIndicatorM3E(),
              ),
            );
          }

          return Container(
            color: surfaceColor,
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
                horizontalScrollPhysics: weeklyScroll
                    ? const PageScrollPhysics()
                    : const BouncingScrollPhysics(),
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
                  dayColor: surfaceColor,
                  dayEventBuilder: (event, height, width, heightPerMinute) {
                    final occurrence = event.data as CourseOccurrence?;
                    if (occurrence == null) return const SizedBox.shrink();
                    return buildTimetableAppointmentCard(
                      context: context,
                      occurrence: occurrence,
                      now: widget.now,
                    );
                  },
                  dayCustomPainter: (heightPerMinute, isToday) =>
                      VerticalDashedSeparatorPainter(
                        color: separatorColor,
                      ),
                ),
                offTimesParam: OffTimesParam(offTimesColor: surfaceColor),
                fullDayParam: const FullDayParam(
                  fullDayEventsBarVisibility: false,
                ),
                daysHeaderParam: DaysHeaderParam(
                  daysHeaderHeight: headerHeight,
                  dayHeaderBuilder: (date, isToday) {
                    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
                    return Container(
                      decoration: BoxDecoration(
                        color: isCupertino ? cardColor : surfaceColor,
                        border: Border(
                          bottom: BorderSide(color: separatorColor, width: 0.5),
                          right: BorderSide(color: separatorColor, width: 0.5),
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              weekdays[date.weekday - 1],
                              style: (isCupertino
                                      ? const TextStyle(fontSize: 13, letterSpacing: -0.08)
                                      : textTheme.labelMedium)
                                  ?.copyWith(
                                color: isToday ? primaryColor : onSurfaceVariantColor,
                                fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: isToday
                                  ? BoxDecoration(
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                      boxShadow: isCupertino
                                          ? null
                                          : [
                                              BoxShadow(
                                                color: primaryColor.withValues(alpha: 0.3),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                    )
                                  : null,
                              child: Text(
                                '${date.day}',
                                style: (isCupertino
                                        ? const TextStyle(fontSize: 17)
                                        : textTheme.titleMedium)
                                    ?.copyWith(
                                  color: isToday ? onPrimaryColor : onSurfaceColor,
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
                  timesIndicatorsWidth: 1.0,
                  timesIndicatorsCustomPainter: (_) => EmptyPainter(),
                ),
                currentHourIndicatorParam: CurrentHourIndicatorParam(
                  currentHourIndicatorLineVisibility: true,
                  currentHourIndicatorHourVisibility: false,
                  currentHourIndicatorCustomPainter: (heightPerMinute, isToday) {
                    return CurrentTimeIndicatorPainter(
                      heightPerMinute: heightPerMinute,
                      isToday: isToday,
                      color: primaryColor,
                      foregroundColor: onPrimaryColor,
                      now: widget.now,
                    );
                  },
                ),
                pinchToZoomParam: const PinchToZoomParameters(pinchToZoom: false),
              ),
            ),
          );
      },
    );
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
  final Color foregroundColor;
  final DateTime now;

  CurrentTimeIndicatorPainter({
    required this.heightPerMinute,
    required this.isToday,
    required this.color,
    required this.foregroundColor,
    required this.now,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isToday) return;

    final absoluteMinutes = now.hour * 60 + now.minute;
    final y = absoluteMinutes * heightPerMinute;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
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
      ..color = foregroundColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(4, y), 2.0, circlePaintInner);
  }

  @override
  bool shouldRepaint(covariant CurrentTimeIndicatorPainter oldDelegate) {
    return oldDelegate.heightPerMinute != heightPerMinute ||
        oldDelegate.isToday != isToday ||
        oldDelegate.now != now ||
        oldDelegate.color != color ||
        oldDelegate.foregroundColor != foregroundColor;
  }
}
