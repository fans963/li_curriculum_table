import 'dart:async';
import 'dart:io';

/// Progress event emitted during a download.
class DownloadProgress {
  final int received;
  final int total;
  final bool done;
  final String savedPath;
  final String error;

  const DownloadProgress({
    required this.received,
    required this.total,
    required this.done,
    this.savedPath = '',
    this.error = '',
  });
}

/// GitHub mirror prefixes for users in mainland China.
/// The raw GitHub URL is always tried first.
const _mirrorPrefixes = [
  'https://ghfast.top/',
  'https://gh-proxy.com/',
  'https://gh.ddlc.top/',
];

/// Download a file with automatic mirror fallback and progress streaming.
///
/// Tries the original [url] first, then each mirror. If a stream error occurs
/// mid-download, retries with the next mirror from scratch.
Stream<DownloadProgress> downloadWithProgress({
  required String url,
  required String savePath,
}) async* {
  final candidates = <String>[
    url,
    ..._mirrorPrefixes.map((p) => '$p$url'),
  ];

  String lastError = '';

  for (var idx = 0; idx < candidates.length; idx++) {
    final candidate = candidates[idx];

    // Notify which source we're trying
    yield DownloadProgress(
      received: 0,
      total: 0,
      done: false,
      error: idx == 0 ? '正在连接 GitHub...' : '正在尝试镜像 $idx...',
    );

    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10)
        ..autoUncompress = false; // critical: do not decompress binary files

      final request = await client.getUrl(Uri.parse(candidate));
      request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');

      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode != HttpStatus.ok) {
        lastError = '$candidate: HTTP ${response.statusCode}';
        client.close(force: true);
        continue;
      }

      final total = response.contentLength;
      var received = 0;
      final file = File(savePath);
      final sink = file.openSync(mode: FileMode.write);
      var streamErr = false;

      await for (final chunk in response) {
        try {
          sink.writeFromSync(chunk);
          received += chunk.length;
          yield DownloadProgress(
            received: received,
            total: total > 0 ? total : 0,
            done: false,
          );
        } catch (e) {
          lastError = '写入失败: $e';
          streamErr = true;
          break;
        }
      }

      await sink.close();
      client.close(force: true);

      if (streamErr) {
        yield DownloadProgress(
          received: received,
          total: total > 0 ? total : 0,
          done: false,
          error: '$lastError，尝试下一个源...',
        );
        continue;
      }

      // Success
      yield DownloadProgress(
        received: received,
        total: total > 0 ? total : 0,
        done: true,
        savedPath: savePath,
      );
      return;
    } catch (e) {
      lastError = '$candidate: $e';
      yield DownloadProgress(
        received: 0,
        total: 0,
        done: false,
        error: '$lastError，尝试下一个源...',
      );
      continue;
    }
  }

  // All candidates failed
  yield DownloadProgress(
    received: 0,
    total: 0,
    done: true,
    error: '所有下载源均失败: $lastError',
  );
}
