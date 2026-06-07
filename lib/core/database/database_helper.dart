import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../../app/constants.dart';
import 'database_init.dart';
import 'database_manager.dart';
import 'migration_history_repository.dart';
import 'sqlite_pragma_helper.dart';

/// Singleton SQLite — ouverture unique via [DatabaseManager].
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database => DatabaseManager.instance.open();

  /// Ouverture brute (appelée une seule fois par le manager).
  Future<Database> openRaw() async {
    if (_database != null && _database!.isOpen) return _database!;

    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    } else if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.databaseName);

    // Pas de onConfigure : les PRAGMA dans ce callback plantent sur Android.
    _database = await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: DatabaseInit.onCreate,
      onUpgrade: DatabaseInit.onUpgrade,
    );

    await SqlitePragmaHelper.enableForeignKeys(_database!);
    await SqlitePragmaHelper.applyRuntimeSettings(_database!);
    await MigrationHistoryRepository.ensureTable(_database!);
    await DatabaseInit.runPostOpenMigrations(_database!);
    return _database!;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
    DatabaseManager.instance.invalidateCache();
  }
}
