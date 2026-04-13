import 'dart:io';
import 'dart:typed_data';

import 'package:feedback/feedback.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class FeedbackHandler {
  static Future<void> shareFeedback(UserFeedback feedback) async {
    final screenshotFile = await _writeImageToStorage(feedback.screenshot);

    // Create an XFile from the temporary file
    final XFile xFile = XFile(screenshotFile.path);

    final String shareText = feedback.text.isEmpty ? '来自用户的应用反馈' : feedback.text;

    try {
      // Use the ShareParams API as required by share_plus 12.0.2
      await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: '🍐课表 - 应用反馈',
          files: [xFile],
        ),
      );
    } catch (e) {
      // Fallback if file sharing fails
      await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: '🍐课表 - 应用反馈',
        ),
      );
    }
  }

  static Future<File> _writeImageToStorage(Uint8List screenshot) async {
    final Directory output = await getTemporaryDirectory();
    final String screenshotFilePath = '${output.path}/feedback_screenshot.png';
    final File screenshotFile = File(screenshotFilePath);
    await screenshotFile.writeAsBytes(screenshot);
    return screenshotFile;
  }
}
