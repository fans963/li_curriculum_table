import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:web/web.dart' as web;

Future<OrtSession> createSessionFromMergedModelBytes(
  OnnxRuntime runtime,
  Uint8List modelBytes, {
  required String modelFileName,
}) async {
  final blob = web.Blob(
    <JSAny>[modelBytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/octet-stream'),
  );
  final url = web.URL.createObjectURL(blob);
  try {
    return await runtime.createSession(url);
  } finally {
    web.URL.revokeObjectURL(url);
  }
}
