import 'package:li_curriculum_table/core/rust/api/crawler.dart';
import 'package:signals/signals.dart';

final ocrInitialized = signal(false);

class OcrInitializer {
  bool _isInitializing = false;

  Future<void> ensureInitialized() async {
    if (ocrInitialized.value) return;
    if (_isInitializing) {
      while (_isInitializing && !ocrInitialized.value) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }

    _isInitializing = true;
    try {
      await initOcrEngine();
      ocrInitialized.value = true;
    } finally {
      _isInitializing = false;
    }
  }
}
