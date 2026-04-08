import 'dart:convert';

import 'package:curriculum_table/src/table_getter/ddddocr.dart';
import 'package:curriculum_table/src/table_getter/http_client_factory.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;

class ScheduleFetchResult {
  ScheduleFetchResult({
    required this.verifyCode,
    required this.loginLikelySuccess,
    required this.html,
    required this.headers,
    required this.rows,
    required this.captchaBytes,
  });

  final String verifyCode;
  final bool loginLikelySuccess;
  final String html;
  final List<String> headers;
  final List<List<String>> rows;
  final Uint8List captchaBytes;
}

class ScheduleFetchException implements Exception {
  ScheduleFetchException({
    required this.message,
    this.cause,
  });

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class PachongClient {
  PachongClient({
    Dio? httpClient,
    this.loginBaseUrl = 'http://202.119.81.112:8080',
    this.targetUrl =
        'http://202.119.81.112:9080/njlgdx/xskb/xskb_list.do?Ves632DSdyV=NEW_XSD_PYGL',
    this.proxyBaseUrl = 'https://table-getter.enbofan663.workers.dev/',
  }) : _http = httpClient ?? createPachongHttpClient();

  final Dio _http;
  final String loginBaseUrl;
  final String targetUrl;
  final String proxyBaseUrl;

  Future<ScheduleFetchResult> loginAndFetchSchedule({
    required String username,
    required String password,
    int maxAttempts = 5,
  }) async {
    final ocrCommon = await DdddOcr.createCommon();

    var finalVerifyCode = '';
    var finalCaptchaBytes = Uint8List(0);
    var finalHtml = '';
    var finalHeaders = <String>[];
    var finalRows = <List<String>>[];
    var loginLikelySuccess = false;

    try {
      for (var attempt = 1; attempt <= maxAttempts; attempt++) {
        final start = await (kIsWeb ? _startRemoteSession() : _startDirectSession());

        final captchaBytes = start.captchaBytes;
        final commonCode =
            (await ocrCommon.classification(captchaBytes, alnumOnly: true)).trim();
        final verifyCode = commonCode;
        if (!_isValidVerifyCode(verifyCode)) {
          continue;
        }

        final submit = await (kIsWeb
            ? _submitRemoteSession(
                session: start.session,
                username: username,
                password: password,
                verifyCode: verifyCode,
              )
            : _submitDirectSession(
                session: start.session,
                username: username,
                password: password,
                verifyCode: verifyCode,
              ));

        final html = submit.html;
        final parsed = parseSchedule(html);
        final headers = parsed.$1;
        final rows = parsed.$2;

        finalVerifyCode = verifyCode;
        finalCaptchaBytes = captchaBytes;
        finalHtml = html;
        finalHeaders = headers;
        finalRows = rows;
        loginLikelySuccess = html.contains('理论课表') || rows.isNotEmpty;

        if (loginLikelySuccess) {
          break;
        }
      }

      if (finalVerifyCode.isEmpty) {
        throw StateError('验证码识别结果无效（非4位字母数字）。');
      }

      return ScheduleFetchResult(
        verifyCode: finalVerifyCode,
        loginLikelySuccess: loginLikelySuccess,
        html: finalHtml,
        headers: finalHeaders,
        rows: finalRows,
        captchaBytes: finalCaptchaBytes,
      );
    } on ScheduleFetchException {
      rethrow;
    } catch (e) {
      throw ScheduleFetchException(
        message: '抓取流程异常: $e',
        cause: e,
      );
    } finally {
      await ocrCommon.close();
    }
  }

  bool _isValidVerifyCode(String code) {
    return RegExp(r'^[A-Za-z0-9]{4}$').hasMatch(code.trim());
  }

  (List<String>, List<List<String>>) parseSchedule(String htmlContent) {
    final document = html_parser.parse(htmlContent);
    final table = document.querySelector('table#dataList');
    if (table == null) {
      return (<String>[], <List<String>>[]);
    }

    final ths = table.querySelectorAll('th');
    final headers = ths.map((e) => e.text.trim()).toList(growable: false);

    final rows = <List<String>>[];
    final trs = table.querySelectorAll('tr');
    for (var i = 1; i < trs.length; i++) {
      final tds = trs[i].querySelectorAll('td');
      if (tds.isEmpty) {
        continue;
      }
      final row = tds
          .map((e) => e.text.replaceAll('\r', '').replaceAll('\n', ' ').trim())
          .toList(growable: false);
      rows.add(row);
    }

    return (headers, rows);
  }

  Future<_RemoteStartResponse> _startRemoteSession() async {
    final data = await _postJson(
      _buildRemoteUri('/api/session/start'),
      <String, dynamic>{'loginBaseUrl': loginBaseUrl},
    );

    final captchaBase64 = (data['captchaBase64'] as String?) ?? '';
    if (captchaBase64.isEmpty) {
      throw StateError('远端未返回验证码图片');
    }

    final session = (data['session'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    return _RemoteStartResponse(
      captchaBytes: Uint8List.fromList(base64Decode(captchaBase64)),
      session: session,
    );
  }

  Future<_RemoteStartResponse> _startDirectSession() async {
    final cookies = <String, String>{};

    final loginInitUri = Uri.parse(loginBaseUrl).resolve('/');
    final loginInitRes = await _http.getUri<List<int>>(
      loginInitUri,
      options: _directOptions(responseType: ResponseType.bytes),
    );
    _mergeCookies(cookies, loginInitRes.headers.map['set-cookie']);

    final captchaUri = Uri.parse(loginBaseUrl)
      .resolve('/verifycode.servlet?t=${DateTime.now().millisecondsSinceEpoch}');
    final captchaRes = await _http.getUri<List<int>>(
      captchaUri,
      options: _directOptions(
        responseType: ResponseType.bytes,
        headers: _cookieHeaders(cookies),
      ),
    );
    _mergeCookies(cookies, captchaRes.headers.map['set-cookie']);

    final captchaBytes = Uint8List.fromList(captchaRes.data ?? const <int>[]);
    if (captchaBytes.isEmpty) {
      throw StateError('直连未获取到验证码图片');
    }

    return _RemoteStartResponse(
      captchaBytes: captchaBytes,
      session: <String, dynamic>{'cookies': cookies},
    );
  }

  Future<_RemoteSubmitResponse> _submitRemoteSession({
    required Map<String, dynamic> session,
    required String username,
    required String password,
    required String verifyCode,
  }) async {
    final data = await _postJson(
      _buildRemoteUri('/api/session/submit'),
      <String, dynamic>{
        'loginBaseUrl': loginBaseUrl,
        'targetUrl': targetUrl,
        'username': username,
        'password': password,
        'verifyCode': verifyCode,
        'session': session,
      },
    );

    final html = (data['html'] as String?) ?? '';
    return _RemoteSubmitResponse(html: html);
  }

  Future<_RemoteSubmitResponse> _submitDirectSession({
    required Map<String, dynamic> session,
    required String username,
    required String password,
    required String verifyCode,
  }) async {
    final cookies = (session['cookies'] as Map?)?.cast<String, String>() ??
        <String, String>{};
    final loginCandidates = <Uri>[
      Uri.parse(loginBaseUrl).resolve('/Logon.do?method=logon'),
      Uri.parse(loginBaseUrl).resolve('/njlgdx/Logon.do?method=logon'),
    ];

    for (final loginUri in loginCandidates) {
      final loginRes = await _http.postUri<List<int>>(
        loginUri,
        data: <String, String>{
          'USERNAME': username,
          'PASSWORD': password,
          'useDogCode': '',
          'RANDOMCODE': verifyCode.trim(),
        },
        options: Options(
          responseType: ResponseType.bytes,
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: false,
          maxRedirects: 0,
          headers: <String, String>{
            ..._cookieHeaders(cookies),
            'Referer': loginUri.toString(),
          },
        ),
      );
      _mergeCookies(cookies, loginRes.headers.map['set-cookie']);
      final location = loginRes.headers.value('location') ?? '';

      var redirectUrl = location;
      for (var i = 1; i <= 5; i++) {
        if (redirectUrl.isEmpty) {
          break;
        }

        final redirectUri = Uri.parse(loginBaseUrl).resolve(redirectUrl);
        final redirectRes = await _http.getUri<List<int>>(
          redirectUri,
          options: _directOptions(
            responseType: ResponseType.bytes,
            headers: _cookieHeaders(cookies),
          ),
        );
        _mergeCookies(cookies, redirectRes.headers.map['set-cookie']);
        final nextLocation = redirectRes.headers.value('location') ?? '';

        final status = redirectRes.statusCode ?? 0;
        if (status < 300 || status >= 400 || nextLocation.isEmpty) {
          break;
        }
        redirectUrl = nextLocation;
      }

      // If cookies changed or endpoint redirected, keep current cookie jar and continue.
      if (location.isNotEmpty) {
        break;
      }
    }

    final targetUri = Uri.parse(targetUrl);
    final targetRes = await _http.getUri<List<int>>(
      targetUri,
      options: _directOptions(
        responseType: ResponseType.bytes,
        headers: _cookieHeaders(cookies),
      ),
    );
    _mergeCookies(cookies, targetRes.headers.map['set-cookie']);

    final html = utf8.decode(targetRes.data ?? const <int>[], allowMalformed: true);
    return _RemoteSubmitResponse(html: html);
  }

  Map<String, String> _cookieHeaders(Map<String, String> cookies) {
    if (cookies.isEmpty) {
      return const <String, String>{};
    }
    final cookieHeader = cookies.entries
        .map((e) => '${e.key}=${e.value}')
        .join('; ');
    return <String, String>{'Cookie': cookieHeader};
  }

  void _mergeCookies(Map<String, String> jar, List<String>? setCookieValues) {
    if (setCookieValues == null || setCookieValues.isEmpty) {
      return;
    }
    for (final raw in setCookieValues) {
      final first = raw.split(';').first.trim();
      if (first.isEmpty || !first.contains('=')) {
        continue;
      }
      final idx = first.indexOf('=');
      final name = first.substring(0, idx).trim();
      final value = first.substring(idx + 1).trim();
      if (name.isEmpty) {
        continue;
      }
      jar[name] = value;
    }
  }

  Options _directOptions({
    required ResponseType responseType,
    Map<String, String>? headers,
  }) {
    return Options(
      responseType: responseType,
      followRedirects: false,
      maxRedirects: 0,
      headers: headers,
    );
  }

  Future<Map<String, dynamic>> _postJson(
    Uri uri,
    Map<String, dynamic> body,
  ) async {
    final response = await _http.postUri<String>(
      uri,
      data: jsonEncode(body),
      options: Options(
        responseType: ResponseType.plain,
        headers: const <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    final statusCode = response.statusCode ?? 0;
    final text = response.data ?? '';
    Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(text);
      data = (decoded as Map).cast<String, dynamic>();
    } catch (_) {
      throw StateError(
        '远端返回非JSON: status=$statusCode, body=$text',
      );
    }

    if (statusCode < 200 || statusCode >= 300) {
      throw StateError(
        '远端接口失败: status=$statusCode, body=${jsonEncode(data)}',
      );
    }

    return data;
  }

  Uri _buildRemoteUri(String path) {
    final base = proxyBaseUrl.trim();
    if (base.isEmpty) {
      throw StateError('proxyBaseUrl 不能为空');
    }

    final baseUri = Uri.parse(base);
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return baseUri.resolve(normalizedPath);
  }

  Future<void> close() async {
    _http.close(force: true);
  }
}

class _RemoteStartResponse {
  _RemoteStartResponse({
    required this.captchaBytes,
    required this.session,
  });

  final Uint8List captchaBytes;
  final Map<String, dynamic> session;
}

class _RemoteSubmitResponse {
  _RemoteSubmitResponse({required this.html});

  final String html;
}
