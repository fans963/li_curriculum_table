import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_helpers.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/schedule_event.dart';
import 'package:li_curriculum_table/features/timetable/presentation/state/timetable_controller.dart';
import 'package:signals/signals_flutter.dart';

/// Bottom sheet form for adding a schedule event with date + clock time.
class AddScheduleEventSheet extends SignalStatefulWidget {
  const AddScheduleEventSheet({super.key});

  static Future<void> show(BuildContext context) {
    final ds = sl<SettingsController>().designStyle.value;
    if (AdaptiveStyle.isCupertino(ds)) {
      return showCupertinoModalPopup(
        context: context,
        builder: (_) => const AddScheduleEventSheet(),
      );
    }
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddScheduleEventSheet(),
    );
  }

  @override
  State<AddScheduleEventSheet> createState() => _AddScheduleEventSheetState();
}

class _AddScheduleEventSheetState extends State<AddScheduleEventSheet> {
  final _nameController = TextEditingController();
  final _teacherController = TextEditingController();
  final _locationController = TextEditingController();

  final _date = signal(DateTime.now());
  final _startTime = signal(const TimeOfDay(hour: 8, minute: 0));
  final _endTime = signal(const TimeOfDay(hour: 9, minute: 35));
  final _enableNotification = signal(false);
  final _notifyTime = signal(const TimeOfDay(hour: 8, minute: 0));

  @override
  void dispose() {
    _nameController.dispose();
    _teacherController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final date = _date.value;
    final startTime = _startTime.value;
    final endTime = _endTime.value;
    final enableNotification = _enableNotification.value;
    final notifyTime = _notifyTime.value;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        expand: false,
        builder: (ctx, scrollController) {
          final cs = Theme.of(ctx).colorScheme;
          return Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('添加日程', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),

                // Title
                TextField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: '日程名称 *',
                    prefixIcon: Icon(Icons.event_note_outlined),
                    filled: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _teacherController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: '相关人员',
                    prefixIcon: Icon(Icons.person_outline),
                    filled: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _locationController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: '地点',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    filled: true,
                  ),
                ),
                const SizedBox(height: 20),

                // Date
                Text('日期', style: Theme.of(ctx).textTheme.labelLarge),
                const SizedBox(height: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                      filled: true,
                    ),
                    child: Text(
                      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}  ${_weekdayLabel(date.weekday)}',
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Start / End time
                Text('时间', style: Theme.of(ctx).textTheme.labelLarge),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _pickStartTime,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: '开始',
                            prefixIcon: Icon(Icons.play_arrow_outlined),
                            filled: true,
                          ),
                          child: Text(startTime.format(context)),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('—'),
                    ),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _pickEndTime,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: '结束',
                            prefixIcon: const Icon(Icons.stop_outlined),
                            filled: true,
                            suffixText: _isEndTimeNextDay ? '次日' : null,
                            suffixStyle: TextStyle(
                              fontSize: 11,
                              color: cs.tertiary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: Text(endTime.format(context)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Notification
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('开启提醒'),
                  subtitle: const Text('在指定时间发送通知提醒'),
                  value: enableNotification,
                  onChanged: (v) => _enableNotification.value = v,
                ),
                if (enableNotification) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _pickNotifyTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '提醒时间',
                        prefixIcon: Icon(Icons.notifications_outlined),
                        filled: true,
                      ),
                      child: Text(notifyTime.format(context)),
                    ),
                  ),
                ],
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('添加日程'),
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool get _isEndTimeNextDay {
    final st = _startTime.value;
    final et = _endTime.value;
    return et.hour * 60 + et.minute <= st.hour * 60 + st.minute;
  }

  String _weekdayLabel(int weekday) {
    const labels = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return labels[weekday];
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) _date.value = picked;
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(context: context, initialTime: _startTime.value);
    if (picked != null) {
      _startTime.value = picked;
      final currentEnd = _endTime.value;
      final startMinutes = picked.hour * 60 + picked.minute;
      final endMinutes = currentEnd.hour * 60 + currentEnd.minute;
      if (endMinutes <= startMinutes) {
        // End <= Start: advance end by 45 min, wrapping past midnight if needed
        final newEndMin = startMinutes + 45;
        _endTime.value = TimeOfDay(hour: (newEndMin ~/ 60) % 24, minute: newEndMin % 60);
      }
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(context: context, initialTime: _endTime.value);
    if (picked != null) _endTime.value = picked;
  }

  Future<void> _pickNotifyTime() async {
    final picked = await showTimePicker(context: context, initialTime: _notifyTime.value);
    if (picked != null) _notifyTime.value = picked;
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showAdaptiveMessage(
        context,
        designStyle: sl<SettingsController>().designStyle.value,
        message: '请输入日程名称',
      );
      return;
    }

    final d = _date.value;
    final st = _startTime.value;
    final et = _endTime.value;
    final start = DateTime(d.year, d.month, d.day, st.hour, st.minute);
    var end = DateTime(d.year, d.month, d.day, et.hour, et.minute);
    if (!end.isAfter(start)) end = end.add(const Duration(days: 1));

    final enableNotif = _enableNotification.value;
    final notifyDateTime = enableNotif
        ? DateTime(d.year, d.month, d.day,
            _notifyTime.value.hour, _notifyTime.value.minute)
        : null;

    final event = ScheduleEvent(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
      title: name,
      teacher: _teacherController.text.trim(),
      location: _locationController.text.trim(),
      start: start,
      end: end,
      enableNotification: enableNotif,
      notifyTime: notifyDateTime,
    );

    sl<TimetableController>().addScheduleEvent(event);

    Navigator.of(context).pop();
    showAdaptiveMessage(
      context,
      designStyle: sl<SettingsController>().designStyle.value,
      message: '已添加日程「$name」\n长按课表上的日程卡片可删除',
    );
  }
}
