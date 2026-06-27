import 'package:infinite_calendar_view/infinite_calendar_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loading_indicator_m3e/loading_indicator_m3e.dart';
import 'package:signals/signals_flutter.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/course_color_service.dart';
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
    required this.pixelsPerMinute,
    required this.now,
    this.onPageChange,
  });

  final double pixelsPerMinute;
  final DateTime now;
  final void Function(DateTime, int)? onPageChange;

  @override
  State<TimetableWeekView> createState() => TimetableWeekViewState();
}

class TimetableWeekViewState extends State<TimetableWeekView> {
  GlobalKey<EventsPlannerState> _plannerKey = GlobalKey<EventsPlannerState>();
  DateTime? _lastTermStart;
  int _lastDaysCount = 7;

  @override
  void initState() {
    super.initState();
    _handleInitialJump();
  }

  void _handleInitialJump() {
    // Retry up to 3 times with increasing delay to ensure the planner is laid out.
    _attemptJump(0);
  }

  void _attemptJump(int attempt) {
    if (attempt > 3) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final planner = _plannerKey.currentState;
      if (planner == null) {
        _attemptJump(attempt + 1);
        return;
      }

      final settings = sl<SettingsController>().state.value;
      final weeklyScroll = settings.weeklyScroll;
      final daysCount = weeklyScroll ? 7 : settings.daysVisibleCount;
      final now = DateTime.now().withoutTime;

      DateTime targetDate;
      if (weeklyScroll || daysCount == 7) {
        targetDate = mondayOfDate(now);
      } else {
        targetDate = now;
      }

      planner.jumpToDate(targetDate);

      // Sync displayWeek with the visible date
      final anchor = sl<TimetableController>().state.value.termStartMonday;
      if (anchor != null) {
        final week = calculateWeekIndex(targetDate, anchor);
        sl<TimetableController>().updateDisplayWeek(week);
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
    // Watch color version — forces planner rebuild when any course color changes.
    final colorVersion = sl<CourseColorService>().version.value;
    final termStart = timetableState.termStartMonday;
    final settings = sl<SettingsController>().state.value;
    final weeklyScroll = settings.weeklyScroll;
    // When week-scrolling is on, always show a full week (7 days).
    // When free-scrolling (无极滑动), use the user-configured count.
    final daysVisibleCount = weeklyScroll ? 7 : settings.daysVisibleCount;

    if (termStart != _lastTermStart || daysVisibleCount != _lastDaysCount) {
      _lastTermStart = termStart;
      _lastDaysCount = daysVisibleCount;
      _plannerKey = GlobalKey<EventsPlannerState>();
      _handleInitialJump();
    }

    final ds = sl<SettingsController>().state.value.designStyle;
    final isCupertino = AdaptiveStyle.isCupertino(ds);
    final colorScheme = Theme.of(context).colorScheme;
    const headerHeight = 44.0;

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

    // No horizontal scroll limit — allow free scrolling beyond data range

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
            key: ValueKey('$termStart-$daysVisibleCount-c$colorVersion'),
            child: EventsPlanner(
              key: _plannerKey,
              controller: controller,
              daysShowed: daysVisibleCount,
              initialDate: termStart ?? DateTime.now().withoutTime,
              heightPerMinute: widget.pixelsPerMinute,
              initialVerticalScrollOffset: 480 * widget.pixelsPerMinute,
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
                  // Use a Listener to detect taps via raw pointer events,
                  // bypassing the gesture arena (Scale/LongPress/Drag recognizers
                  // from the framework cause ~300ms tap delay).
                  return _TapDetector(
                    onTap: () => openCourseDetails(context, occurrence),
                    child: buildTimetableAppointmentCard(
                      context: context,
                      occurrence: occurrence,
                      now: widget.now,
                      onTap: () {}, // suppress card's own GestureDetector onTap
                    ),
                  );
                },
                dayCustomPainter: (heightPerMinute, isToday) =>
                    DayLinesWithVerticalSeparatorPainter(
                      heightPerMinute: heightPerMinute,
                      lineColor: separatorColor,
                      rightOffset: 1.5, // daySeparationWidth / 2
                    ),
              ),
              offTimesParam: OffTimesParam(offTimesColor: surfaceColor),
              fullDayParam: const FullDayParam(
                fullDayEventsBarVisibility: false,
              ),
              daysHeaderParam: DaysHeaderParam(
                daysHeaderHeight: headerHeight,
                dayHeaderBuilder: (date, isToday) {
                  const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
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
                            style: TextStyle(
                              fontSize: 11,
                              color: isToday
                                  ? primaryColor
                                  : onSurfaceVariantColor,
                              fontWeight: isToday
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: isToday
                                ? BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                  )
                                : null,
                            child: Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: 14,
                                color: isToday
                                    ? onPrimaryColor
                                    : onSurfaceColor,
                                fontWeight: isToday
                                    ? FontWeight.w800
                                    : FontWeight.w500,
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
                timesIndicatorsWidth: 32,
                timesIndicatorsHorizontalPadding: 2,
                timesIndicatorsCustomPainter: (heightPerMinute) =>
                    _CompactHoursPainter(
                      heightPerMinute: heightPerMinute,
                      color: colorScheme.outline,
                    ),
              ),
              currentHourIndicatorParam: const CurrentHourIndicatorParam(),
              pinchToZoomParam: const PinchToZoomParameters(),
            ),
          ),
        );
      },
    );
  }
}

