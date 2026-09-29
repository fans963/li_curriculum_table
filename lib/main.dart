import 'package:flutter/foundation.dart';
import 'package:li_curriculum_table/core/presentation/styles/styles.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:li_curriculum_table/app/app.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/rust/api/rust_logger.dart';
import 'package:li_curriculum_table/core/rust/frb_generated.dart';
import 'package:li_curriculum_table/core/services/app_logger.dart';
import 'package:li_curriculum_table/core/services/cookie_storage/cookie_storage.dart';
import 'package:li_curriculum_table/core/services/notification_service.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/grades/presentation/state/grade_controller.dart';
import 'package:li_curriculum_table/features/todo/presentation/state/todo_controller.dart';
import 'package:li_curriculum_table/features/exam_schedule/presentation/state/exam_controller.dart';
import 'package:li_curriculum_table/util/util.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await UiStyleRegistry.initializeAll();
  } catch (e) {
    if (kDebugMode) debugPrint('UiStyleRegistry init failed: $e');
  }

  await AppLogger.instance.init();

  // Global error handler for uncaught exceptions
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogger.instance.error(
      'FlutterError: ${details.exceptionAsString()}',
      error: details.exception,
      stack: details.stack,
    );
    if (kDebugMode) {
      debugPrint('Flutter error: ${details.exceptionAsString()}');
    }
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.instance.error(
      'Uncaught error: $error',
      error: error,
      stack: stack,
    );
    return true;
  };

  // Initialize Rust FFI bridge with error handling
  try {
    await RustLib.init();
    initRustLogStream().listen((entry) {
      AppLogger.instance.logRust(entry.level, entry.module, entry.message);
    });
  } catch (e) {
    AppLogger.instance.error('Rust bridge initialization failed', error: e);
    debugPrint('Rust bridge initialization failed: $e');
    // Continue without Rust — features depending on it will degrade gracefully
  }

  // Hide system status bar for a more unified look on mobile
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  if (isDesktop) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(1500, 1000),
      minimumSize: Size(960, 680),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      title: '🍐课表',
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Setup dependency injection
  setupServiceLocator();

  // Await settings so the first frame renders with persisted theme, not defaults
  await sl<SettingsController>().init();

  // Rehydrate the Rust cookie jar from `flutter_secure_storage`. This is
  // the single persistence backend for every platform (Android KeyStore,
  // iOS Keychain, macOS Keychain, Linux libsecret, Windows DPAPI, Web
  // localStorage). Must run *before* any controller fires a request so
  // we don't trip an unauthenticated round-trip on cold start.
  try {
    await CookieStorage.bootstrap();
  } catch (e, st) {
    AppLogger.instance.warning(
      'Cookie bootstrap failed; session will not persist',
      error: e,
      stack: st,
    );
  }

  // Initialize notifications (Windows unsupported by flutter_local_notifications)
  final notifications = sl<NotificationService>();
  try {
    await notifications.init();
    await notifications.requestPermission();
  } catch (e) {
    AppLogger.instance.warning('Notification init skipped', error: e);
    if (kDebugMode) {
      debugPrint('Notification init skipped (unsupported platform): $e');
    }
  }

  // Fire-and-forget: these load data into signals asynchronously
  sl<GradeController>().init().catchError((e) {
    if (kDebugMode) debugPrint('GradeController init error: $e');
  });
  sl<ExamController>().init().catchError((e) {
    if (kDebugMode) debugPrint('ExamController init error: $e');
  });

  // Course todo / DDL controller — fire-and-forget load.
  sl<TodoController>().init().catchError((e) {
    if (kDebugMode) debugPrint('TodoController init error: $e');
  });

  runApp(const CurriculumTableApp());
}
