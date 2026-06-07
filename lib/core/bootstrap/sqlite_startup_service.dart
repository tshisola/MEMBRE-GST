import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_manager.dart';
import '../database/safe_database_initializer.dart';
import '../logging/app_logger.dart';
import '../logging/technical_error_repository.dart';
import 'startup_timeout_handler.dart';

class SQLiteStartupResult {
  const SQLiteStartupResult({
    required this.ready,
    this.path,
    this.error,
    this.pendingBackground = false,
  });

  final bool ready;
  final String? path;
  final Object? error;
  final bool pendingBackground;
}

/// Initialise SQLite sans migration lourde au démarrage critique.
class SQLiteStartupService {
  SQLiteStartupService._();

  static const Duration _quickTimeout = Duration(seconds: 8);
  static const Duration _fullTimeout = Duration(seconds: 45);

  /// Chemin rapide : ouverture seule, migrations ville en différé.
  static Future<SQLiteStartupResult> initialize() async {
    try {
      await SharedPreferences.getInstance();
    } catch (e) {
      AppLogger.sqlite('SharedPreferences: $e');
    }

    final db = await SafeDatabaseInitializer.initializeForStartup(
      timeout: _quickTimeout,
    );

    if (db != null) {
      SQLiteLogger.info('Prêt (${db.path})');
      return SQLiteStartupResult(ready: true, path: db.path);
    }

    if (DatabaseManager.instance.status ==
        DatabaseOpenStatus.pendingBackground) {
      SQLiteLogger.info('Ouverture SQLite en arrière-plan');
      return const SQLiteStartupResult(
        ready: false,
        pendingBackground: true,
      );
    }

    return StartupTimeoutHandler.run(
      label: 'SQLite',
      timeout: _fullTimeout,
      action: () async {
        final opened = await DatabaseManager.instance.open(
          timeout: _fullTimeout,
        );
        SQLiteLogger.info('Prêt (${opened.path})');
        return SQLiteStartupResult(ready: true, path: opened.path);
      },
      onTimeout: () {
        TechnicalErrorRepository.record(
          source: 'sqlite_open',
          error: TimeoutException('sqlite_open_timeout'),
        );
        return const SQLiteStartupResult(
          ready: false,
          pendingBackground: true,
        );
      },
    );
  }

  /// Poursuit l'ouverture après affichage de l'UI.
  static void ensureOpenInBackground({void Function(bool ok)? onComplete}) {
    DatabaseManager.instance.continueOpenInBackground(onComplete: onComplete);
  }
}
