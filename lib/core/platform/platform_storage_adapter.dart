import 'package:flutter/foundation.dart';

import 'mobile_sqlite_adapter.dart';
import 'web_indexed_db_adapter.dart';

/// Interface commune stockage — mobile SQLite, Web IndexedDB.
abstract class PlatformStorageAdapter {
  Future<void> initialize();
  Future<void> put(String box, String key, Map<String, dynamic> value);
  Future<Map<String, dynamic>?> get(String box, String key);
  Future<List<Map<String, dynamic>>> getAll(String box);
  Future<void> delete(String box, String key);
  Future<void> clearBox(String box);
  bool get isReady;

  static PlatformStorageAdapter instance = _resolve();

  static PlatformStorageAdapter _resolve() {
    if (kIsWeb) return WebIndexedDbAdapter();
    return MobileSQLiteAdapter();
  }
}
