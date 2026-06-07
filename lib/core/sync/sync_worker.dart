import '../../app/constants.dart';
import '../firebase/firebase_initializer.dart';
import '../firebase/firestore_service.dart';
import '../sync/local_to_firebase_sync.dart';
import 'offline_action_queue.dart';
import 'offline_sync_queue.dart';
import '../logging/technical_error_repository.dart';
import '../messaging/user_friendly_error_mapper.dart';
import 'sync_logger.dart';

/// Processes items from [OfflineSyncQueue] and legacy [OfflineActionQueue].
class SyncWorker {
  SyncWorker({
    OfflineSyncQueue? queue,
    OfflineActionQueue? legacyQueue,
    LocalToFirebaseSync? memberPush,
    FirestoreService? firestore,
  })  : _queue = queue ?? OfflineSyncQueue(),
        _legacy = legacyQueue ?? OfflineActionQueue(),
        _memberPush = memberPush ?? LocalToFirebaseSync(),
        _firestore = firestore ?? FirestoreService();

  final OfflineSyncQueue _queue;
  final OfflineActionQueue _legacy;
  final LocalToFirebaseSync _memberPush;
  final FirestoreService _firestore;

  Future<SyncWorkerResult> run() async {
    if (!FirebaseInitializer.isInitialized) {
      return const SyncWorkerResult(processed: 0, failed: 0, skipped: true);
    }

    var processed = 0;
    var failed = 0;

    final legacyCount = await _legacy.flushPending();
    processed += legacyCount;

    final items = await _queue.listPending();
    for (final item in items) {
      if (item.retryCount >= AppConstants.syncMaxRetries &&
          item.status == AppConstants.queueStatusFailed) {
        continue;
      }
      await _queue.markSyncing(item.id);
      try {
        await _dispatch(item);
        await _queue.markSynced(item.id);
        processed++;
      } catch (e, st) {
        if (UserFriendlyErrorMapper.isPermissionDenied(e) ||
            UserFriendlyErrorMapper.isNetworkIssue(e)) {
          await _queue.markPendingRetry(item.id, e.toString());
        } else {
          await _queue.markFailed(item.id, e.toString());
          failed++;
        }
        TechnicalErrorRepository.record(
          source: 'sync_worker_${item.actionType}',
          error: e,
          stack: st,
        );
        SyncLogger.error('SyncWorker ${item.actionType}', e);
      }
    }

    return SyncWorkerResult(processed: processed, failed: failed);
  }

  Future<void> _dispatch(OfflineSyncQueueItem item) async {
    final payload = item.payload ?? {};
    switch (item.actionType) {
      case AppConstants.syncActionCreateMember:
      case AppConstants.syncActionUpdateMember:
        await _memberPush.pushMember(item.entityId);
      case AppConstants.syncActionCreateMemberAccount:
        await _firestore.createDocument(
          AppConstants.collectionMemberAccounts,
          payload,
          id: payload['id'] as String? ?? item.entityId,
        );
      case AppConstants.syncActionUpdateAttendance:
        await _firestore.createDocument(
          AppConstants.collectionMediaAttendance,
          payload,
          id: payload['id'] as String? ?? item.entityId,
        );
      case AppConstants.syncActionSendMessage:
        await _firestore.createDocument(
          AppConstants.collectionMessages,
          payload,
          id: payload['id'] as String? ?? item.entityId,
        );
      case AppConstants.syncActionCreateDepartmentList:
        await _firestore.createDocument(
          AppConstants.collectionDepartmentManualLists,
          payload,
          id: payload['id'] as String? ?? item.entityId,
        );
      case AppConstants.syncActionDeleteDepartmentList:
        await _firestore.deleteDocument(
          AppConstants.collectionDepartmentManualLists,
          item.entityId,
        );
      case AppConstants.syncActionAssignRole:
        await _firestore.createDocument(
          AppConstants.collectionMediaRoles,
          payload,
          id: payload['id'] as String? ?? item.entityId,
        );
      case AppConstants.syncActionDeleteMember:
      case AppConstants.syncActionDeactivateMember:
        await _memberPush.pushMember(item.entityId);
        final deleted = payload['deletedMember'] as Map<String, dynamic>?;
        if (deleted != null) {
          await _firestore.createDocument(
            AppConstants.collectionDeletedMembers,
            deleted,
            id: item.entityId,
          );
        }
      case AppConstants.syncActionRestoreMember:
        await _memberPush.pushMember(item.entityId);
      default:
        SyncLogger.info('SyncWorker: action non gérée ${item.actionType}');
    }
  }
}

class SyncWorkerResult {
  const SyncWorkerResult({
    required this.processed,
    required this.failed,
    this.skipped = false,
  });

  final int processed;
  final int failed;
  final bool skipped;
}
