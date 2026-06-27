import 'platform_exit_stub.dart' if (dart.library.io) 'platform_exit_io.dart';

/// Exit the application. No-op on web.
void exitApp() => doExit(0);
