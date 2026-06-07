import '../logging/app_logger.dart';

/// Logs sync operations for debugging and audit.
class SyncLogger {
  SyncLogger._();

  static void info(String message) {
    AppLogger.sync(message);
  }

  static void error(String message, [Object? e]) {
    AppLogger.error('Sync', message, e);
  }
}
