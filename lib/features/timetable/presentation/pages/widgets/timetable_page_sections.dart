import 'dart:typed_data';

import 'package:flutter/material.dart';

class TimetableControlPanel extends StatelessWidget {
  const TimetableControlPanel({
    super.key,
    required this.usernameController,
    required this.passwordController,
    required this.isLoading,
    required this.currentTeachingWeek,
    required this.onTeachingWeekChanged,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool isLoading;
  final int currentTeachingWeek;
  final ValueChanged<int> onTeachingWeekChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 860;
        final usernameField = TextField(
          controller: usernameController,
          enabled: !isLoading,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: '账号',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        );
        final passwordField = TextField(
          controller: passwordController,
          enabled: !isLoading,
          obscureText: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: '密码',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        );
        final weekOptions = List<int>.generate(30, (index) => index + 1);
        final selectedWeek = weekOptions.contains(currentTeachingWeek)
            ? currentTeachingWeek
            : 1;
        final weekField = DropdownButtonFormField<int>(
          initialValue: selectedWeek,
          items: weekOptions
              .map(
                (week) => DropdownMenuItem<int>(
                  value: week,
                  child: Text('当前周: 第$week周'),
                ),
              )
              .toList(growable: false),
          decoration: const InputDecoration(
            labelText: '当前周数',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: isLoading
              ? null
              : (value) {
                  if (value != null) {
                    onTeachingWeekChanged(value);
                  }
                },
        );

        if (wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: usernameField),
                  const SizedBox(width: 10),
                  Expanded(child: passwordField),
                  const SizedBox(width: 10),
                  SizedBox(width: 170, child: weekField),
                ],
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            usernameField,
            const SizedBox(height: 8),
            passwordField,
            const SizedBox(height: 8),
            weekField,
          ],
        );
      },
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
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final foregroundColor = isError
        ? colorScheme.onErrorContainer
        : hasData
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    if (!isError && !isLoading) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            isLoading
                ? Icons.hourglass_top_rounded
                : isError
                ? Icons.error_outline
                : Icons.info_outline,
            size: 18,
            color: foregroundColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              status,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

