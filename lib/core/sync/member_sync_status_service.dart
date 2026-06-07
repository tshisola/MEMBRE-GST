import '../../app/constants.dart';
import '../../features/members/data/local_member_repository.dart';
import '../database/database_helper.dart';

/// Exposes member sync counts for UI badges and sync center.
class MemberSyncStatusService {
  MemberSyncStatusService({LocalMemberRepository? local})
      : _local = local ?? LocalMemberRepository();

  final LocalMemberRepository _local;

  Future<MemberSyncSummary> loadSummary() async {
    final pending = await _local.countBySyncStatus(AppConstants.syncStatusPending);
    final syncing = await _local.countBySyncStatus(AppConstants.syncStatusSyncing);
    final synced = await _local.countBySyncStatus(AppConstants.syncStatusSynced);
    final errors = await _local.countBySyncStatus(AppConstants.syncStatusError);
    final conflicts = await _local.countBySyncStatus(AppConstants.syncStatusConflict);
    final localOnly = await _local.countBySyncStatus(AppConstants.syncStatusLocal);

    final db = await DatabaseHelper.instance.database;
    final queueRows = await db.query(
      AppConstants.tableOfflineActionQueue,
      where: "action_type = ? AND status IN ('pending', 'failed')",
      whereArgs: ['member_upsert'],
    );

    return MemberSyncSummary(
      pending: pending + queueRows.length,
      syncing: syncing,
      synced: synced,
      errors: errors,
      conflicts: conflicts,
      localOnly: localOnly,
    );
  }
}

class MemberSyncSummary {
  const MemberSyncSummary({
    required this.pending,
    required this.syncing,
    required this.synced,
    required this.errors,
    required this.conflicts,
    required this.localOnly,
  });

  final int pending;
  final int syncing;
  final int synced;
  final int errors;
  final int conflicts;
  final int localOnly;

  int get totalIssues => pending + errors + conflicts;
}
