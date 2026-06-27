import 'dart:async';

import 'package:li_curriculum_table/core/rust/api/crawler.dart';
import 'package:signals/signals.dart';

final ocrInitialized = signal(false);

class OcrInitializer {
  Completer<void>? _initCompleter;

  Future<void> ensureInitialized() async {
    if (ocrInitialized.value) return;

    // If already initializing, wait for the existing Completer instead of polling
    if (_initCompleter != null && !_initCompleter!.isCompleted) {
      return _initCompleter!.future;
    }

    _initCompleter = Completer<void>();
    try {
      await initOcrEngine();
      ocrInitialized.value = true;
      _initCompleter!.complete();
    } catch (e) {
      _initCompleter!.completeError(e);
      rethrow;
    }
  }
}
