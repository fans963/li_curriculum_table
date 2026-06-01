import 'package:li_curriculum_table/core/rust/api/crawler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ocrInitializedProvider =
    NotifierProvider<OcrInitializedNotifier, bool>(OcrInitializedNotifier.new);

class OcrInitializedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setInitialized(bool value) => state = value;
}

final ocrInitializerProvider = Provider((ref) => OcrInitializer(ref));

class OcrInitializer {
  final Ref _ref;
  bool _isInitializing = false;

  OcrInitializer(this._ref);

  Future<void> ensureInitialized() async {
    if (_ref.read(ocrInitializedProvider)) return;
    if (_isInitializing) {
      while (_isInitializing && !_ref.read(ocrInitializedProvider)) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }

    _isInitializing = true;
    try {
      // Model is compiled into the Rust .so at build time via include_bytes!,
      // so we no longer need to load the ONNX asset at runtime.
      await initOcrEngine();
      _ref.read(ocrInitializedProvider.notifier).setInitialized(true);
    } finally {
      _isInitializing = false;
    }
  }
}
