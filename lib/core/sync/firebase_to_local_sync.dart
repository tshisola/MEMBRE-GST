import '../../app/constants.dart';
import '../../features/members/data/local_member_repository.dart';
import '../../shared/models/ifcm_member_record.dart';
import '../firebase/firebase_member_service.dart';
import 'conflict_resolver.dart';
import 'sync_logger.dart';

/// Pulls Firestore members into SQLite local cache.
class FirebaseToLocalSync {
  FirebaseToLocalSync({
    LocalMemberRepository? localRepo,
    FirebaseMemberRepository? firebaseRepo,
    ConflictResolver? conflictResolver,
  })  : _local = localRepo ?? LocalMemberRepository(),
        _firebase = firebaseRepo ?? FirebaseMemberRepository(),
        _conflict = conflictResolver ?? ConflictResolver();

  final LocalMemberRepository _local;
  final FirebaseMemberRepository _firebase;
  final ConflictResolver _conflict;

  Future<int> pullAll() async {
    if (!_firebase.isAvailable) return 0;

    final remoteMembers = await _firebase.fetchAll();
    var updated = 0;

    for (final remote in remoteMembers) {
      final existing = await _local.getById(remote.localId);
      IfcmMemberRecord toSave;
      if (existing != null &&
          existing.syncStatus != AppConstants.syncStatusPending) {
        toSave = await _conflict.resolve(local: existing, remote: remote);
      } else {
        toSave = remote.copyWith(syncStatus: AppConstants.syncStatusSynced);
      }
      await _local.upsert(toSave);
      updated++;
    }

    SyncLogger.info('Firebase→Local: $updated membres mis à jour');
    return updated;
  }

  Future<int> applySnapshot(List<IfcmMemberRecord> remoteMembers) async {
    var updated = 0;
    for (final remote in remoteMembers) {
      if (!remote.isActive || remote.isDeleted) continue;
      final existing = await _local.getById(remote.localId);
      IfcmMemberRecord toSave;
      if (existing != null &&
          existing.syncStatus == AppConstants.syncStatusPending &&
          existing.createdBy != null) {
        // Garde la création locale en cours sur CET appareil seulement.
        continue;
      }
      if (existing != null) {
        toSave = await _conflict.resolve(local: existing, remote: remote);
      } else {
        toSave = remote.copyWith(syncStatus: AppConstants.syncStatusSynced);
      }
      await _local.upsert(toSave);
      updated++;
    }
    return updated;
  }
}

/// Updates local cache from realtime Firestore snapshots.
class MemberLocalCacheUpdater {
  MemberLocalCacheUpdater({FirebaseToLocalSync? sync})
      : _sync = sync ?? FirebaseToLocalSync();

  final FirebaseToLocalSync _sync;

  Future<int> updateFromRemote(List<IfcmMemberRecord> members) =>
      _sync.applySnapshot(members);
}
