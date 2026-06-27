import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/course_occurrence.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/course_row.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/course_color_service.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/course_online_service.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/timetable_appointment_card.dart'
    show openCourseDetails, resolveAppointmentTone;

/// A collapsible horizontal strip displaying async (录播) online courses
/// that have no fixed time slots. Sits above the timetable grid.
class AsyncCourseStrip extends StatefulWidget {
  final List<CourseRow> asyncCourses;
  final bool isExpanded;
  final VoidCallback? onToggle;

  const AsyncCourseStrip({
    super.key,
    required this.asyncCourses,
    this.isExpanded = true,
    this.onToggle,
  });

  @override
  State<AsyncCourseStrip> createState() => AsyncCourseStripState();
}

class AsyncCourseStripState extends State<AsyncCourseStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _heightAnimation;
  late final Animation<double> _fadeAnimation;
  bool _prevExpanded = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _heightAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );
    _controller.value = widget.isExpanded ? 1.0 : 0.0;
    _prevExpanded = widget.isExpanded;
  }

  @override
  void didUpdateWidget(covariant AsyncCourseStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != _prevExpanded) {
      _prevExpanded = widget.isExpanded;
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void toggle() => widget.onToggle?.call();

  bool get isExpanded => widget.isExpanded;

  @override
  Widget build(BuildContext context) {
    final settings = sl<SettingsController>().state.value;
    final isCupertino = AdaptiveStyle.isCupertino(settings.designStyle);
    final cs = Theme.of(context).colorScheme;

    if (widget.asyncCourses.isEmpty) return const SizedBox.shrink();

    final stripHeight = 88.0; // mini header (~20) + card row (~68)

    return SizeTransition(
      sizeFactor: _heightAnimation,
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          height: stripHeight,
          decoration: BoxDecoration(
            color: isCupertino
                ? CupertinoColors.systemGroupedBackground.resolveFrom(context)
                : cs.surface,
            border: Border(
              bottom: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mini header row
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 4, right: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.live_tv_rounded,
                      size: 13,
                      color: cs.primary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '网课 (${widget.asyncCourses.length}门)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: toggle,
                      child: Icon(
                        widget.isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              // Horizontal scrollable card row
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  itemCount: widget.asyncCourses.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return _AsyncCourseCard(
                      course: widget.asyncCourses[index],
                      isCupertino: isCupertino,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AsyncCourseCard extends StatelessWidget {
  final CourseRow course;
  final bool isCupertino;

  const _AsyncCourseCard({required this.course, required this.isCupertino});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onlineService = sl<CourseOnlineService>();
    final override = onlineService.getOverride(course.courseName);
    // Use the same color resolver as grid cards, including custom color overrides.
    final customColor = sl<CourseColorService>().getColor(course.courseName);
    final tone = resolveAppointmentTone(
      context,
      seedText: course.courseName,
      customColor: customColor,
    );
    final color = tone.accent;

    // Location display: manual platform override > auto-detected "线上" > raw location
    final locText =
        override?.platform ??
        (course.location.trim() == '线上' ? '线上' : course.location.trim());

    return GestureDetector(
      onTap: () => openCourseDetails(context, _toOccurrence(course, color)),
      child: Container(
        width: 155,
        decoration: BoxDecoration(
          color: isCupertino
              ? CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
                  context,
                )
              : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    course.courseName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                      height: 1.2,
                    ),
                  ),
                  if (locText.isNotEmpty)
                    Text(
                      locText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                        height: 1.2,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Build a synthetic [CourseOccurrence] from a [CourseRow] for the details sheet.
CourseOccurrence _toOccurrence(CourseRow row, Color color) {
  final now = DateTime.now();
  final monday = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: now.weekday - DateTime.monday));
  // Use the first slot if available, otherwise dummy placeholder
  final slot = row.slots.isNotEmpty ? row.slots.first : null;
  final weekday = slot?.weekday ?? 1;
  final day = monday.add(Duration(days: weekday - DateTime.monday));

  return CourseOccurrence(
    courseName: row.courseName,
    teacher: row.teacher,
    location: row.location,
    credit: row.credit,
    courseType: row.courseType,
    stage: row.stage,
    start: DateTime(day.year, day.month, day.day, 8),
    end: DateTime(day.year, day.month, day.day, 9),
    startWeek: slot?.startWeek,
    endWeek: slot?.endWeek,
    weekText: slot?.weekText ?? '',
    color: color,
  );
}
