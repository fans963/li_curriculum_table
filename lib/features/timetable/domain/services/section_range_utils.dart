/// Mapping from section indices to "Large Session" ranges as used in the grid.
const Map<String, (int, int)> largeSessionMapping = {
  '第一大节': (1, 3),
  '第二大节': (4, 5),
  '第三大节': (6, 7),
  '第四大节': (8, 10),
  '第五大节': (11, 13),
  '中午': (14, 14),
};

/// Detect which "Large Session" a specific section belongs to.
/// Returns the (start, end) range of that session.
(int, int)? getLargeSessionRangeForSection(int section) {
  for (final range in largeSessionMapping.values) {
    if (section >= range.$1 && section <= range.$2) {
      return range;
    }
  }
  return null;
}

/// Parse a row header text (like "第一大节") into its section range.
(int, int)? sectionRangeFromRowHeader(String rowHeaderText) {
  final normalized = rowHeaderText.replaceAll(RegExp(r'\s+'), '');
  for (final entry in largeSessionMapping.entries) {
    if (normalized.contains(entry.key)) {
      return entry.value;
    }
  }
  return null;
}
