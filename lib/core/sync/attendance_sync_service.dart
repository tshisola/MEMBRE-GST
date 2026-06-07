import '../../app/constants.dart';
import '../sync/background_sync_trigger.dart';

/// Synchronise le pointage vers Firebase via offline_sync_queue.
class AttendanceSyncService {
  AttendanceSyncService({BackgroundSyncTrigger? trigger})
      : _trigger = trigger ?? BackgroundSyncTrigger();

  final BackgroundSyncTrigger _trigger;

  Future<void> enqueueRecords(List<Map<String, dynamic>> records) async {
    for (final record in records) {
      final id = record['id'] as String? ?? '';
      if (id.isEmpty) continue;
      await _trigger.afterLocalWrite(
        entityType: 'media_attendance',
        entityId: id,
        actionType: AppConstants.syncActionUpdateAttendance,
        payload: record,
      );
    }
  }
}

/// Alias file d'attente pointage.
typedef AttendanceOfflineQueue = BackgroundSyncTrigger;
