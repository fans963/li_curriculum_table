import 'package:flutter/material.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_helpers.dart';
import 'package:li_curriculum_table/core/presentation/widgets/adaptive_date_picker.dart';
import 'package:li_curriculum_table/core/presentation/styles/styles.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/schedule_event.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/liquid_glass_add_schedule_event_sheet.dart';
import 'package:li_curriculum_table/features/timetable/presentation/state/timetable_controller.dart';
import 'package:signals/signals_flutter.dart';

/// Bottom sheet form for adding a schedule event with date + clock time.
class AddScheduleEventSheet extends SignalStatefulWidget {
  const AddScheduleEventSheet({super.key});

  static Future<void> show(BuildContext context) {
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

  final _nameNotEmpty = signal(false);

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    _nameNotEmpty.value = _nameController.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _teacherController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Subscribe to nameNotEmpty signal for reactive rebuilds
    final _ = _nameNotEmpty.value;
    final ds = sl<SettingsController>().state.value.designStyle;
    final concrete = UiStyleRegistry.resolveConcreteStyle(ds);
    if (concrete == DesignStyle.cupertino) {
      return _buildLiquidGlass(context);
    }
    return _buildMaterial(context);
  }

  Widget _buildLiquidGlass(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        expand: false,
        builder: (ctx, scrollController) {
          return LiquidGlassAddScheduleEventSheetView(
            scrollController: scrollController,
            nameController: _nameController,
            teacherController: _teacherController,
            locationController: _locationController,
            date: _date.value,
            startTime: _startTime.value,
            endTime: _endTime.value,
            enableNotification: _enableNotification.value,
            notifyTime: _notifyTime.value,
            nameNotEmpty: _nameNotEmpty.value,
            onPickDate: _pickDate,
            onPickStartTime: _pickStartTime,
            onPickEndTime: _pickEndTime,
            onToggleNotification: (v) => _enableNotification.value = v,
            onPickNotifyTime: _pickNotifyTime,
            onSubmit: _submit,
            onCancel: () => Navigator.of(context).pop(),
          );
        },
      ),
    );
  }

  Widget _buildMaterial(BuildContext context) {
    final date = _date.value;
    final startTime = _startTime.value;
    final endTime = _endTime.value;
    final enableNotification = _enableNotification.value;
    final notifyTime = _notifyTime.value;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final ds = sl<SettingsController>().state.value.designStyle;
    final style = UiStyleRegistry.resolve(ds);

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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
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
                Text(
                  '添加日程',
                  style: Theme.of(ctx).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
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

                // Time range
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
                            labelText: '开始时间',
                            prefixIcon: Icon(Icons.access_time_outlined),
                            filled: true,
                          ),
                          child: Text(
                            '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('—'),
                    ),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _pickEndTime,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: '结束时间',
                            prefixIcon: Icon(Icons.access_time_outlined),
                            filled: true,
                          ),
                          child: Text(
                            '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Notification toggle
                style.buildCard(
                  context: ctx,
                  borderRadius: 20,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.notifications_outlined,
                              size: 20,
                              color: cs.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '开启提醒',
                                style: Theme.of(ctx).textTheme.bodyMedium,
                              ),
                            ),
                            adaptiveSwitch(
                              context: ctx,
                              designStyle: sl<SettingsController>()
                                  .state
                                  .value
                                  .designStyle,
                              value: enableNotification,
                              onChanged: (v) => _enableNotification.value = v,
                            ),
                          ],
                        ),
                        if (enableNotification) ...[
                          const Divider(),
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: _pickNotifyTime,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Text(
                                    '提醒时间',
                                    style: Theme.of(ctx).textTheme.bodyMedium,
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${notifyTime.hour.toString().padLeft(2, '0')}:${notifyTime.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: cs.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 18,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: adaptiveButton(
                        context: context,
                        designStyle:
                            sl<SettingsController>().state.value.designStyle,
                        style: UiButtonStyle.text,
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('取消'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: adaptiveButton(
                        context: context,
                        designStyle:
                            sl<SettingsController>().state.value.designStyle,
                        style: UiButtonStyle.filled,
                        onPressed: _nameNotEmpty.value ? _submit : null,
                        child: const Text('保存'),
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

  String _weekdayLabel(int weekday) {
    const labels = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return labels[weekday];
  }

  Future<void> _pickDate() async {
    final picked = await showAdaptiveDatePicker(
      context: context,
      designStyle: sl<SettingsController>().state.value.designStyle,
      initialDate: _date.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) _date.value = picked;
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime.value,
    );
    if (picked != null) {
      _startTime.value = picked;
      final currentEnd = _endTime.value;
      final startMin = picked.hour * 60 + picked.minute;
      final endMin = currentEnd.hour * 60 + currentEnd.minute;
      if (endMin <= startMin) {
        final newEnd = (startMin + 45).clamp(0, 23 * 60 + 59);
        _endTime.value = TimeOfDay(hour: newEnd ~/ 60, minute: newEnd % 60);
      }
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime.value,
    );
    if (picked != null) {
      final startMin = _startTime.value.hour * 60 + _startTime.value.minute;
      final pickedMin = picked.hour * 60 + picked.minute;
      if (pickedMin <= startMin) {
        final adjusted = (startMin + 45).clamp(0, 23 * 60 + 59);
        _endTime.value = TimeOfDay(hour: adjusted ~/ 60, minute: adjusted % 60);
      } else {
        _endTime.value = picked;
      }
    }
  }

  Future<void> _pickNotifyTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _notifyTime.value,
    );
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
    final end = DateTime(d.year, d.month, d.day, et.hour, et.minute);

    final enableNotif = _enableNotification.value;
    final notifyDateTime = enableNotif
        ? DateTime(
            d.year,
            d.month,
            d.day,
            _notifyTime.value.hour,
            _notifyTime.value.minute,
          )
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
