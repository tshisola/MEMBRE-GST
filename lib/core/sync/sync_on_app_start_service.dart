import '../storage/local_session.dart';
import 'auto_sync_manager.dart';

/// Sync at cold start (called from AppInitializer).
class SyncOnAppStartService {
  SyncOnAppStartService({AutoSyncManager? autoSync})
      : _autoSync = autoSync ?? AutoSyncManager();

  final AutoSyncManager _autoSync;

  Future<void> run() => _autoSync.runBackgroundSync(trigger: 'cold_start');
}
