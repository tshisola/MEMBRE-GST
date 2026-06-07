import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../logging/app_logger.dart';
import 'database_manager.dart';

/// Initialisation SQLite sûre — une seule ouverture concurrente.
class SafeDatabaseInitializer {
  SafeDatabaseInitializer._();

  static Future<Database?> initializeForStartup({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      return await DatabaseManager.instance.open(timeout: timeout);
    } on TimeoutException {
      DatabaseManager.instance.continueOpenInBackground();
      AppLogger.sqlite('Ouverture SQLite poursuivie en arrière-plan');
      return null;
    } catch (e) {
      AppLogger.sqlite('Ouverture SQLite: $e');
      DatabaseManager.instance.continueOpenInBackground();
      return null;
    }
  }
}
