import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

/// Central application logger with rotating file output.
///
/// Keeps a bounded in-memory buffer for feedback export, and writes
/// timestamped records into `getApplicationSupportDirectory()/logs`.
class AppLogger {
  AppLogger._();

  static final AppLogger instance = AppLogger._();

  final List<String> _recent = <String>[];
  IOSink? _sink;
  File? _currentFile;
  Directory? _logDirectory;
  Future<void>? _initFuture;
  bool _initialized = false;

  static const int maxRecentLines = 500;
  static const int maxFileBytes = 512 * 1024;
  static const int maxLogFiles = 6;

  /// Initializes the logger and installs the root file handler.
  Future<void> init() {
    _initFuture ??= _initialize();
    return _initFuture!;
  }

  Future<void> _initialize() async {
    hierarchicalLoggingEnabled = true;
    Logger.root.level = Level.ALL;

    try {
      final supportDir = await getApplicationSupportDirectory();
      final logDir = Directory('${supportDir.path}/logs');
      await logDir.create(recursive: true);
      _logDirectory = logDir;
      _openNextFile();
    } catch (e) {
      debugPrint('AppLogger init failed: $e');
    }

    Logger.root.onRecord.listen(_handleRecord);
    _initialized = true;
  }

  Logger logger(String name) => Logger(name);

  void debug(String message, {String? tag}) =>
      _log(Level.FINE, message, tag: tag);

  void info(String message, {String? tag}) =>
      _log(Level.INFO, message, tag: tag);

