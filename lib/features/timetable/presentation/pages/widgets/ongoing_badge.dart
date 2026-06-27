import 'package:flutter/cupertino.dart';

/// A small "进行中" badge widget used in timetable cards and detail sheets.
Widget ongoingBadge(
  Color accent, {
  double fontSize = 11,
  double hPad = 7,
  double vPad = 3,
  Color? foreground,
}) {
  final fg = foreground ?? CupertinoColors.white;
  return Container(
    padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
    decoration: BoxDecoration(
      color: accent,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '进行中',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ],
    ),
  );
}
