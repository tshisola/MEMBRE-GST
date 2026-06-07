import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../app/constants.dart';
import '../../features/members/data/conflict_log_repository.dart';
import '../../features/members/data/local_member_repository.dart';
import '../../shared/models/ifcm_member_record.dart';
import '../database/database_helper.dart';
import '../firebase/firebase_initializer.dart';
import '../firebase/firebase_member_service.dart';
import 'sync_logger.dart';

/// Resolves conflicts between local SQLite and Firestore (updatedAt wins).
class ConflictResolver {
  ConflictResolver({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  Future<IfcmMemberRecord> resolve({
    required IfcmMemberRecord local,
    required IfcmMemberRecord remote,
  }) async {
    final localUpdated = local.updatedAt ?? local.createdAt ?? DateTime(1970);
    final remoteUpdated = remote.updatedAt ?? remote.createdAt ?? DateTime(1970);

    IfcmMemberRecord winner;
    if (remoteUpdated.isAfter(localUpdated)) {
      winner = remote.copyWith(syncStatus: AppConstants.syncStatusSynced);
      SyncLogger.info('Conflit résolu: version Firebase plus récente (${remote.memberCode})');
    } else {
      winner = local;
      SyncLogger.info('Conflit résolu: version locale plus récente (${local.memberCode})');
    }

    if (localUpdated != remoteUpdated) {
      await _logConflict(local, remote);
    }

    return winner;
  }

  /// Admin Général — force keep local version.
  Future<void> resolveKeepLocal({
    required String conflictId,
    required IfcmMemberRecord local,
  }) async {
    final repo = LocalMemberRepository();
    await repo.upsert(
      local.copyWith(
        syncStatus: AppConstants.syncStatusSynced,
        updatedAt: DateTime.now(),
      ),
    );
    if (FirebaseInitializer.isInitialized) {
      await FirebaseMemberRepository().upsertMember(local);
    }
    await ConflictLogRepository().markResolved(conflictId);
    SyncLogger.info('Conflit $conflictId résolu — version locale');
  }

  /// Admin Général — force keep Firebase version.
  Future<void> resolveKeepRemote({
    required String conflictId,
    required IfcmMemberRecord remote,
  }) async {
    final repo = LocalMemberRepository();
    await repo.upsert(
      remote.copyWith(syncStatus: AppConstants.syncStatusSynced),
    );
    await ConflictLogRepository().markResolved(conflictId);
    SyncLogger.info('Conflit $conflictId résolu — version Firebase');
  }

  Future<void> _logConflict(
    IfcmMemberRecord local,
    IfcmMemberRecord remote,
  ) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(AppConstants.tableSyncConflicts, {
      'id': _uuid.v4(),
      'member_id': local.id,
      'local_json': jsonEncode(local.toFirestore()),
      'remote_json': jsonEncode(remote.toFirestore()),
      'resolved': 0,
      'created_at': DateTime.now().toIso8601String(),
      'city': AppConstants.city,
    });
    await LocalMemberRepository().updateSyncStatus(
      local.id,
      syncStatus: AppConstants.syncStatusConflict,
    );
  }
}
