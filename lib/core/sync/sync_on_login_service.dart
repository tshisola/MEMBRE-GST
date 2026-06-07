import '../storage/local_session.dart';
import 'auto_sync_manager.dart';

/// Sync after successful login.
class SyncOnLoginService {
  SyncOnLoginService({required AutoSyncManager autoSync}) : _autoSync = autoSync;

  final AutoSyncManager _autoSync;

  Future<void> afterLogin(LocalSession session) =>
      _autoSync.runBackgroundSync(trigger: 'login', session: session);
}
