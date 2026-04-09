import 'package:flutter/material.dart';

class TimetableWeekdayHeader extends StatelessWidget {
  const TimetableWeekdayHeader({
    super.key,
    required this.rulerWidth,
    required this.weekStartDate,
  });

  final double rulerWidth;
  final DateTime weekStartDate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: rulerWidth),
          ...List.generate(7, (index) {
            final date = weekStartDate.add(Duration(days: index));
            final isToday = date.day == today.day && 
                           date.month == today.month && 
                           date.year == today.year;
            
            return Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    weekdays[index],
                    style: textTheme.labelSmall?.copyWith(
                      color: isToday ? colorScheme.primary : colorScheme.onSurfaceVariant,
                      fontWeight: isToday ? FontWeight.w900 : FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 28,
                    height: 28,
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
                      style: textTheme.titleSmall?.copyWith(
                        color: isToday ? colorScheme.onPrimary : colorScheme.onSurface,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
