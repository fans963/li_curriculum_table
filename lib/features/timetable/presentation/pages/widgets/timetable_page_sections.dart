import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loading_indicator_m3e/loading_indicator_m3e.dart';
import 'package:m3e_core/m3e_core.dart';

class TimetableControlPanel extends StatefulWidget {
  const TimetableControlPanel({
    super.key,
    required this.usernameController,
    required this.passwordController,
    required this.isLoading,
    required this.currentTeachingWeek,
    required this.termStartMonday,
    required this.onTermStartDateChanged,
    this.onLoginPressed,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool isLoading;
  final int currentTeachingWeek;
  final DateTime? termStartMonday;
  final ValueChanged<DateTime> onTermStartDateChanged;
  final VoidCallback? onLoginPressed;

  @override
  State<TimetableControlPanel> createState() => _TimetableControlPanelState();
}

class _TimetableControlPanelState extends State<TimetableControlPanel> {
  late final TextEditingController _termStartController;

  @override
  void initState() {
    super.initState();
    _termStartController = TextEditingController(
      text: widget.termStartMonday != null
          ? DateFormat('yyyy-MM-dd').format(widget.termStartMonday!)
          : '未设置',
    );
  }

  @override
  void didUpdateWidget(covariant TimetableControlPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.termStartMonday != widget.termStartMonday) {
      _termStartController.text = widget.termStartMonday != null
          ? DateFormat('yyyy-MM-dd').format(widget.termStartMonday!)
          : '未设置';
    }
  }

  @override
  void dispose() {
    _termStartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
              enabled: !widget.isLoading,
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
              enabled: !widget.isLoading,
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
                  icon: widget.isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: LoadingIndicatorM3E(
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.cloud_sync_rounded),
                  label: Text(widget.isLoading ? '正在登录并同步信息...' : '一键登录并同步所有信息'),
                  size: M3EButtonSize.lg,
                  shape: M3EButtonShape.round,
                  onPressed: widget.isLoading ? null : widget.onLoginPressed,
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              readOnly: true,
              controller: _termStartController,
              enabled: !widget.isLoading,
              decoration: InputDecoration(
                labelText: '本学期开学日期',
                prefixIcon: const Icon(Icons.calendar_month_outlined),
                suffixIcon: const Icon(Icons.edit_calendar_outlined, size: 20),
                helperText: '当前推算为第 ${widget.currentTeachingWeek} 周',
                helperStyle: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                filled: true,
                fillColor: colorScheme.surface,
              ),
              onTap: () async {
                final initialDate = widget.termStartMonday ?? DateTime.now();
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

