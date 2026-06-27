import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loading_indicator_m3e/loading_indicator_m3e.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:signals/signals_flutter.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/timetable/presentation/state/timetable_controller.dart';

class TimetableControlPanel extends SignalStatefulWidget {
  const TimetableControlPanel({
    super.key,
    required this.usernameController,
    required this.passwordController,
    required this.onTermStartDateChanged,
    required this.onCurrentTermChanged,
    this.onLoginPressed,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final ValueChanged<DateTime> onTermStartDateChanged;
  final ValueChanged<String> onCurrentTermChanged;
  final VoidCallback? onLoginPressed;

  @override
  State<TimetableControlPanel> createState() => _TimetableControlPanelState();
}

class _TimetableControlPanelState extends State<TimetableControlPanel> {
  late final TextEditingController _termStartController;
  late final EffectCleanup _syncTermStart;

  @override
  void initState() {
    super.initState();
    final timetableCtrl = sl<TimetableController>();

    _termStartController = TextEditingController(
      text: _formatTermStart(timetableCtrl.termStartMonday.value),
    );

    // Reactively sync term start date display from signal
    _syncTermStart = effect(() {
      final newText = _formatTermStart(timetableCtrl.termStartMonday.value);
      if (_termStartController.text != newText) {
        _termStartController.text = newText;
      }
    });
  }

  String _formatTermStart(DateTime? date) =>
      date != null ? DateFormat('yyyy-MM-dd').format(date) : '未设置';

  @override
  void dispose() {
    _syncTermStart();
    _termStartController.dispose();
    super.dispose();
  }

  List<String> _getSemesterOptions() {
    final now = DateTime.now();
    final int currentStartYear = now.month >= 9 ? now.year : now.year - 1;
    final List<String> options = [];
    for (int y = currentStartYear + 1; y >= currentStartYear - 4; y--) {
      options.add('$y-${y + 1}-3');
      options.add('$y-${y + 1}-2');
      options.add('$y-${y + 1}-1');
    }
    return options;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = sl<TimetableController>().state.value;
    final settingsCtrl = sl<SettingsController>();
    final options = _getSemesterOptions();
    final currentTerm = settingsCtrl.currentTerm.value;
    if (currentTerm.isNotEmpty && !options.contains(currentTerm)) {
      options.insert(0, currentTerm);
    }

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: widget.usernameController,
              enabled: !state.isLoading,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: '教务系统账号',
                prefixIcon: const Icon(Icons.account_circle_outlined),
                hintText: '请输入学号',
                filled: true,
                fillColor: colorScheme.surface,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: widget.passwordController,
              enabled: !state.isLoading,
              obscureText: true,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: '登录密码',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                hintText: '请输入密码',
                filled: true,
                fillColor: colorScheme.surface,
              ),
            ),
            if (widget.onLoginPressed != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: M3EFilledButton.icon(
                  icon: state.isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: LoadingIndicatorM3E(
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.cloud_sync_rounded),
                  label: AutoSizeText(state.isLoading ? '正在登录并同步信息...' : '一键登录并同步所有信息', maxLines: 1),
                  size: M3EButtonSize.lg,
                  shape: M3EButtonShape.round,
                  onPressed: state.isLoading ? null : widget.onLoginPressed,
                ),
              ),
            ],
            const SizedBox(height: 12),
            _TermDropdown(
              options: options,
              currentTerm: currentTerm,
              isLoading: state.isLoading,
              onSelected: widget.onCurrentTermChanged,
            ),
            const SizedBox(height: 12),
            TextFormField(
              readOnly: true,
              controller: _termStartController,
              enabled: !state.isLoading,
              decoration: InputDecoration(
                labelText: '本学期开学日期',
                prefixIcon: const Icon(Icons.calendar_month_outlined),
                suffixIcon: const Icon(Icons.edit_calendar_outlined, size: 20),
                helperText: '当前推算为第 ${state.currentTeachingWeek} 周',
                helperStyle: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                filled: true,
                fillColor: colorScheme.surface,
              ),
              onTap: () async {
                final termStart = sl<TimetableController>().termStartMonday.value;
                final initialDate = termStart ?? DateTime.now();
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: DateTime(initialDate.year - 1),
                  lastDate: DateTime(initialDate.year + 1),
                  helpText: '选择开学日期 (第一周周一)',
                );
                if (pickedDate != null) {
                  widget.onTermStartDateChanged(pickedDate);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class TimetableStatusBanner extends StatelessWidget {
  const TimetableStatusBanner({
    super.key,
    required this.status,
    required this.isLoading,
    required this.hasData,
  });

  final String status;
  final bool isLoading;
  final bool hasData;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isError = _looksLikeError(status);

    final backgroundColor = isError
        ? colorScheme.errorContainer
        : hasData
        ? colorScheme.secondaryContainer.withValues(alpha: 0.4)
        : colorScheme.surfaceContainerHighest;
    final foregroundColor = isError
        ? colorScheme.onErrorContainer
        : hasData
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurfaceVariant;

    if (!isError && !isLoading && status.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      color: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: LoadingIndicatorM3E(),
              )
            else
              Icon(
                isError ? Icons.error_outline : Icons.info_outline,
                size: 20,
                color: foregroundColor,
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                status,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _looksLikeError(String value) {
    const keywords = ['失败', '错误', '异常', '不可用', 'timeout', 'error'];
    final lower = value.toLowerCase();
    return keywords.any((k) => lower.contains(k));
  }
}

class _TermDropdown extends StatefulWidget {
  final List<String> options;
  final String currentTerm;
  final bool isLoading;
  final ValueChanged<String> onSelected;

  const _TermDropdown({
    required this.options,
    required this.currentTerm,
    required this.isLoading,
    required this.onSelected,
  });

  @override
  State<_TermDropdown> createState() => _TermDropdownState();
}

class _TermDropdownState extends State<_TermDropdown> {
  late final M3EDropdownController<String> _controller;
  final _syncing = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _controller = M3EDropdownController<String>();
    _controller.initialize();
    _syncItems();
  }

  @override
  void didUpdateWidget(_TermDropdown old) {
    super.didUpdateWidget(old);
    if (old.options != widget.options || old.currentTerm != widget.currentTerm) {
      _syncItems();
    }
  }

  void _syncItems() {
    _syncing.value = true;
    _controller.setItems(widget.options.map((opt) => M3EDropdownItem(
      label: opt,
      value: opt,
      selected: opt == widget.currentTerm,
    )).toList());
    if (widget.currentTerm.isNotEmpty) {
      _controller.selectWhere((item) => item.value == widget.currentTerm);
    }
    _syncing.value = false;
  }

  @override
  void dispose() {
    _syncing.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ds = sl<SettingsController>().state.value.designStyle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        M3EDropdownMenu<String>(
          singleSelect: true,
          showChipAnimation: false,
          items: const [],
          controller: _controller,
          enabled: !widget.isLoading,
          onSelectionChanged: (items) {
            if (!_syncing.value && items.isNotEmpty) {
              widget.onSelected(items.first.value);
            }
          },
          containerRadius: 16,
          fieldStyle: M3EDropdownFieldStyle(
            hintText: '当前学期',
            prefixIcon: Icon(AppIcons.school(ds), size: 18),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: BorderSide(color: cs.outlineVariant, width: 0.5),
        focusedBorder: BorderSide(color: cs.primary, width: 1),
        borderRadius: BorderRadius.circular(12),
        selectedBorderRadius: 12,
      ),
      dropdownStyle: M3EDropdownStyle(
        maxHeight: 300,
        containerRadius: 16,
      ),
      itemStyle: M3EDropdownItemStyle(
        outerRadius: 12,
        innerRadius: 6,
        selectedIcon: Icon(Icons.check, size: 18, color: cs.primary),
      ),
    ),
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 4),
          child: Text(
            '格式: 学年-学期 (1秋季 2春季 3暑期小学期)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

