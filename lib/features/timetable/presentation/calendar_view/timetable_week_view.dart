import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:li_curriculum_table/features/timetable/presentation/calendar_view/calendar_view_adapter.dart';
import 'package:li_curriculum_table/features/timetable/presentation/calendar_view/timetable_week_view_components.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/timetable_appointment_card.dart';

class TimetableWeekView extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(timetableEventControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final viewHeight = 64.0; // The height of our header area

    return Container(
      color: colorScheme.surface,
      child: Stack(
        children: [
          WeekView(
            controller: controller,
            // Basics
            startHour: startHour,
            endHour: endHour,
            heightPerMinute: pixelsPerMinute,
            backgroundColor: colorScheme.surface,
            // Minimalist Grid
            showVerticalLines: false,
            hourLinePainter: (lineColor, lineHeight, offset, minuteHeight,
                showVerticalLine, verticalLineOffset, lineStyle, dashWidth,
                dashSpaceWidth, emulateVerticalOffsetBy, startHourArg, endHourArg) {
              return BoundaryHourLinePainter(
                lineColor: colorScheme.outlineVariant.withValues(alpha: 0.8),
                lineHeight: 0.8,
                minuteHeight: pixelsPerMinute,
                offset: offset,
                startHour: startHour,
              );
            },
            // Indicators
            liveTimeIndicatorSettings: LiveTimeIndicatorSettings(
              color: colorScheme.primary,
              showTime: false,
              height: 1.5,
              bulletRadius: 3,
            ),
            // Custom Ruler
            timeLineBuilder: (date) =>
                timetableTimeLineBuilder(date, colorScheme.onSurfaceVariant),
            timeLineWidth: 48,
            // Custom Event Cards
            eventTileBuilder: (date, events, boundary, startDuration, endDuration) {
              if (events.isEmpty) return const SizedBox.shrink();
              final occurrence = events.first.event;
              if (occurrence == null) return const SizedBox.shrink();
              
              return buildTimetableAppointmentCard(
                context: context,
                occurrence: occurrence,
                now: now,
              );
            },
            // Navigation
            onPageChange: onPageChange,
            // Header (Built-in Material 3 Styling)
            headerStyle: HeaderStyle(
              decoration: BoxDecoration(
                color: colorScheme.surface,
              ),
              headerTextStyle: textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            weekTitleHeight: viewHeight,
            weekDayBuilder: (date) {
              final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
              final now = DateTime.now();
              final isToday = date.day == now.day && 
                             date.month == now.month && 
                             date.year == now.year;
              
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
            weekNumberBuilder: (date) => Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  bottom: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
                ),
              ),
            ),
            // Selection (None)
            onDateTap: (_) {},
            onDateLongPress: (_) {},
          ),
          // THE ULTIMATE FIX: Masking/Re-coloring the stubborn internal divider
          // Instead of hiding it, we 'paint' it with the outlineVariant color
          Positioned(
            top: 48, // Transition between Month Title and Day Labels
            left: 0,
            right: 0,
            height: 0.5,
            child: Container(color: colorScheme.outlineVariant),
          ),
          Positioned(
            top: 48 + viewHeight, // Transition between Day Labels and Table Grid
            left: 0,
            right: 0,
            height: 0.5,
            child: Container(color: colorScheme.outlineVariant),
          ),
        ],
      ),
    );
  }
}