  void warning(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stack,
  }) => _log(Level.WARNING, message, tag: tag, error: error, stack: stack);

  void error(String message, {String? tag, Object? error, StackTrace? stack}) {
    _log(Level.SEVERE, message, tag: tag, error: error, stack: stack);
  }

  /// Routes a log record emitted by the Rust side into the same AppLogger.
  ///
  /// Rust sends its module name separately so the file format can stay
  /// normalized while still making the source of each line obvious.
  void logRust(String level, String module, String message) {
    final tag = module.isEmpty ? 'Rust' : 'Rust/$module';
    switch (level.toUpperCase()) {
      case 'ERROR':
        error(message, tag: tag);
        break;
      case 'WARN':
        warning(message, tag: tag);
        break;
      case 'INFO':
        info(message, tag: tag);
        break;
      case 'DEBUG':
      case 'TRACE':
        debug(message, tag: tag);
        break;
      default:
        info(message, tag: tag);
        break;
    }
  }

  void _log(
    Level level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stack,
  }) {
    final logger = tag == null ? Logger.root : Logger(tag);
    logger.log(level, message, error, stack);
  }

  void _handleRecord(LogRecord record) {
    final line = _format(record);
    _appendRecent(line);

    // Mirror every normalized record to the console as well. Rust records
    // arrive through the same AppLogger, so all lines share one format.
    debugPrint(_format(record, colorize: true));

    final sink = _sink;
    if (sink == null) return;

    try {
      sink.writeln(line);
      _rotateIfNeeded();
    } catch (_) {
      // Never let logging crash the app.
    }
  }

  String _format(LogRecord record, {bool colorize = false}) {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}';
    final levelLabel = _levelLabel(record.level).padRight(5);
    final levelColor = colorize ? _levelColor(record.level) : '';
    final level = levelColor.isNotEmpty
        ? '$levelColor$levelLabel\x1B[0m'
        : levelLabel;
    final name = record.loggerName == 'root' ? 'App' : record.loggerName;
    final buffer = StringBuffer(
      '[$time] [$level] [$name] ${_redact(record.message)}',
    );

    if (record.error != null) {
      buffer.writeln();
      buffer.write('  error: ${_redact(record.error.toString())}');
    }
    if (record.stackTrace != null) {
      buffer.writeln();
      buffer.write('  stack: ${record.stackTrace}');
    }
    return buffer.toString();
  }

  String _levelLabel(Level level) {
    if (level >= Level.SHOUT) return 'FATAL';
    if (level >= Level.SEVERE) return 'ERROR';
    if (level >= Level.WARNING) return 'WARN';
    if (level >= Level.INFO) return 'INFO';
    if (level >= Level.FINE) return 'DEBUG';
    return 'TRACE';
  }

  String _levelColor(Level level) {
    if (level >= Level.SHOUT) return '\x1B[91m';
    if (level >= Level.SEVERE) return '\x1B[31m';
    if (level >= Level.WARNING) return '\x1B[33m';
    if (level >= Level.INFO) return '\x1B[32m';
    if (level >= Level.FINE) return '\x1B[36m';
    return '\x1B[90m';
  }

  String _redact(String input) {
    return input
        .replaceAll(
          RegExp(
            r'(password|passwd|pwd|token|cookie|jsessionid|verifycode|captcha)\s*[=:]\s*\S+',
            caseSensitive: false,
          ),
          r'$1=***',
        )
        .replaceAll(
          RegExp(r'(学号|账号|密码|验证码|口令|token|cookie|jsessionid)\s*[=:：]\s*\S+'),
          r'$1=***',
        );
  }

  void _appendRecent(String line) {
    _recent.add(line);
    if (_recent.length > maxRecentLines) {
      _recent.removeRange(0, _recent.length - maxRecentLines);
    }
  }

  void _openNextFile() {
    final dir = _logDirectory;
    if (dir == null) return;

    final now = DateTime.now();
    final stamp =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _currentFile = File('${dir.path}/app-$stamp-1.log');
    _sink?.close();
    _sink = _currentFile!.openWrite(mode: FileMode.append);
    _pruneOldFiles(stamp);
  }

  void _rotateIfNeeded() {
    final file = _currentFile;
    if (file == null) return;
    if (file.lengthSync() < maxFileBytes) return;

    final dir = _logDirectory;
    if (dir == null) return;
    final stamp = file.uri.pathSegments.last
        .replaceFirst('app-', '')
        .replaceFirst('.log', '');
    _sink?.close();
    _sink = null;

    final baseStamp = stamp.endsWith('-1')
        ? stamp.substring(0, stamp.length - 2)
        : stamp.split('-').take(3).join('-');
    var index = 2;
    File next = File('${dir.path}/app-$baseStamp-$index.log');
    while (next.existsSync()) {
      index++;
      next = File('${dir.path}/app-$baseStamp-$index.log');
    }
    _currentFile = next;
    _sink = next.openWrite(mode: FileMode.append);
    _pruneOldFiles(baseStamp);
  }

  void _pruneOldFiles(String currentStamp) {
    final dir = _logDirectory;
    if (dir == null) return;
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((f) => f.uri.pathSegments.last.startsWith('app-'))
            .toList()
          ..sort(
            (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
          );

    final currentPrefix = 'app-$currentStamp';
    final others = files.where((f) {
      final name = f.uri.pathSegments.last;
      return !name.startsWith(currentPrefix);
    }).toList();
    final keepOthers = others.take(maxLogFiles).toSet();

    for (final f in files) {
      if (f == _currentFile) continue;
      final name = f.uri.pathSegments.last;
      if (name.startsWith(currentPrefix) && f != _currentFile) {
        // Keep current-day files within maxLogFiles too.
        if (_currentDayFiles(currentPrefix).length <= maxLogFiles) continue;
      }
      if (f != _currentFile && !keepOthers.contains(f)) {
        try {
          f.deleteSync();
        } catch (_) {}
      }
    }
  }

  List<File> _currentDayFiles(String prefix) {
    final dir = _logDirectory;
    if (dir == null) return const [];
    return dir
        .listSync()
        .whereType<File>()
        .where((f) => f.uri.pathSegments.last.startsWith(prefix))
        .toList();
  }

  /// Returns the latest in-memory log lines, newest last.
  Future<String> exportRecentLogs({int maxLines = maxRecentLines}) async {
    if (!_initialized) {
      await init();
    }
    return _recent.length <= maxLines
        ? _recent.join('\n')
        : _recent.sublist(_recent.length - maxLines).join('\n');
  }

  Future<File> writeFeedbackLogFile() async {
    final logs = await exportRecentLogs();
    final info = await _deviceInfo();
    final content = [
      '🍐 课表 用户反馈日志',
      '',
      info,
      '',
      '━━━━━━━━━━━━━━━━━━━━━━━━━━',
      logs,
    ].join('\n');

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/curriculum_table_feedback_${DateTime.now().millisecondsSinceEpoch}.txt',
    );
    await file.writeAsString(content);
    return file;
  }

  Future<String> _deviceInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final lines = <String>[
        'app_version: ${info.version}',
        'build_number: ${info.buildNumber}',
        'package_name: ${info.packageName}',
        'platform: ${Platform.operatingSystem}',
        'platform_version: ${Platform.operatingSystemVersion}',
        'locale: ${Platform.localeName}',
      ];
      return lines.join('\n');
    } catch (_) {
      return 'device_info: unavailable';
    }
  }

  /// Deletes all persisted log files and clears the in-memory buffer.
  Future<void> clearLogs() async {
    _recent.clear();
    final dir = _logDirectory;
    if (dir == null) return;
    try {
      for (final entity in dir.listSync()) {
        if (entity is File && entity.uri.pathSegments.last.startsWith('app-')) {
          entity.deleteSync();
        }
      }
    } catch (_) {}
    _openNextFile();
  }
}
