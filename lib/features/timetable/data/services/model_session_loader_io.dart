import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

Future<OrtSession> createSessionFromMergedModelBytes(
  OnnxRuntime runtime,
  Uint8List modelBytes, {
  required String modelFileName,
}) async {
  final suffix = DateTime.now().millisecondsSinceEpoch;
  final path = '${Directory.systemTemp.path}${Platform.pathSeparator}${suffix}_$modelFileName';
  final file = File(path);
  await file.writeAsBytes(modelBytes, flush: true);
  return runtime.createSession(file.path);
}
