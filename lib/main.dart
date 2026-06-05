import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:li_curriculum_table/app/app.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/rust/frb_generated.dart';
import 'package:li_curriculum_table/core/services/notification_service.dart';
import 'package:li_curriculum_table/core/services/ocr_initializer.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/grades/presentation/state/grade_controller.dart';
import 'package:li_curriculum_table/features/exam_schedule/presentation/state/exam_controller.dart';
import 'package:li_curriculum_table/util/util.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handler for uncaught exceptions
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint('Flutter error: ${details.exceptionAsString()}');
    }
  };

  // Initialize Rust FFI bridge with error handling
  try {
    await RustLib.init();
  } catch (e) {
    debugPrint('Rust bridge initialization failed: $e');
    // Continue without Rust — features depending on it will degrade gracefully
  }

  // Hide system status bar for a more unified look on mobile
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  if (isDesktop) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(1500, 1000),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Setup dependency injection
  setupServiceLocator();

  // Start loading OCR engine in background to avoid blocking startup
  sl<OcrInitializer>().ensureInitialized();

  // Await settings so the first frame renders with persisted theme, not defaults
  await sl<SettingsController>().init();

  // Initialize notifications and request permission
  final notifications = sl<NotificationService>();
  await notifications.init();
  await notifications.requestPermission();

  // Fire-and-forget: these load data into signals asynchronously
  sl<GradeController>().init().catchError((e) {
    if (kDebugMode) debugPrint('GradeController init error: $e');
  });
  sl<ExamController>().init().catchError((e) {
    if (kDebugMode) debugPrint('ExamController init error: $e');
  });

  runApp(const CurriculumTableApp());
}
