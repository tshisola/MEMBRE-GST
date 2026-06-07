import '../../app/constants.dart';
import '../../shared/models/deleted_member_record.dart';
import '../../shared/models/ifcm_member_record.dart';
import '../firebase/firebase_initializer.dart';
import '../firebase/firestore_service.dart';
import '../sync/background_sync_trigger.dart';
import '../sync/offline_sync_queue.dart';

/// Enfile la synchronisation Firebase après suppression locale.
class MemberDeletionSyncService {
  MemberDeletionSyncService({
    OfflineSyncQueue? queue,
    FirestoreService? firestore,
    BackgroundSyncTrigger? syncTrigger,
  })  : _queue = queue ?? OfflineSyncQueue(),
        _firestore = firestore ?? FirestoreService(),
        _syncTrigger = syncTrigger ?? BackgroundSyncTrigger();

  final OfflineSyncQueue _queue;
  final FirestoreService _firestore;
  final BackgroundSyncTrigger _syncTrigger;

  Future<void> enqueueSoftDelete({
    required IfcmMemberRecord member,
    required DeletedMemberRecord deletedSnapshot,
    required String actorId,
    required String actorName,
  }) async {
    final payload = {
      'member': member.toFirestore(),
      'deletedMember': deletedSnapshot.toFirestore(),
      'actorId': actorId,
      'actorName': actorName,
    };
    await _queue.enqueue(
      entityType: 'member',
      entityId: member.id,
      actionType: AppConstants.syncActionDeleteMember,
      payload: payload,
    );
    await _syncTrigger.afterLocalWrite(
      entityType: 'member',
      entityId: member.id,
      actionType: AppConstants.syncActionDeleteMember,
      payload: payload,
    );
  }

  Future<void> enqueueDeactivate({
    required IfcmMemberRecord member,
    required String actorId,
  }) async {
    final payload = {
      'member': member.toFirestore(),
      'actorId': actorId,
    };
    await _queue.enqueue(
      entityType: 'member',
      entityId: member.id,
      actionType: AppConstants.syncActionDeactivateMember,
      payload: payload,
    );
    await _syncTrigger.afterLocalWrite(
      entityType: 'member',
      entityId: member.id,
      actionType: AppConstants.syncActionDeactivateMember,
      payload: payload,
    );
  }

  Future<void> enqueueRestore({
    required IfcmMemberRecord member,
    required String actorId,
    required String actorName,
  }) async {
    final payload = {
      'member': member.toFirestore(),
      'actorId': actorId,
      'actorName': actorName,
    };
    await _queue.enqueue(
      entityType: 'member',
      entityId: member.id,
      actionType: AppConstants.syncActionRestoreMember,
      payload: payload,
    );
    await _syncTrigger.afterLocalWrite(
      entityType: 'member',
      entityId: member.id,
      actionType: AppConstants.syncActionRestoreMember,
      payload: payload,
    );
  }

  Future<void> pushSoftDeleteNow({
    required IfcmMemberRecord member,
    required DeletedMemberRecord deletedSnapshot,
  }) async {
    if (!FirebaseInitializer.isInitialized) return;
    try {
      await _firestore.createDocument(
        AppConstants.collectionMembers,
        member.toFirestore(),
        id: member.cloudId ?? member.id,
      );
      await _firestore.createDocument(
        AppConstants.collectionDeletedMembers,
        deletedSnapshot.toFirestore(),
        id: member.id,
      );
    } catch (_) {}
  }

  Future<void> pushRestoreNow(IfcmMemberRecord member) async {
    if (!FirebaseInitializer.isInitialized) return;
    try {
      await _firestore.createDocument(
        AppConstants.collectionMembers,
        member.toFirestore(),
        id: member.cloudId ?? member.id,
      );
    } catch (_) {}
  }
}
