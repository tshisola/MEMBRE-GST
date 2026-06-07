import 'package:flutter/foundation.dart';

import 'error_reporter_local.dart';

/// Central logging — startup, navigation, Firebase, SQLite, sync.
class AppLogger {
  AppLogger._();

  static void startup(String message) {
    _log('Startup', message);
  }

  static void navigation(String message) {
    _log('Navigation', message);
  }

  static void firebase(String message) {
    _log('Firebase', message);
  }

  static void sqlite(String message) {
    _log('SQLite', message);
  }

  static void sync(String message) {
    _log('Sync', message);
  }

  static void error(String category, String message, [Object? e, StackTrace? st]) {
    final full = '$message${e != null ? ' — $e' : ''}';
    debugPrint('[$category][ERROR] $full');
    if (st != null) debugPrint(st.toString());
    ErrorReporterLocal.record(
      category: category,
      message: full,
      stackTrace: st?.toString(),
    );
  }

  static void _log(String tag, String message) {
    debugPrint('[$tag] $message');
  }
}

/// Alias demandés dans la spec.
class StartupLogger {
  StartupLogger._();
  static void info(String m) => AppLogger.startup(m);
  static void error(String m, [Object? e, StackTrace? st]) =>
      AppLogger.error('Startup', m, e, st);
}

class NavigationLogger {
  NavigationLogger._();
  static void info(String m) => AppLogger.navigation(m);
}

class FirebaseLogger {
  FirebaseLogger._();
  static void info(String m) => AppLogger.firebase(m);
  static void error(String m, [Object? e, StackTrace? st]) =>
      AppLogger.error('Firebase', m, e, st);
}

class SQLiteLogger {
  SQLiteLogger._();
  static void info(String m) => AppLogger.sqlite(m);
  static void error(String m, [Object? e, StackTrace? st]) =>
      AppLogger.error('SQLite', m, e, st);
}
