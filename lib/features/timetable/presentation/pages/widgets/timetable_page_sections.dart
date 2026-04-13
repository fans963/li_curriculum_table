import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimetableControlPanel extends StatelessWidget {
  const TimetableControlPanel({
    super.key,
    required this.usernameController,
    required this.passwordController,
    required this.isLoading,
    required this.currentTeachingWeek,
    required this.termStartMonday,
    required this.onTermStartDateChanged,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool isLoading;
  final int currentTeachingWeek;
  final DateTime? termStartMonday;
  final ValueChanged<DateTime> onTermStartDateChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: usernameController,
              enabled: !isLoading,
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
              controller: passwordController,
              enabled: !isLoading,
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
            const SizedBox(height: 12),
            TextFormField(
              readOnly: true,
              controller: TextEditingController(
                text: termStartMonday != null
                    ? DateFormat('yyyy-MM-dd').format(termStartMonday!)
                    : '未设置',
              ),
              enabled: !isLoading,
              decoration: InputDecoration(
                labelText: '本学期开学日期 (第一周周一)',
                prefixIcon: const Icon(Icons.calendar_month_outlined),
                suffixIcon: const Icon(Icons.edit_calendar_outlined, size: 20),
                helperText: '当前推算为第 $currentTeachingWeek 周',
                helperStyle: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                filled: true,
                fillColor: colorScheme.surface,
              ),
              onTap: () async {
                final initialDate = termStartMonday ?? DateTime.now();
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: DateTime(initialDate.year - 1),
                  lastDate: DateTime(initialDate.year + 1),
                  helpText: '选择开学日期 (第一周周一)',
                );
                if (pickedDate != null) {
                  onTermStartDateChanged(pickedDate);
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
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

class TimetableSummaryItem {
  const TimetableSummaryItem({required this.label, required this.value});

  final String label;
  final String value;
}

class TimetableSummaryChip extends StatelessWidget {
  const TimetableSummaryChip({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TimetableEmptyCalendarTip extends StatelessWidget {
  const TimetableEmptyCalendarTip({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_note, size: 34, color: Colors.grey.shade500),
          const SizedBox(height: 8),
          Text('暂无课表数据', style: textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('请先输入账号密码并执行抓取。', style: textTheme.bodySmall),
        ],
      ),
    );
  }
}
