import 'package:flutter/services.dart';
import 'package:li_curriculum_table/core/rust/api/crawler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ocrInitializedProvider = NotifierProvider<OcrInitializedNotifier, bool>(OcrInitializedNotifier.new);

class OcrInitializedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setInitialized(bool value) => state = value;
}

final ocrInitializerProvider = Provider((ref) => OcrInitializer(ref));

class OcrInitializer {
  final Ref _ref;
  OcrInitializer(this._ref);

  Future<void> ensureInitialized() async {
    if (_ref.read(ocrInitializedProvider)) return;

    final ByteData modelData = await rootBundle.load('assets/models/common_pruned.onnx');
    await initOcrEngine(modelBytes: modelData.buffer.asUint8List());

    _ref.read(ocrInitializedProvider.notifier).setInitialized(true);
  }
}
