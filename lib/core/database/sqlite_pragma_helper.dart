import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

/// Applique les PRAGMA SQLite de façon compatible Android / desktop.
class SqlitePragmaHelper {
  SqlitePragmaHelper._();

  static Future<void> enableForeignKeys(Database db) async {
    await _run(db, 'PRAGMA foreign_keys = ON', required: true);
  }

  static Future<void> applyRuntimeSettings(Database db) async {
    const pragmas = [
      'PRAGMA busy_timeout = 20000',
      'PRAGMA journal_mode = WAL',
      'PRAGMA synchronous = NORMAL',
    ];
    for (final sql in pragmas) {
      await _run(db, sql);
    }
  }

  static Future<void> _run(
    Database db,
    String sql, {
    bool required = false,
  }) async {
    Object? lastError;
    try {
      await db.execute(sql);
      return;
    } catch (e) {
      lastError = e;
    }
    try {
      await db.rawQuery(sql);
      return;
    } catch (e) {
      lastError = e;
    }
    final message = '[SQLite] $sql — $lastError';
    if (required) {
      debugPrint(message);
      throw Exception(message);
    }
    debugPrint('$message (ignoré)');
  }
}
