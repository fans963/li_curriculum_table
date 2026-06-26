import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/rust/api/book.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:signals/signals.dart';

/// Centralised book cover loading logic with signal-based state management.
///
/// Eliminates the identical ISBN sanitization + cover fetch + signal boilerplate
/// duplicated across 4 StatefulWidget State classes.
///
/// Usage:
/// ```dart
/// final cover = BookCoverSignal(detailUrl: book.detailUrl, title: book.title);
/// // In build:
/// SignalBuilder(builder: (context) {
///   if (cover.loading.value) return LoadingWidget();
///   final url = cover.url.value;
///   ...
/// });
/// // In dispose:
/// cover.dispose();
/// ```
class BookCoverSignal {
  late final Signal<String?> _url;
  late final Signal<bool> _loading;

  /// Read-only access to the cover URL signal.
  ReadonlySignal<String?> get url => _url;

  /// Read-only access to the loading state signal.
  ReadonlySignal<bool> get loading => _loading;

  BookCoverSignal({
    required String detailUrl,
    required String title,
  })  : _url = signal<String?>(null),
        _loading = signal(true) {
    _load(detailUrl: detailUrl, title: title);
  }

  Future<void> _load({
    required String detailUrl,
    required String title,
  }) async {
    if (!isEnabled) {
      _loading.value = false;
      return;
    }
    try {
      final detail = await fetchBookLocations(detailUrl: detailUrl);
      final isbn = sanitizeIsbn(detail.isbn);
      if (isbn == null) {
        _loading.value = false;
        return;
      }
      final coverUrl = await fetchCoverUrl(isbn: isbn, title: title);
      _url.value = coverUrl;
      _loading.value = false;
    } catch (_) {
      _loading.value = false;
    }
  }

  void dispose() {
    _url.dispose();
    _loading.dispose();
  }

  // ── Static helpers ──

  static bool get isEnabled {
    return sl<SettingsController>().state.value.enableBookCover;
  }

  /// Strips non-numeric chars and returns a valid ISBN-10 or ISBN-13,
  /// or `null` if the raw string doesn't contain one.
  static String? sanitizeIsbn(String raw) {
    final clean = raw.replaceAll(RegExp(r'[^0-9Xx]'), '');
    if (clean.length >= 13) return clean.substring(0, 13);
    if (clean.length >= 10) return clean.substring(0, 10);
    if (clean.isNotEmpty) return clean;
    return null;
  }
}
