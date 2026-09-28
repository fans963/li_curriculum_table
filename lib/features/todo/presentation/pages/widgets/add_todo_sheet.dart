import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:signals/signals_flutter.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/features/todo/domain/entities/course_todo.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_helpers.dart';
import 'package:li_curriculum_table/features/todo/presentation/state/todo_controller.dart';
import 'package:uuid/uuid.dart';

/// Bottom sheet form for adding or editing a course todo / DDL.
class AddTodoSheet extends SignalStatefulWidget {
  final CourseTodo? existing;
  final String? presetCourseName;

  const AddTodoSheet({super.key, this.existing, this.presetCourseName});

  static Future<void> show(
    BuildContext context, {
    CourseTodo? existing,
    String? presetCourseName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddTodoSheet(
        existing: existing,
        presetCourseName: presetCourseName,
      ),
    );
  }

  @override
  State<AddTodoSheet> createState() => _AddTodoSheetState();
}

class _AddTodoSheetState extends State<AddTodoSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _courseController;
  late final TextEditingController _noteController;
  late final Signal<DateTime> _deadline;
  late final Signal<int> _reminderMinutes;
  late final Signal<bool> _saving;

  static const _reminderOptions = <int>[0, 15, 30, 60, 120, 1440, 10080];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleController = TextEditingController(text: e?.title ?? '');
    _courseController =
        TextEditingController(text: e?.courseName ?? widget.presetCourseName ?? '');
    _noteController = TextEditingController(text: e?.note ?? '');
    _deadline = signal<DateTime>(
      e?.deadline ?? _defaultDeadline(),
    );
    _reminderMinutes = signal<int>(e?.reminderMinutes ?? 120);
    _saving = signal<bool>(false);
  }

  static DateTime _defaultDeadline() {
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day, 23, 59);
    final diff = base.difference(now);
    return diff.inHours < 4
        ? base.add(const Duration(days: 1))
        : base;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _courseController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final initial = _deadline.value;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      helpText: '选择截止日期',
    );
    if (picked == null || !mounted) return;
    _deadline.value = DateTime(
      picked.year,
      picked.month,
      picked.day,
      _deadline.value.hour,
      _deadline.value.minute,
    );
  }

  Future<void> _pickTime() async {
    final initial = TimeOfDay.fromDateTime(_deadline.value);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: '选择截止时间',
    );
    if (picked == null || !mounted) return;
    _deadline.value = DateTime(
      _deadline.value.year,
      _deadline.value.month,
      _deadline.value.day,
      picked.hour,
      picked.minute,
    );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      showAdaptiveMessage(context, message: '请输入待办标题');
      return;
    }
    _saving.value = true;
    final controller = sl<TodoController>();
    final isEdit = widget.existing != null;
    final deadline = _deadline.value;
    final reminder = _reminderMinutes.value;
    final courseName = _courseController.text.trim();
    final note = _noteController.text.trim();

    try {
      if (isEdit) {
        final updated = widget.existing!.copyWith(
          title: title,
          courseName: courseName.isEmpty ? null : courseName,
          deadline: deadline,
          reminderMinutes: reminder,
          note: note.isEmpty ? null : note,
        );
        await controller.updateTodo(updated);
      } else {
        final todo = CourseTodo(
          id: const Uuid().v4(),
          title: title,
          courseName: courseName.isEmpty ? null : courseName,
          deadline: deadline,
          reminderMinutes: reminder,
          note: note.isEmpty ? null : note,
        );
        await controller.addTodo(todo);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      showAdaptiveMessage(
        context,
        message: isEdit ? '已更新待办' : '已添加待办',
      );
    } catch (e) {
      if (!mounted) return;
      showAdaptiveMessage(context, message: '保存失败：$e');
    } finally {
      _saving.value = false;
    }
  }

  Future<void> _delete() async {
    final e = widget.existing;
    if (e == null) return;
    final confirmed = await showAdaptiveConfirmDialog(
      context,
      title: '删除待办',
      content: '确定要删除「${e.title}」吗？',
      confirmText: '删除',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    await sl<TodoController>().deleteTodo(e.id);
    if (!mounted) return;
    Navigator.of(context).pop();
    showAdaptiveMessage(context, message: '已删除');
  }

  String _formatDeadline(DateTime dt) {
    String pad(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${pad(dt.month)}-${pad(dt.day)} '
        '${pad(dt.hour)}:${pad(dt.minute)}';
  }

  String _reminderLabel(int minutes) {
    if (minutes == 0) return '不提醒';
    if (minutes < 60) return '$minutes 分钟前';
    if (minutes < 1440) return '${minutes ~/ 60} 小时前';
    return '${minutes ~/ 1440} 天前';
  }

  @override
  Widget build(BuildContext context) {
    // Touch reactive signal so the sheet rebuilds.
    final deadline = _deadline.value;
    final reminder = _reminderMinutes.value;
    final saving = _saving.value;
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.55,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      widget.existing == null
                          ? Icons.add_task_rounded
                          : Icons.edit_note_rounded,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.existing == null ? '添加待办 / DDL' : '编辑待办',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _titleController,
                  autofocus: widget.existing == null,
                  decoration: const InputDecoration(
                    labelText: '待办标题 *',
                    hintText: '例如：第三章课后习题 / 期末论文',
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                  textInputAction: TextInputAction.next,
                  maxLength: 60,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _courseController,
                  decoration: const InputDecoration(
                    labelText: '关联课程（可选）',
                    hintText: '例如：高等数学',
                    prefixIcon: Icon(Icons.school_rounded),
                  ),
                  textInputAction: TextInputAction.next,
                  maxLength: 40,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today_rounded, size: 18),
                        label: Text(
                          _formatDeadline(deadline).split(' ').first,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.access_time_rounded, size: 18),
                        label: Text(
                          _formatDeadline(deadline).split(' ').last,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '提醒',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _reminderOptions.map((m) {
                    final selected = reminder == m;
                    return ChoiceChip(
                      label: Text(_reminderLabel(m)),
                      selected: selected,
                      onSelected: (_) => _reminderMinutes.value = m,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _noteController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: '备注（可选）',
                    hintText: '要求、提交方式、链接等',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    if (widget.existing != null)
                      Expanded(
                        child: M3EButton.outlined(
                          onPressed: saving ? null : _delete,
                          decoration: M3EButtonDecoration.styleFrom(
                            foregroundColor: cs.error,
                            side: BorderSide(color: cs.error),
                          ),
                          child: const Text('删除'),
                        ),
                      ),
                    if (widget.existing != null) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: M3EButton.filled(
                        onPressed: saving ? null : _save,
                        child: saving
                            ? adaptiveActivityIndicator(
                                color: cs.onPrimary, size: 20)
                            : Text(widget.existing == null ? '保存待办' : '更新'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
