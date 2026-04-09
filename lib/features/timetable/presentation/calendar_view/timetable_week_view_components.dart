import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/course_occurrence.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/section_time_mapping.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/timetable_appointment_card.dart';

/// A custom hour line painter that ONLY draws lines at class start/end times.
class BoundaryHourLinePainter extends CustomPainter {
  BoundaryHourLinePainter({
    required this.lineColor,
    required this.lineHeight,
    required this.minuteHeight,
    required this.offset,
    required this.startHour,
  });

  final Color lineColor;
  final double lineHeight;
  final double minuteHeight;
  final double offset;
  final int startHour;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = lineHeight;

    final List<int> timePointsMins = [];
    for (final range in sectionTimeMapping.values) {
      timePointsMins.add(range.start.$1 * 60 + range.start.$2);
      timePointsMins.add(range.end.$1 * 60 + range.end.$2);
    }

    final uniquePoints = timePointsMins.toSet().toList();
    final startMins = startHour * 60;

    for (final mins in uniquePoints) {
      final y = (mins - startMins) * minuteHeight;
      if (y >= 0 && y <= size.height) {
        // Draw horizontal line across the whole width
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant BoundaryHourLinePainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.minuteHeight != minuteHeight;
  }
}

/// A custom timeline (ruler) builder that displays class start/end timestamps.
Widget timetableTimeLineBuilder(DateTime date, Color textColor) {
  // We only want to show labels if the current 'date' minute matches a class point.
  // calendar_view calls this every 'timeInterval' minutes.
  // To keep it clean, we check if this specific timestamp is a section boundary.
  
  final mins = date.hour * 60 + date.minute;
  final isBoundary = sectionTimeMapping.values.any((r) => 
    (r.start.$1 * 60 + r.start.$2 == mins) || (r.end.$1 * 60 + r.end.$2 == mins)
  );

  if (!isBoundary) return const SizedBox.shrink();

  return Container(
    padding: const EdgeInsets.only(right: 8),
    alignment: Alignment.centerRight,
    child: Text(
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
    ),
  );
}


