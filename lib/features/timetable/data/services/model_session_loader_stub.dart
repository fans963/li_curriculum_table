import 'dart:typed_data';

import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

Future<OrtSession> createSessionFromMergedModelBytes(
  OnnxRuntime runtime,
  Uint8List modelBytes, {
  required String modelFileName,
}) {
  throw UnsupportedError('Model byte session loading is not supported on this platform.');
}
