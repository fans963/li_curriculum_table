import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:signals/signals_flutter.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_helpers.dart';
import 'package:li_curriculum_table/features/todo/domain/entities/course_todo.dart';
import 'package:li_curriculum_table/features/todo/presentation/pages/widgets/add_todo_sheet.dart';
import 'package:li_curriculum_table/features/todo/presentation/state/todo_controller.dart';

/// Full-screen modal sheet showing every todo grouped by status.
class TodoManagementSheet extends StatelessWidget {
  const TodoManagementSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const TodoManagementSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = sl<TodoController>();
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.checklist_rounded,
                        color: cs.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '待办与 DDL',
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: '清除已完成',
                        onPressed: () async {
                          final ok = await showAdaptiveConfirmDialog(
                            context,
                            title: '清除已完成',
                            content: '所有标记为「已完成」的待办将被永久删除。',
                            confirmText: '清除',
                            isDestructive: true,
                          );
                          if (ok) await controller.clearCompleted();
                        },
                        icon: const Icon(Icons.cleaning_services_rounded),
                      ),
                      M3EButton.tonal(
                        onPressed: () => AddTodoSheet.show(context),
                        size: M3EButtonSize.sm,
                        shape: M3EButtonShape.round,
                        child: const Text('添加'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SignalBuilder(
                    dependencies: [
                      controller.todos,
                      controller.busy,
                    ],
                    builder: (context) {
                      if (controller.busy.value &&
                          controller.todos.value.isEmpty) {
                        return Center(
                          child: adaptiveActivityIndicator(size: 24),
                        );
                      }
                      final all = controller.todos.value;
                      if (all.isEmpty) return const _EmptyState();
                      final open = all.where((t) => !t.isCompleted).toList()
                        ..sort((a, b) => a.deadline.compareTo(b.deadline));
                      final completed = all.where((t) => t.isCompleted).toList()
                        ..sort((a, b) => (b.completedAt ?? b.deadline)
                            .compareTo(a.completedAt ?? a.deadline));

                      return ListView(
                        controller: scrollController,
                        padding:
                            const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        children: [
                          if (open.isNotEmpty) ...[
                            _SectionHeader(
                              title: '待完成 (${open.length})',
                              color: cs.primary,
                            ),
                            ...open.map(
                              (t) => _TodoTile(
                                todo: t,
                                onToggle: () =>
                                    controller.toggleCompleted(t.id),
                                onEdit: () =>
                                    AddTodoSheet.show(context, existing: t),
                                onDelete: () =>
                                    controller.deleteTodo(t.id),
                              ),
                            ),
                          ],
                          if (completed.isNotEmpty) ...[
                            _SectionHeader(
                              title: '已完成 (${completed.length})',
                              color: cs.onSurfaceVariant,
                            ),
                            ...completed.map(
                              (t) => _TodoTile(
                                todo: t,
                                onToggle: () =>
                                    controller.toggleCompleted(t.id),
                                onEdit: () =>
                                    AddTodoSheet.show(context, existing: t),
                                onDelete: () =>
                                    controller.deleteTodo(t.id),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_turned_in_rounded,
              size: 56,
              color: cs.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              '还没有待办',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '从课程详情或这里添加你的第一个作业、测验或论文 DDL。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            M3EButton.filled(
              onPressed: () => AddTodoSheet.show(context),
              child: const Text('添加待办'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodoTile extends StatelessWidget {
  final CourseTodo todo;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TodoTile({
    required this.todo,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final urgencyColor = todo.isCompleted
        ? cs.onSurfaceVariant
        : (todo.isOverdue
            ? cs.error
            : (todo.deadline.difference(DateTime.now()).inHours < 24
                ? cs.error
                : (todo.deadline.difference(DateTime.now()).inHours < 72
                    ? cs.tertiary
                    : cs.primary)));

    return Dismissible(
      key: ValueKey(todo.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: cs.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Icon(Icons.delete_rounded, color: cs.onErrorContainer),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return true;
      },
      child: ListTile(
        onTap: onEdit,
        leading: Checkbox(
          value: todo.isCompleted,
          onChanged: (_) => onToggle(),
          shape: const CircleBorder(),
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration:
                todo.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
            color: todo.isCompleted ? cs.onSurfaceVariant : cs.onSurface,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(
            children: [
              Icon(
                todo.isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.alarm_rounded,
                size: 12,
                color: urgencyColor,
              ),
              const SizedBox(width: 4),
              Text(
                todo.remainingTimeText,
                style: TextStyle(
                  fontSize: 12,
                  color: urgencyColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (todo.courseName?.isNotEmpty == true) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    todo.courseName!,
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