/// Combined painter: horizontal hour/half-hour lines (like LinesPainter)
/// plus a vertical dashed separator on the right edge.
class DayLinesWithVerticalSeparatorPainter extends CustomPainter {
  final double heightPerMinute;
  final Color lineColor;
  final double dashHeight;
  final double dashSpace;
  final double rightOffset;

  DayLinesWithVerticalSeparatorPainter({
    required this.heightPerMinute,
    required this.lineColor,
    this.dashHeight = 4.0,
    this.dashSpace = 4.0,
    this.rightOffset = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellHeight = heightPerMinute * 60;

    final hourPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5;
    final halfHourPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.2;
    final dashPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5;

    // Horizontal lines — same as LinesPainter
    for (var i = 0; i < 24; i++) {
      final hourY = i * cellHeight;
      canvas.drawLine(Offset(0, hourY), Offset(size.width, hourY), hourPaint);

      final halfHourY = hourY + cellHeight / 2;
      canvas.drawLine(
        Offset(0, halfHourY),
        Offset(size.width, halfHourY),
        halfHourPaint,
      );
    }
    // 24:00
    canvas.drawLine(
      Offset(0, 24 * cellHeight),
      Offset(size.width, 24 * cellHeight),
      hourPaint,
    );

    // Vertical dashed line — offset to align with header separator
    final dx = size.width + rightOffset;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(dx, y), Offset(dx, y + dashHeight), dashPaint);
      y += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(
    covariant DayLinesWithVerticalSeparatorPainter oldDelegate,
  ) {
    return oldDelegate.heightPerMinute != heightPerMinute ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.rightOffset != rightOffset;
  }
}

/// Detects taps via raw pointer events using [Listener], completely bypassing
/// Flutter's gesture arena. This avoids the ~300ms disambiguation delay caused
/// by competing [ScaleGestureRecognizer], [LongPressGestureRecognizer], and
/// [DragGestureRecognizer] from the infinite_calendar_view framework.
class _TapDetector extends StatefulWidget {
  const _TapDetector({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_TapDetector> createState() => _TapDetectorState();
}

class _TapDetectorState extends State<_TapDetector> {
  Offset? _pointerDownPos;
  DateTime? _pointerDownTime;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        _pointerDownPos = event.localPosition;
        _pointerDownTime = DateTime.now();
      },
      onPointerUp: (event) {
        if (_pointerDownPos == null || _pointerDownTime == null) return;
        final dx = event.localPosition.dx - _pointerDownPos!.dx;
        final dy = event.localPosition.dy - _pointerDownPos!.dy;
        final distance = dx * dx + dy * dy;
        final elapsed = DateTime.now().difference(_pointerDownTime!);
        // Consider it a tap if the pointer barely moved (< 20px²) and was held
        // for less than 200ms.
        if (distance < 400 && elapsed < const Duration(milliseconds: 200)) {
          widget.onTap();
        }
        _pointerDownPos = null;
        _pointerDownTime = null;
      },
      onPointerCancel: (_) {
        _pointerDownPos = null;
        _pointerDownTime = null;
      },
      child: widget.child,
    );
  }
}

/// Compact time axis painter — shows just the hour number (e.g. "8" not "08:00").
/// Text is vertically centered on the hour line drawn by LinesPainter at
/// y = i * cellHeight, so the number sits right on the line.
class _CompactHoursPainter extends CustomPainter {
  final double heightPerMinute;
  final Color color;

  const _CompactHoursPainter({
    required this.heightPerMinute,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellHeight = heightPerMinute * 60;
    const fontSize = 10.0;
    const textHeight = fontSize; // approximate single-line height

    for (var i = 0; i <= 24; i++) {
      final lineY = i * cellHeight;
      // Center text vertically on the line
      final textY = lineY - textHeight / 2;
      final tp = TextPainter(
        text: TextSpan(
          text: '$i',
          style: TextStyle(color: color, fontSize: fontSize, height: 1.0),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout(minWidth: size.width, maxWidth: size.width);
      tp.paint(canvas, Offset(0, textY));
    }
  }

  @override
  bool shouldRepaint(covariant _CompactHoursPainter oldDelegate) =>
      oldDelegate.heightPerMinute != heightPerMinute ||
      oldDelegate.color != color;
}
