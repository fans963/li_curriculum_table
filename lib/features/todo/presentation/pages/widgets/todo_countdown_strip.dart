import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/features/todo/presentation/pages/widgets/add_todo_sheet.dart';
import 'package:li_curriculum_table/features/todo/domain/entities/course_todo.dart';
import 'package:li_curriculum_table/features/todo/presentation/pages/widgets/todo_management_sheet.dart';
import 'package:li_curriculum_table/features/todo/presentation/state/todo_controller.dart';

/// Compact horizontal strip listing the nearest upcoming DDLs.
/// Sits above the timetable grid; collapses to a single summary chip
/// when there are no urgent items.
class TodoCountdownStrip extends StatelessWidget {
  const TodoCountdownStrip({super.key});

  static const _maxVisible = 4;

  @override
  Widget build(BuildContext context) {
    final controller = sl<TodoController>();
    return SignalBuilder(
      dependencies: [controller.upcomingTodos, controller.busy, controller.loaded],
      builder: (context) {
        if (!controller.loaded.value) return const SizedBox.shrink();
        final upcoming = controller.upcomingTodos.value;
        if (upcoming.isEmpty) {
          return const SizedBox.shrink();
        }
        final visible = upcoming.take(_maxVisible).toList(growable: false);
        final extra = upcoming.length - visible.length;
        final cs = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.event_note_rounded,
                    size: 16,
                    color: cs.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '临近 DDL',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => TodoManagementSheet.show(context),
                    icon: const Icon(Icons.list_alt_rounded, size: 16),
                    label: const Text('查看全部'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 84,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: visible.length + (extra > 0 ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    if (extra > 0 && index == visible.length) {
                      return _MoreChip(count: extra);
                    }
                    return _TodoCard(todo: visible[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TodoCard extends StatelessWidget {
  final CourseTodo todo;
  const _TodoCard({required this.todo});

  Color _urgencyColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    if (todo.isOverdue) return cs.error;
    final remaining = todo.deadline.difference(now);
    if (remaining.inHours < 24) return cs.error;
    if (remaining.inHours < 24 * 3) return cs.tertiary;
    return cs.primary;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = _urgencyColor(context);
    return SizedBox(
      width: 220,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => AddTodoSheet.show(context, existing: todo),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accent.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      todo.isOverdue
                          ? Icons.error_rounded
                          : Icons.alarm_rounded,
                      size: 14,
                      color: accent,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        todo.remainingTimeText,
                        style: TextStyle(
                          fontSize: 11,
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  todo.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (todo.courseName?.isNotEmpty == true)
                  Text(
                    todo.courseName!,
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoreChip extends StatelessWidget {
  final int count;
  const _MoreChip({required this.count});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => TodoManagementSheet.show(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 80,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.more_horiz_rounded,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(height: 2),
              Text(
                '还有 $count',
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
