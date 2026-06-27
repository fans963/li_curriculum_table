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
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    setState(() {});
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
    if (_isCupertino) {
      return _buildCupertino(context);
    }
    return _buildMaterial(context);
  }

  Widget _buildMaterial(BuildContext context) {
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
                          decoration: const InputDecoration(
                            labelText: '结束',
                            prefixIcon: Icon(Icons.stop_outlined),
                            filled: true,
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

  Widget _buildCupertino(BuildContext context) {
    final date = _date.value;
    final startTime = _startTime.value;
    final endTime = _endTime.value;
    final enableNotification = _enableNotification.value;
    final notifyTime = _notifyTime.value;

    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return CupertinoTheme(
      data: CupertinoTheme.of(context),
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // iOS Action / Navigation Bar
              Container(
                height: 56,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(context).withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        '取消',
                        style: TextStyle(
                          fontSize: 16,
                          color: CupertinoColors.systemBlue.resolveFrom(context),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '添加日程',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                    const Spacer(),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      onPressed: _nameController.text.trim().isNotEmpty ? _submit : null,
                      child: Text(
                        '添加',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.systemBlue.resolveFrom(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content Area
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
                  child: Column(
                    children: [
                      _buildCupertinoCard([
                        CupertinoTextField(
                          controller: _nameController,
                          placeholder: '日程名称 *',
                          prefix: const Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Icon(CupertinoIcons.pencil, size: 20, color: CupertinoColors.systemGrey),
                          ),
                          decoration: null,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          placeholderStyle: TextStyle(
                            color: CupertinoColors.placeholderText.resolveFrom(context),
                            fontSize: 16,
                          ),
                          style: TextStyle(
                            color: CupertinoColors.label.resolveFrom(context),
                            fontSize: 16,
                          ),
                          clearButtonMode: OverlayVisibilityMode.editing,
                          textInputAction: TextInputAction.next,
                        ),
                        _buildCupertinoDivider(),
                        CupertinoTextField(
                          controller: _teacherController,
                          placeholder: '相关人员',
                          prefix: const Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Icon(CupertinoIcons.person, size: 20, color: CupertinoColors.systemGrey),
                          ),
                          decoration: null,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          placeholderStyle: TextStyle(
                            color: CupertinoColors.placeholderText.resolveFrom(context),
                            fontSize: 16,
                          ),
                          style: TextStyle(
                            color: CupertinoColors.label.resolveFrom(context),
                            fontSize: 16,
                          ),
                          clearButtonMode: OverlayVisibilityMode.editing,
                          textInputAction: TextInputAction.next,
                        ),
                        _buildCupertinoDivider(),
                        CupertinoTextField(
                          controller: _locationController,
                          placeholder: '地点',
                          prefix: const Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Icon(CupertinoIcons.location, size: 20, color: CupertinoColors.systemGrey),
                          ),
                          decoration: null,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          placeholderStyle: TextStyle(
                            color: CupertinoColors.placeholderText.resolveFrom(context),
                            fontSize: 16,
                          ),
                          style: TextStyle(
                            color: CupertinoColors.label.resolveFrom(context),
                            fontSize: 16,
                          ),
                          clearButtonMode: OverlayVisibilityMode.editing,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                        ),
                      ]),
                      const SizedBox(height: 20),

                      _buildCupertinoCard([
                        _buildCupertinoTapRow(
                          icon: CupertinoIcons.calendar,
                          label: '日期',
                          value: '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}  ${_weekdayLabel(date.weekday)}',
                          onTap: _pickDate,
                        ),
                        _buildCupertinoDivider(),
                        _buildCupertinoTapRow(
                          icon: CupertinoIcons.clock,
                          label: '开始时间',
                          value: startTime.format(context),
                          onTap: _pickStartTime,
                        ),
                        _buildCupertinoDivider(),
                        _buildCupertinoTapRow(
                          icon: CupertinoIcons.clock_fill,
                          label: '结束时间',
                          value: endTime.format(context),
                          onTap: _pickEndTime,
                        ),
                      ]),
                      const SizedBox(height: 20),

                      _buildCupertinoCard([
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              const Icon(CupertinoIcons.bell, size: 20, color: CupertinoColors.systemGrey),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '开启提醒',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: CupertinoColors.label.resolveFrom(context),
                                      ),
                                    ),
                                    Text(
                                      '在指定时间发送通知提醒',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              CupertinoSwitch(
                                value: enableNotification,
                                onChanged: (v) => _enableNotification.value = v,
                              ),
                            ],
                          ),
                        ),
                        if (enableNotification) ...[
                          _buildCupertinoDivider(),
                          _buildCupertinoTapRow(
                            icon: CupertinoIcons.bell_fill,
                            label: '提醒时间',
                            value: notifyTime.format(context),
                            onTap: _pickNotifyTime,
                          ),
                        ],
                      ]),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCupertinoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context).withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildCupertinoDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 48),
      child: Container(
        height: 0.5,
        color: CupertinoColors.separator.resolveFrom(context).withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildCupertinoTapRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: CupertinoColors.systemGrey),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              CupertinoIcons.chevron_forward,
              size: 16,
              color: CupertinoColors.tertiaryLabel.resolveFrom(context),
            ),
          ],
        ),
      ),
    );
  }

  String _weekdayLabel(int weekday) {
    const labels = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return labels[weekday];
  }

  bool get _isCupertino =>
      AdaptiveStyle.isCupertino(sl<SettingsController>().designStyle.value);

  Future<void> _pickDate() async {
    if (_isCupertino) {
      final picked = await _showCupertinoDatePicker(_date.value);
      if (picked != null) _date.value = picked;
    } else {
      final picked = await showDatePicker(
        context: context,
        initialDate: _date.value,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      if (picked != null) _date.value = picked;
    }
  }

  Future<void> _pickStartTime() async {
    final picked = _isCupertino
        ? await _showCupertinoTimePicker(_startTime.value)
        : await showTimePicker(context: context, initialTime: _startTime.value);
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
    final picked = _isCupertino
        ? await _showCupertinoTimePicker(_endTime.value)
        : await showTimePicker(context: context, initialTime: _endTime.value);
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
    final picked = _isCupertino
        ? await _showCupertinoTimePicker(_notifyTime.value)
        : await showTimePicker(context: context, initialTime: _notifyTime.value);
    if (picked != null) _notifyTime.value = picked;
  }

  Future<DateTime?> _showCupertinoDatePicker(DateTime initial) async {
    DateTime selected = initial;
    await showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 260,
        color: CupertinoColors.systemBackground.resolveFrom(ctx),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoButton(
                  child: const Text('完成'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initial,
                minimumDate: DateTime(2020),
                maximumDate: DateTime.now().add(const Duration(days: 365)),
                onDateTimeChanged: (d) => selected = d,
              ),
            ),
          ],
        ),
      ),
    );
    return selected;
  }

  Future<TimeOfDay?> _showCupertinoTimePicker(TimeOfDay initial) async {
    DateTime selected = DateTime(2000, 1, 1, initial.hour, initial.minute);
    await showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 260,
        color: CupertinoColors.systemBackground.resolveFrom(ctx),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoButton(
                  child: const Text('完成'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: selected,
                use24hFormat: true,
                onDateTimeChanged: (d) => selected = d,
              ),
            ),
          ],
        ),
      ),
    );
    return TimeOfDay(hour: selected.hour, minute: selected.minute);
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
