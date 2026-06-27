import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Show a Cupertino-style date picker in a modal popup.
/// Returns the selected [DateTime] or `null` if dismissed.
Future<DateTime?> showCupertinoDatePickerModal(
  BuildContext context,
  DateTime initial, {
  DateTime? minimumDate,
  DateTime? maximumDate,
}) async {
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
              minimumDate: minimumDate ?? DateTime(2020),
              maximumDate:
                  maximumDate ?? DateTime.now().add(const Duration(days: 365)),
              onDateTimeChanged: (d) => selected = d,
            ),
          ),
        ],
      ),
    ),
  );
  return selected;
}

/// Show a Cupertino-style time picker in a modal popup.
/// Returns the selected [TimeOfDay] or `null` if dismissed.
Future<TimeOfDay?> showCupertinoTimePickerModal(
  BuildContext context,
  TimeOfDay initial,
) async {
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
