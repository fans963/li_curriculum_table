class TimetableEndpoints {
  static const String proxyBaseUrl = String.fromEnvironment(
    'TIMETABLE_PROXY_BASE_URL',
    defaultValue: 'https://schedule-fetcher.enbofan663.workers.dev/',
  );
  static const String webLoginBaseUrl = 'http://api.fans963blog.asia:8080';
  static const String webTargetUrl =
      'http://api.fans963blog.asia:9080/njlgdx/xskb/xskb_list.do?Ves632DSdyV=NEW_XSD_PYGL';

  static const String directLoginBaseUrl = 'http://202.119.81.113:8080';
  static const String directTargetUrl =
      'http://202.119.81.113:9080/njlgdx/xskb/xskb_list.do?Ves632DSdyV=NEW_XSD_PYGL';
}
