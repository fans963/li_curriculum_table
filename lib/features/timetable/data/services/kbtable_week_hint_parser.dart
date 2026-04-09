import 'package:html/parser.dart' as html_parser;
import 'package:li_curriculum_table/features/timetable/domain/services/section_range_utils.dart';

class KbtableWeekHint {
  const KbtableWeekHint({
    required this.courseName,
    required this.weekday,
    required this.startSection,
    required this.endSection,
    required this.weekText,
  });

  final String courseName;
  final int weekday;
  final int startSection;
  final int endSection;
  final String weekText;
}

/// Extract week hints from the visual timetable grid (`#kbtable`).
///
/// The `dataList` table does not include week ranges, while `kbtable` does.
List<KbtableWeekHint> parseKbtableWeekHints(String htmlContent) {
  final document = html_parser.parse(htmlContent);
  final kbtable = document.querySelector('table#kbtable');
  if (kbtable == null) {
    return const <KbtableWeekHint>[];
  }

  final result = <KbtableWeekHint>[];
  final rows = kbtable.querySelectorAll('tr');
  if (rows.length <= 1) {
    return const <KbtableWeekHint>[];
  }

  for (final row in rows.skip(1)) {
    final sectionRange = sectionRangeFromRowHeader(
      row.querySelector('th')?.text ?? '',
    );
    if (sectionRange == null) {
      continue;
    }

    final cells = row.querySelectorAll('td');
    for (var i = 0; i < cells.length && i < 7; i++) {
      final weekday = DateTime.monday + i;
      final compactDiv = cells[i].querySelector('div.kbcontent1');
      if (compactDiv == null) {
        continue;
      }

      final cellText = _normalizeCellText(compactDiv.innerHtml);
      if (cellText.isEmpty) {
        continue;
      }

      for (final match in _cellEntryReg.allMatches(cellText)) {
        final courseName = (match.group(1) ?? '').trim();
        final weekBody = (match.group(2) ?? '').replaceAll(' ', '');
        if (courseName.isEmpty || weekBody.isEmpty) {
          continue;
        }

        result.add(
          KbtableWeekHint(
            courseName: courseName,
            weekday: weekday,
            startSection: sectionRange.$1,
            endSection: sectionRange.$2,
            weekText: '$weekBody(周)',
          ),
        );
      }
    }
  }

  return result;
}

final RegExp _cellEntryReg = RegExp(
  r'([^\r\n]+?)\s*([0-9]{1,2}(?:\s*-\s*[0-9]{1,2})?(?:\s*,\s*[0-9]{1,2}(?:\s*-\s*[0-9]{1,2})?)*)\s*\(周\)',
  multiLine: true,
);


String _normalizeCellText(String rawHtml) {
  final withBreaks = rawHtml
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll('&nbsp;', ' ');
  final raw = html_parser.parseFragment(withBreaks).text ?? '';

  return raw
      .replaceAll('\r', '\n')
      .replaceAll('----------------------', '\n')
      .replaceAll('---------------------', '\n')
      .replaceAll(RegExp(r'\n+'), '\n')
      .replaceAll(RegExp(r'[\t\u00A0]+'), ' ')
      .trim();
}
