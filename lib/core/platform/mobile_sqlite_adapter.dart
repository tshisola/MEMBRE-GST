import '../database/database_manager.dart';
import 'platform_storage_adapter.dart';

/// Mobile — délègue au SQLite existant (aucune régression Android).
class MobileSQLiteAdapter implements PlatformStorageAdapter {
  bool _ready = false;

  @override
  bool get isReady => _ready;

  @override
  Future<void> initialize() async {
    await DatabaseManager.instance.open();
    _ready = DatabaseManager.instance.isReady;
  }

  @override
  Future<void> put(String box, String key, Map<String, dynamic> value) async {}

  @override
  Future<Map<String, dynamic>?> get(String box, String key) async => null;

  @override
  Future<List<Map<String, dynamic>>> getAll(String box) async => [];

  @override
  Future<void> delete(String box, String key) async {}

  @override
  Future<void> clearBox(String box) async {}
}
