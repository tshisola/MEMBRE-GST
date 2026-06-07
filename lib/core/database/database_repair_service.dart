import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../app/constants.dart';
import '../logging/app_logger.dart';
import '../services/city_name_migration_service.dart';
import 'database_helper.dart';
import 'database_init.dart';
import 'database_manager.dart' show DatabaseManager, DatabaseOpenStatus;
import 'migration_history_repository.dart';

class DatabaseRepairResult {
  const DatabaseRepairResult({
    required this.success,
    required this.message,
    this.backupPath,
    this.tablesChecked = 0,
  });

  final bool success;
  final String message;
  final String? backupPath;
  final int tablesChecked;
}

/// Réparation locale — ne supprime pas les données sans action explicite Admin.
class DatabaseRepairService {
  DatabaseRepairService._();

  static Future<DatabaseRepairResult> repair() async {
    DatabaseManager.instance.status = DatabaseOpenStatus.repairing;
    try {
      await DatabaseHelper.instance.close();
      DatabaseManager.instance.invalidateCache();

      final dbPath = await _resolveDbPath();
      String? backupPath;
      if (await File(dbPath).exists()) {
        backupPath = '$dbPath.bak-${DateTime.now().millisecondsSinceEpoch}';
        await File(dbPath).copy(backupPath);
        SQLiteLogger.info('Sauvegarde: $backupPath');
      }

      final db = await DatabaseManager.instance.open(
        timeout: const Duration(seconds: 60),
      );

      final integrity = await db.rawQuery('PRAGMA integrity_check');
      final ok = integrity.isNotEmpty &&
          (integrity.first.values.first == 'ok' ||
              integrity.first.values.first.toString().toLowerCase() == 'ok');

      await MigrationHistoryRepository.ensureTable(db);
      await DatabaseInit.runPostOpenMigrations(db);

      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
      );

      await MigrationHistoryRepository.record(
        db,
        name: 'repair_pass',
        version: AppConstants.databaseVersion,
        status: ok ? 'success' : 'warning',
        error: ok ? null : integrity.toString(),
      );

      DatabaseManager.instance.status = DatabaseOpenStatus.ready;
      return DatabaseRepairResult(
        success: ok,
        message: ok
            ? 'Base réparée (${tables.length} tables).'
            : 'Réparation partielle — vérifiez le diagnostic.',
        backupPath: backupPath,
        tablesChecked: tables.length,
      );
    } catch (e, st) {
      DatabaseManager.instance.status = DatabaseOpenStatus.failed;
      DatabaseManager.instance.lastError = e.toString();
      SQLiteLogger.error('Réparation échouée', e, st);
      return DatabaseRepairResult(
        success: false,
        message: 'Réparation impossible: $e',
      );
    }
  }

  static Future<void> runDeferredCityMigration() async {
    try {
      final db = await DatabaseManager.instance.open();
      final migration = CityNameMigrationService(
        databaseProvider: () => DatabaseManager.instance.open(),
      );
      final count = await migration.migrateLocalDatabase(db);
      if (count > 0) {
        SQLiteLogger.info('Migration ville: $count lignes');
      }
      await MigrationHistoryRepository.record(
        db,
        name: 'city_kinshasa_to_lubumbashi',
        version: AppConstants.databaseVersion,
        status: 'success',
      );
    } catch (e) {
      SQLiteLogger.error('Migration ville différée', e);
    }
  }

  static Future<String> _resolveDbPath() async {
    final base = await getDatabasesPath();
    return join(base, AppConstants.databaseName);
  }
}
