import 'package:li_curriculum_table/core/rust/api/book.dart';
import 'package:pool/pool.dart';
import 'package:signals/signals.dart';

/// Centralised book cover loading logic with signal-based state management.
///
/// Uses a static [Pool] to limit concurrent detail-page fetches and avoid
/// overwhelming the slow campus OPAC server.
class BookCoverSignal {
  late final Signal<String?> _url;
  late final Signal<bool> _loading;
  bool _disposed = false;

  static final _pool = Pool(2);

  ReadonlySignal<String?> get url => _url;
  ReadonlySignal<bool> get loading => _loading;

  BookCoverSignal({required String detailUrl, required String title})
    : _url = signal<String?>(null),
      _loading = signal(true) {
    _load(detailUrl: detailUrl, title: title);
  }

  Future<void> _load({required String detailUrl, required String title}) async {
    if (!isEnabled) {
      if (!_disposed) _loading.value = false;
      return;
    }
    try {
      await _pool.withResource(() async {
        if (_disposed) return;
        final detail = await fetchBookLocations(detailUrl: detailUrl);
        final isbn = sanitizeIsbn(detail.isbn);
        if (isbn == null) {
          if (!_disposed) _loading.value = false;
          return;
        }
        final coverUrl = await fetchCoverUrl(isbn: isbn, title: title);
        if (!_disposed) {
          _url.value = coverUrl;
          _loading.value = false;
        }
      });
    } catch (_) {
      if (!_disposed) _loading.value = false;
    }
  }

  void dispose() {
    _disposed = true;
    _url.dispose();
    _loading.dispose();
  }

  // ── Static helpers ──

  // Disabled for stable release — feature is incomplete.
  static bool get isEnabled => false;

  static String? sanitizeIsbn(String raw) {
    final clean = raw.replaceAll(RegExp(r'[^0-9Xx]'), '');
    if (clean.length >= 13) return clean.substring(0, 13);
    if (clean.length >= 10) return clean.substring(0, 10);
    if (clean.isNotEmpty) return clean;
    return null;
  }
}
