import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:signals/signals_flutter.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_helpers.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/presentation/widgets/adaptive_date_picker.dart';
import 'package:li_curriculum_table/core/presentation/styles/styles.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
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
    this.onQrLoginPressed,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final ValueChanged<DateTime> onTermStartDateChanged;
  final ValueChanged<String> onCurrentTermChanged;
  final VoidCallback? onLoginPressed;
  final VoidCallback? onQrLoginPressed;

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
    final cs = colorScheme;
    final state = sl<TimetableController>().state.value;
    final settingsCtrl = sl<SettingsController>();
    final ds = settingsCtrl.state.value.designStyle;
    final style = UiStyleRegistry.resolve(ds);
    final concrete = UiStyleRegistry.resolveConcreteStyle(ds);
    final isGlass = concrete == DesignStyle.cupertino;
    final options = _getSemesterOptions();
    final currentTerm = settingsCtrl.currentTerm.value;
    if (currentTerm.isNotEmpty && !options.contains(currentTerm)) {
      options.insert(0, currentTerm);
    }

    Future<void> pickTermStartDate() async {
      final termStart = sl<TimetableController>().termStartMonday.value;
      final initialDate = termStart ?? DateTime.now();
      final pickedDate = await showAdaptiveDatePicker(
        context: context,
        designStyle: ds,
        initialDate: initialDate,
        firstDate: DateTime(initialDate.year - 1),
        lastDate: DateTime(initialDate.year + 1),
        helpText: '选择开学日期 (第一周周一)',
      );
      if (pickedDate != null && mounted) {
        widget.onTermStartDateChanged(pickedDate);
      }
    }

    return style.buildCard(
      context: context,
      borderRadius: 24,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isGlass
                  ? colorScheme.primary.withValues(alpha: 0.15)
                  : colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.primary.withValues(
                  alpha: isGlass ? 0.35 : 0.25,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '登录方式已更新',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: isGlass
                              ? colorScheme.primary
                              : colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '请使用「智慧理工服务门户」的账号和密码登录。',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isGlass
                              ? colorScheme.onSurface
                              : colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          adaptiveTextField(
            context: context,
            designStyle: ds,
            controller: widget.usernameController,
            enabled: !state.isLoading,
            textInputAction: TextInputAction.next,
            labelText: '智慧理工服务门户账号',
            prefixIcon: const Icon(Icons.account_circle_outlined),
            hintText: '请输入门户账号',
          ),
          const SizedBox(height: 12),
          adaptiveTextField(
            context: context,
            designStyle: ds,
            controller: widget.passwordController,
            enabled: !state.isLoading,
            obscureText: true,
            textInputAction: TextInputAction.done,
            labelText: '智慧理工服务门户密码',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            hintText: '请输入密码',
          ),
          if (widget.onLoginPressed != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: adaptiveButton(
                context: context,
                designStyle: ds,
                style: UiButtonStyle.filled,
                onPressed: state.isLoading ? null : widget.onLoginPressed,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (state.isLoading)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: adaptiveActivityIndicator(
                          context: context,
                          designStyle: ds,
                          size: 20,
                        ),
                      )
                    else
                      const Icon(Icons.cloud_sync_rounded),
                    const SizedBox(width: 8),
                    AutoSizeText(
                      state.isLoading ? '正在登录并同步信息...' : '一键登录并同步所有信息',
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (widget.onQrLoginPressed != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: adaptiveButton(
                context: context,
                designStyle: ds,
                style: UiButtonStyle.outlined,
                onPressed: state.isLoading ? null : widget.onQrLoginPressed,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_2_rounded),
                    SizedBox(width: 8),
                    Text('微信扫码登录'),
                  ],
                ),
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
          if (isGlass) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '本学期开学日期',
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) => GlassButton.custom(
                width: constraints.maxWidth,
                height: 52,
                shape: const LiquidRoundedSuperellipse(borderRadius: 14),
                enabled: !state.isLoading,
                onTap: pickTermStartDate,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.calendar, size: 20),
                    const SizedBox(width: 10),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _termStartController,
                      builder: (context, value, _) => Text(
                        value.text.isEmpty ? '选择开学日期' : value.text,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '当前推算为第 ${state.currentTeachingWeek} 周',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ] else
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
                filled: isGlass,
                fillColor: cs.surface.withValues(alpha: isGlass ? 0.2 : 1.0),
                border: isGlass
                    ? OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.4),
                        ),
                      )
                    : null,
              ),
              onTap: pickTermStartDate,
            ),
        ],
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
    final ds = sl<SettingsController>().state.value.designStyle;
    final style = UiStyleRegistry.resolve(ds);
    final isError = _looksLikeError(status);

    final foregroundColor = isError
        ? colorScheme.onErrorContainer
        : hasData
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurfaceVariant;

    if (!isError && !isLoading && status.isEmpty) {
      return const SizedBox.shrink();
    }

    return style.buildCard(
      context: context,
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (isLoading)
            SizedBox(
              width: 18,
              height: 18,
              child: adaptiveActivityIndicator(
                context: context,
                designStyle: ds,
                size: 18,
              ),
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

  Future<void> _showGlassTermPicker() async {
    if (widget.isLoading || widget.options.isEmpty) return;
    final cs = Theme.of(context).colorScheme;
    final selected = await GlassDialog.show<String>(
      context: context,
      title: '选择当前学期',
      maxWidth: 380,
      barrierDismissible: true,
      content: SizedBox(
        height: (MediaQuery.sizeOf(context).height * 0.45).clamp(180.0, 380.0),
        child: CupertinoScrollbar(
          child: ListView.builder(
            itemCount: widget.options.length,
            itemExtent: 48,
            itemBuilder: (itemContext, index) {
              final term = widget.options[index];
              final isSelected = term == widget.currentTerm;
              return CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                borderRadius: BorderRadius.circular(12),
                onPressed: () => Navigator.of(itemContext).pop(term),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cs.primary.withValues(alpha: 0.14)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            term,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: isSelected ? cs.primary : cs.onSurface,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                          ),
                        ),
                        if (isSelected)
                          Icon(CupertinoIcons.checkmark, color: cs.primary),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      actions: [
        GlassDialogAction(
          label: '取消',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
    if (selected != null && mounted) widget.onSelected(selected);
  }

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
    if (old.options != widget.options ||
        old.currentTerm != widget.currentTerm) {
      _syncItems();
    }
  }

  void _syncItems() {
    _syncing.value = true;
    _controller.setItems(
      widget.options
          .map(
            (opt) => M3EDropdownItem(
              label: opt,
              value: opt,
              selected: opt == widget.currentTerm,
            ),
          )
          .toList(),
    );
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
    final concrete = UiStyleRegistry.resolveConcreteStyle(ds);

    if (concrete == DesignStyle.cupertino) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '当前学期',
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) => GlassButton.custom(
              width: constraints.maxWidth,
              height: 52,
              shape: const LiquidRoundedSuperellipse(borderRadius: 14),
              enabled: !widget.isLoading && widget.options.isNotEmpty,
              onTap: _showGlassTermPicker,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.calendar, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    widget.currentTerm.isNotEmpty
                        ? widget.currentTerm
                        : '选择当前学期',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '格式：学年-学期（1 秋季、2 春季、3 暑期）',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      );
    }

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
          dropdownStyle: M3EDropdownPanelStyle(
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
