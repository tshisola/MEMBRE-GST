import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../app/constants.dart';

class MigrationHistoryRepository {
  MigrationHistoryRepository._();

  static const _table = AppConstants.tableMigrationHistory;
  static final _uuid = Uuid();

  static Future<void> ensureTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_table (
        id TEXT PRIMARY KEY,
        migration_name TEXT NOT NULL,
        version INTEGER NOT NULL,
        status TEXT NOT NULL,
        executed_at TEXT NOT NULL,
        error_message TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_migration_history_name ON $_table(migration_name)',
    );
  }

  static Future<bool> wasExecuted(Database db, String name) async {
    await ensureTable(db);
    final rows = await db.query(
      _table,
      where: 'migration_name = ? AND status = ?',
      whereArgs: [name, 'success'],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  static Future<void> record(
    Database db, {
    required String name,
    required int version,
    required String status,
    String? error,
  }) async {
    await ensureTable(db);
    await db.insert(_table, {
      'id': _uuid.v4(),
      'migration_name': name,
      'version': version,
      'status': status,
      'executed_at': DateTime.now().toIso8601String(),
      'error_message': error,
    });
  }

  static Future<List<Map<String, dynamic>>> listRecent(Database db,
      {int limit = 20}) async {
    await ensureTable(db);
    return db.query(_table, orderBy: 'executed_at DESC', limit: limit);
  }
}
