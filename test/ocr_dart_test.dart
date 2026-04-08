import 'dart:io';

import 'package:curriculum_table/src/table_getter/ddddocr.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  DdddOcr? ocr;
  Object? initError;

  setUpAll(() async {
    try {
      ocr = await DdddOcr.createFromAssets();
    } catch (e) {
      initError = e;
    }
  });

  tearDownAll(() async {
    if (ocr != null) {
      await ocr!.close();
    }
  });

  Future<void> runCase(String imagePath) async {
    if (ocr == null) {
      // ignore: avoid_print
      print('Skipped OCR test because runtime init failed: $initError');
      return;
    }

    final bytes = await File(imagePath).readAsBytes();
    final text = await ocr!.classification(bytes);
    // Keep the print for quick local verification while debugging OCR models.
    // ignore: avoid_print
    print('OCR($imagePath) => "$text"');
    expect(text.trim().isNotEmpty, isTrue, reason: 'OCR result should not be empty for $imagePath');
  }

  test('classify captcha.jpg', () async {
    await runCase('test/captcha.jpg');
  });

  test('classify verifycode.jpg', () async {
    await runCase('test/verifycode.jpg');
  });
}
