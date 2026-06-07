import 'dart:async';

import 'dart:async';

import 'auto_sync_manager.dart';
import 'offline_sync_queue.dart';

/// Enqueues offline actions and triggers background sync (non-blocking).
class BackgroundSyncTrigger {
  BackgroundSyncTrigger({
    OfflineSyncQueue? queue,
    AutoSyncManager? autoSync,
  })  : _queue = queue ?? OfflineSyncQueue(),
        _autoSync = autoSync ?? AutoSyncManager();

  final OfflineSyncQueue _queue;
  final AutoSyncManager _autoSync;

  Future<void> afterLocalWrite({
    required String entityType,
    required String entityId,
    required String actionType,
    Map<String, dynamic>? payload,
  }) async {
    await _queue.enqueue(
      entityType: entityType,
      entityId: entityId,
      actionType: actionType,
      payload: payload,
    );
    unawaited(_autoSync.runBackgroundSync(trigger: actionType));
  }
}
