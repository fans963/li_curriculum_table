import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:li_curriculum_table/core/presentation/styles/styles.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';

/// Opens the date selection control belonging to the active design style.
Future<DateTime?> showAdaptiveDatePicker({
  required BuildContext context,
  required DesignStyle designStyle,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? helpText,
}) {
  if (UiStyleRegistry.resolveConcreteStyle(designStyle) !=
      DesignStyle.cupertino) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: helpText,
    );
  }

  final first = DateTime(firstDate.year, firstDate.month, firstDate.day);
  final last = DateTime(lastDate.year, lastDate.month, lastDate.day, 23, 59);
  final initial = DateTime(
    initialDate.year,
    initialDate.month,
    initialDate.day,
  );
  var selected = initial.isBefore(first)
      ? first
      : initial.isAfter(last)
      ? DateTime(last.year, last.month, last.day)
      : initial;

  return GlassSheet.show<DateTime>(
    context: context,
    isScrollable: false,
    settings: const LiquidGlassSettings(
      blur: 10,
      thickness: 10,
      glassColor: Color.fromRGBO(255, 255, 255, 0.12),
      lightAngle: 0.75 * math.pi,
      lightIntensity: 0.7,
      ambientStrength: 0.4,
      saturation: 1.2,
      refractiveIndex: 0.15,
      chromaticAberration: 0,
    ),
    builder: (sheetContext) {
      final colors = Theme.of(sheetContext).colorScheme;
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    helpText ?? '选择日期',
                    style: Theme.of(sheetContext).textTheme.titleMedium
                        ?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  onPressed: () => Navigator.of(sheetContext).pop(selected),
                  child: const Text('完成'),
                ),
              ],
            ),
            SizedBox(
              height: 220,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: selected,
                minimumDate: first,
                maximumDate: last,
                onDateTimeChanged: (date) => selected = date,
              ),
            ),
          ],
        ),
      );
    },
  );
}
