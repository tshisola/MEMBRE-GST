import '../../app/constants.dart';
import '../database/database_helper.dart';
import 'offline_sync_queue.dart';

/// Auto-retry failed sync queue items (max 3 attempts).
class SyncRetryService {
  SyncRetryService({OfflineSyncQueue? queue}) : _queue = queue ?? OfflineSyncQueue();

  final OfflineSyncQueue _queue;

  Future<int> resetRetryableFailures() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      AppConstants.tableOfflineSyncQueue,
      where: 'status = ? AND retry_count < ?',
      whereArgs: [AppConstants.queueStatusFailed, AppConstants.syncMaxRetries],
    );
    for (final row in rows) {
      await db.update(
        AppConstants.tableOfflineSyncQueue,
        {
          'status': AppConstants.queueStatusPending,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
    return rows.length;
  }

  Future<List<OfflineSyncQueueItem>> criticalFailures() =>
      _queue.listFailedAboveMax();
}
