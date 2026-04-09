typedef ParsedCourseTimeSlot = ({
  int weekday,
  int startSection,
  int endSection,
  int? startWeek,
  int? endWeek,
  String weekText,
});

final RegExp _slotReg = RegExp(r'星期([一二三四五六日天])\((\d{2})-(\d{2})小节\)');

List<ParsedCourseTimeSlot> parseCourseTimeSlots(String timeText) {
  final matches = _slotReg.allMatches(timeText).toList(growable: false);
  if (matches.isEmpty) {
    return const <ParsedCourseTimeSlot>[];
  }

  final result = <ParsedCourseTimeSlot>[];
  var cursor = 0;
  for (final m in matches) {
    final weekday = _weekdayFromChinese(m.group(1) ?? '');
    final startSection = int.tryParse(m.group(2) ?? '');
    final endSection = int.tryParse(m.group(3) ?? '');
    if (weekday == null || startSection == null || endSection == null) {
      cursor = m.end;
      continue;
    }

    final prefix = timeText.substring(cursor, m.start);
    final weekSpan = _parseWeekSpan(prefix);
    result.add((
      weekday: weekday,
      startSection: startSection,
      endSection: endSection,
      startWeek: weekSpan?.startWeek,
      endWeek: weekSpan?.endWeek,
      weekText: weekSpan?.weekText ?? '',
    ));

    cursor = m.end;
  }

  return result;
}

typedef _WeekSpan = ({int? startWeek, int? endWeek, String weekText});

_WeekSpan? _parseWeekSpan(String rawPrefix) {
  final text = rawPrefix
      .replaceAll('；', ';')
      .replaceAll('，', ',')
      .replaceAll('～', '-')
      .replaceAll('—', '-')
      .replaceAll('–', '-')
      .replaceAll('（周）', '周')
      .replaceAll('(周)', '周')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (text.isEmpty || !text.contains('周')) {
    return null;
  }

  final rangeMatch = RegExp(
    r'(?:第\s*)?(\d{1,2})\s*[-~至到]\s*(\d{1,2})\s*周',
  ).firstMatch(text);
  if (rangeMatch != null) {
    final start = int.tryParse(rangeMatch.group(1)!);
    final end = int.tryParse(rangeMatch.group(2)!);
    if (start != null && end != null) {
      return (
        startWeek: start < end ? start : end,
        endWeek: start < end ? end : start,
        weekText: rangeMatch.group(0)!,
      );
    }
  }

  final mixedMatch = RegExp(r'([\d\s,\-]+)\s*周').firstMatch(text);
  if (mixedMatch != null) {
    final body = mixedMatch.group(1) ?? '';
    final segments = body
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    final weeks = <int>[];
    for (final segment in segments) {
      final range = RegExp(r'^(\d{1,2})\s*-\s*(\d{1,2})$').firstMatch(segment);
      if (range != null) {
        final a = int.tryParse(range.group(1) ?? '');
        final b = int.tryParse(range.group(2) ?? '');
        if (a != null && b != null) {
          weeks.add(a < b ? a : b);
          weeks.add(a < b ? b : a);
        }
        continue;
      }

      final single = int.tryParse(segment);
      if (single != null) {
        weeks.add(single);
      }
    }

    if (weeks.isNotEmpty) {
      weeks.sort();
      return (
        startWeek: weeks.first,
        endWeek: weeks.last,
        weekText: '${mixedMatch.group(1)}周',
      );
    }
  }

  final singleMatch = RegExp(r'(?:第\s*)?(\d{1,2})\s*周').firstMatch(text);
  if (singleMatch != null) {
    final week = int.tryParse(singleMatch.group(1)!);
    if (week != null) {
      return (startWeek: week, endWeek: week, weekText: singleMatch.group(0)!);
    }
  }

  return null;
}

int? _weekdayFromChinese(String c) {
  switch (c) {
    case '一':
      return DateTime.monday;
    case '二':
      return DateTime.tuesday;
    case '三':
      return DateTime.wednesday;
    case '四':
      return DateTime.thursday;
    case '五':
      return DateTime.friday;
    case '六':
      return DateTime.saturday;
    case '日':
    case '天':
      return DateTime.sunday;
    default:
      return null;
  }
}
