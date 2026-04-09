typedef SectionClock = (int, int);

typedef SectionTimeRange = ({SectionClock start, SectionClock end});

/// Single source of truth for section-to-clock mapping.
const Map<int, SectionTimeRange> sectionTimeMapping = <int, SectionTimeRange>{
  1: (start: (8, 0), end: (8, 45)),
  2: (start: (8, 50), end: (9, 35)),
  3: (start: (9, 40), end: (10, 25)),
  4: (start: (10, 40), end: (11, 25)),
  5: (start: (11, 30), end: (12, 15)),
  6: (start: (14, 0), end: (14, 45)),
  7: (start: (14, 50), end: (15, 35)),
  8: (start: (15, 50), end: (16, 35)),
  9: (start: (16, 40), end: (17, 25)),
  10: (start: (17, 30), end: (18, 15)),
  11: (start: (19, 0), end: (19, 45)),
  12: (start: (19, 50), end: (20, 35)),
  13: (start: (20, 40), end: (21, 25)),
};

SectionClock? startClockOfSection(int section) {
  return sectionTimeMapping[section]?.start;
}

SectionClock? endClockOfSection(int section) {
  return sectionTimeMapping[section]?.end;
}

double get timetableDisplayStartHour {
  final values = sectionTimeMapping.values;
  if (values.isEmpty) {
    return 8;
  }
  return values
      .map((range) => range.start.$1 + range.start.$2 / 60)
      .reduce((a, b) => a < b ? a : b);
}

double get timetableDisplayEndHour {
  final values = sectionTimeMapping.values;
  if (values.isEmpty) {
    return 22;
  }
  return values
      .map((range) => range.end.$1 + range.end.$2 / 60)
      .reduce((a, b) => a > b ? a : b);
}
