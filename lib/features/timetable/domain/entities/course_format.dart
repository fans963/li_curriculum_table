/// The delivery format of a course.
enum CourseFormat {
  /// Traditional in-person classroom course.
  offline,

  /// Synchronous online course with fixed schedule (直播).
  liveOnline,

  /// Asynchronous online course without fixed time slots (录播).
  asyncOnline,

  /// Mixed — some sessions online, some offline.
  hybrid,
}

/// Extension for human-readable labels.
extension CourseFormatLabel on CourseFormat {
  String get label {
    switch (this) {
      case CourseFormat.offline:
        return '线下课';
      case CourseFormat.liveOnline:
        return '直播课';
      case CourseFormat.asyncOnline:
        return '录播课';
      case CourseFormat.hybrid:
        return '混合课';
    }
  }
}

/// User-defined override for a course's online/offline classification.
///
/// Since the academic system does not natively distinguish online courses,
/// users can manually mark a course and provide platform details. This
/// override is persisted locally via [CourseOnlineService].
class CourseFormatOverride {
  final CourseFormat format;
  final String? platform;
  final String? link;
  final String? meetingId;

  const CourseFormatOverride({
    required this.format,
    this.platform,
    this.link,
    this.meetingId,
  });

  bool get isOnline => format != CourseFormat.offline;

  /// Human-readable label for the format.
  String get label {
    switch (format) {
      case CourseFormat.offline:
        return '线下课';
      case CourseFormat.liveOnline:
        return '直播课';
      case CourseFormat.asyncOnline:
        return '录播课';
      case CourseFormat.hybrid:
        return '混合课';
    }
  }

  Map<String, dynamic> toJson() => {
    'format': format.name,
    if (platform != null) 'platform': platform,
    if (link != null) 'link': link,
    if (meetingId != null) 'meetingId': meetingId,
  };

  factory CourseFormatOverride.fromJson(Map<String, dynamic> json) {
    return CourseFormatOverride(
      format: CourseFormat.values.firstWhere(
        (f) => f.name == json['format'],
        orElse: () => CourseFormat.offline,
      ),
      platform: json['platform'] as String?,
      link: json['link'] as String?,
      meetingId: json['meetingId'] as String?,
    );
  }
}
