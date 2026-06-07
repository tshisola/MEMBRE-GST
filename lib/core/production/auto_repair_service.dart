import '../logging/app_logger.dart';
import '../sync/auto_sync_manager.dart';
import '../sync/offline_action_queue.dart';
import '../sync/offline_sync_queue.dart';
import '../sync/sync_retry_service.dart';
import 'app_health_checker.dart';

/// Réparation automatique légère (files d'attente + sync).
class AutoRepairService {
  AutoRepairService({
    AutoSyncManager? autoSync,
    SyncRetryService? retry,
  })  : _autoSync = autoSync ?? AutoSyncManager(),
        _retry = retry ?? SyncRetryService();

  final AutoSyncManager _autoSync;
  final SyncRetryService _retry;

  Future<AutoRepairResult> run() async {
    final health = await AppHealthChecker.check();
    if (!health.sqliteOpen) {
      return const AutoRepairResult(
        success: false,
        message: 'Préparation locale — réessayez dans un instant.',
      );
    }

    var repaired = 0;
    try {
      repaired += await _retry.resetRetryableFailures();
      await OfflineActionQueue().flushPending();
      await _autoSync.runBackgroundSync(trigger: 'auto_repair', forcePull: true);
      AppLogger.sync('AutoRepair: $repaired élément(s) retraités');
      return AutoRepairResult(
        success: true,
        message: 'Réparation terminée. Sync relancée.',
        itemsRetried: repaired,
      );
    } catch (e) {
      AppLogger.error('Sync', 'AutoRepair échoué', e);
      return AutoRepairResult(
        success: false,
        message: 'Réparation partielle: $e',
        itemsRetried: repaired,
      );
    }
  }
}

class AutoRepairResult {
  const AutoRepairResult({
    required this.success,
    required this.message,
    this.itemsRetried = 0,
  });

  final bool success;
  final String message;
  final int itemsRetried;
}
