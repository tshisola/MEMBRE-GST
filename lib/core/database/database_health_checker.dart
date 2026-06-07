import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../app/constants.dart';
import 'database_manager.dart';
import 'migration_history_repository.dart';

class DatabaseHealthReport {
  const DatabaseHealthReport({
    required this.fileExists,
    required this.isOpen,
    required this.path,
    this.fileSizeBytes,
    this.tableCount = 0,
    this.openDurationMs,
    this.lastError,
    this.recentMigrations = const [],
  });

  final bool fileExists;
  final bool isOpen;
  final String? path;
  final int? fileSizeBytes;
  final int tableCount;
  final int? openDurationMs;
  final String? lastError;
  final List<Map<String, dynamic>> recentMigrations;
}

class DatabaseHealthChecker {
  DatabaseHealthChecker._();

  static Future<DatabaseHealthReport> check() async {
    final manager = DatabaseManager.instance;
    final base = await getDatabasesPath();
    final path = join(base, AppConstants.databaseName);
    final file = File(path);
    final exists = await file.exists();
    final size = exists ? await file.length() : null;

    var isOpen = false;
    var tableCount = 0;
    var migrations = <Map<String, dynamic>>[];

    if (manager.isReady) {
      isOpen = true;
      try {
        final db = await manager.open();
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table'",
        );
        tableCount = tables.length;
        migrations = await MigrationHistoryRepository.listRecent(db);
      } catch (e) {
        return DatabaseHealthReport(
          fileExists: exists,
          isOpen: false,
          path: path,
          fileSizeBytes: size,
          lastError: e.toString(),
        );
      }
    }

    return DatabaseHealthReport(
      fileExists: exists,
      isOpen: isOpen,
      path: path,
      fileSizeBytes: size,
      tableCount: tableCount,
      openDurationMs: manager.openDurationMs,
      lastError: manager.lastError,
      recentMigrations: migrations,
    );
  }
}
