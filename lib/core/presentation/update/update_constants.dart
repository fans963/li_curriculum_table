import 'package:flutter/foundation.dart';

const ghOwner = 'fans963';
const ghRepo = 'li_curriculum_table';
const giteeOwner = 'fans963';
const giteeRepo = 'li_curriculum_table';

/// GitHub mirror prefixes for in-app download (native platforms).
const ghMirrorPrefixes = [
  'https://ghfast.top/',
  'https://gh-proxy.com/',
  'https://gh.ddlc.top/',
];

/// All downloadable assets with human-readable labels.
const assets = [
  Asset('app-arm64-v8a-release.apk', 'Android ARM64'),
  Asset('app-armeabi-v7a-release.apk', 'Android ARM32'),
  Asset('app-x86_64-release.apk', 'Android x86_64'),
  Asset('li-curriculum-table-unsigned.ipa', 'iOS (IPA)'),
];

class Asset {
  final String filename;
  final String label;
  const Asset(this.filename, this.label);
}

/// Vercel CDN URL (fastest globally, no proxy needed).
String vercelUrl(String version, String filename) =>
    'https://li-table.vercel.app/releases/v$version/$filename';

/// Gitee download URL (fastest in mainland China).
String giteeUrl(String version, String filename) =>
    'https://gitee.com/$giteeOwner/$giteeRepo/releases/download/v$version/$filename';

/// GitHub download URL (fallback).
String ghUrl(String version, String filename) =>
    'https://github.com/$ghOwner/$ghRepo/releases/download/v$version/$filename';

/// Mirror-prefixed GitHub URL for in-app download.
String ghMirrorUrl(String version, String filename) =>
    '${ghMirrorPrefixes.first}${ghUrl(version, filename)}';

/// Build the download URL for the current device (native in-app download).
/// Priority: Vercel CDN > Gitee > GitHub mirror > GitHub raw
String buildDownloadUrl(String version) {
  String filename;
  if (defaultTargetPlatform == TargetPlatform.android) {
    filename = 'app-arm64-v8a-release.apk';
  } else if (defaultTargetPlatform == TargetPlatform.iOS) {
    filename = 'li-curriculum-table-unsigned.ipa';
  } else {
    return 'https://github.com/$ghOwner/$ghRepo/releases/tag/v$version';
  }
  return vercelUrl(version, filename);
}

class DownloadState {
  bool downloading = false;
  double progress = 0; // 0.0 ~ 1.0
  String? error;
  String? savedPath;
  int received = 0;
  int total = 0;
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
