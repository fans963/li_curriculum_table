/// Cross-platform cookie persistence backed by `flutter_secure_storage`
/// (Android KeyStore / iOS Keychain / macOS Keychain / Linux libsecret /
/// Windows DPAPI / Web localStorage).
///
/// `CookieStorage` is the single source of truth for the on-disk copy
/// of the cookie jar. Rust holds the jar in memory at runtime — we
/// only ever touch storage at startup (read) and on save/clear events
/// (write), so the extra latency of a secure KV is a non-issue.
///
/// API:
///   * [CookieStorage.bootstrap] — call once at app startup. Returns a
///     storage helper with any previously persisted cookies already
///     loaded into the Rust jar.
///   * [CookieStorage.saveFromRust] — called after QR / password /
///     cookie-injection login. Snapshots the Rust jar and writes the
///     JSON to secure storage.
///   * [CookieStorage.clear] — wipes both the persisted blob and the
///     Rust in-memory jar.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:li_curriculum_table/core/rust/api/crawler.dart' as rust_api;

const _secureKey = 'app.session_cookies_json';
const _secureOptions = AndroidOptions.defaultOptions;

class CookieStorage {
  CookieStorage._();

  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  /// Read previously-persisted cookies (JSON string). Returns `null`
  /// if the user has never logged in on this device.
  Future<String?> _read() async {
    try {
      return await _secure.read(key: _secureKey, aOptions: _secureOptions);
    } catch (e) {
      if (kDebugMode) debugPrint('CookieStorage: read failed: $e');
      return null;
    }
  }

  /// Snapshot the Rust jar and persist its JSON representation.
  Future<void> _write(String json) async {
    try {
      await _secure.write(
        key: _secureKey,
        value: json,
        aOptions: _secureOptions,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('CookieStorage: write failed: $e');
    }
  }

  /// Wipe the persisted cookie blob.
  Future<void> _delete() async {
    try {
      await _secure.delete(key: _secureKey, aOptions: _secureOptions);
    } catch (_) {/* ignore */}
  }

  /// Read the previously-persisted cookies from secure storage and
  /// hand them to the Rust jar so it starts populated. No-op on first
  /// run.
  static Future<void> bootstrap() async {
    final storage = CookieStorage._();
    final existing = await storage._read();
    if (existing == null || existing.isEmpty) {
      if (kDebugMode) debugPrint('CookieStorage: no previous session');
      return;
    }
    try {
      final count = await rust_api.setInitialCookiesJson(json: existing);
      if (kDebugMode) {
        debugPrint('CookieStorage: restored $count cookies from secure storage');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('CookieStorage: bootstrap parse failed: $e');
    }
  }

  /// Snapshot the Rust jar to JSON and persist it. Safe to call at
  /// any time; a no-op if the jar is empty.
  static Future<void> saveFromRust() async {
    final storage = CookieStorage._();
    try {
      final raw = await rust_api.persistCookiesBytes();
      if (raw.isEmpty) {
        await storage._delete();
      } else {
        await storage._write(utf8.decode(raw));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('CookieStorage: save failed: $e');
    }
  }

  /// Clear both the persisted blob and the in-memory Rust jar.
  static Future<void> clear() async {
    final storage = CookieStorage._();
    await storage._delete();
    try {
      await rust_api.clearPersistedCookies();
    } catch (_) {/* ignore */}
  }
}
