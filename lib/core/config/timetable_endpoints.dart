class TimetableEndpoints {
  static const String proxyBaseUrl = String.fromEnvironment(
    'TIMETABLE_PROXY_BASE_URL',
    defaultValue: 'https://project-k70ln.vercel.app/',
  );
  static const String loginBaseUrl = 'http://202.119.81.112:8080';
  static const String targetUrl =
      'http://202.119.81.112:9080/njlgdx/xskb/xskb_list.do?Ves632DSdyV=NEW_XSD_PYGL';
}
