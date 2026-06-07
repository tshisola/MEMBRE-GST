import '../../../app/constants.dart';
import '../../../features/members/data/local_member_repository.dart';
import '../../../shared/models/ifcm_member_record.dart';
import '../../database/database_helper.dart';
import '../../sync/member_sync_manager.dart';
import 'duplicate_merge_audit_service.dart';
import 'duplicate_similarity_engine.dart';

/// Fusionne deux membres — conserve présences, QR principal et données.
class DuplicateMergeService {
  DuplicateMergeService({
    LocalMemberRepository? repo,
    DuplicateSimilarityEngine? similarity,
    DuplicateMergeAuditService? audit,
    MemberSyncManager? sync,
  })  : _repo = repo ?? LocalMemberRepository(),
        _similarity = similarity ?? DuplicateSimilarityEngine(),
        _audit = audit ?? DuplicateMergeAuditService(),
        _sync = sync ?? MemberSyncManager();

  final LocalMemberRepository _repo;
  final DuplicateSimilarityEngine _similarity;
  final DuplicateMergeAuditService _audit;
  final MemberSyncManager _sync;

  Future<DuplicateMergeResult> preview(String memberIdA, String memberIdB) async {
    final a = await _repo.getById(memberIdA);
    final b = await _repo.getById(memberIdB);
    if (a == null || b == null) {
      return const DuplicateMergeResult(
        success: false,
        message: 'Profil introuvable.',
      );
    }
    final comparison = _similarity.compare(a, b);
    return DuplicateMergeResult(
      success: true,
      message: 'Aperçu prêt.',
      comparison: comparison,
    );
  }

  Future<DuplicateMergeResult> merge({
    required String primaryMemberId,
    required String secondaryMemberId,
    required String actorId,
    String? actorName,
  }) async {
    if (primaryMemberId == secondaryMemberId) {
      return const DuplicateMergeResult(
        success: false,
        message: 'Sélection invalide.',
      );
    }

    final primary = await _repo.getById(primaryMemberId);
    final secondary = await _repo.getById(secondaryMemberId);
    if (primary == null || secondary == null) {
      return const DuplicateMergeResult(
        success: false,
        message: 'Profil introuvable.',
      );
    }

    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().toIso8601String();
      final merged = _mergeFields(primary, secondary);

      await db.transaction((txn) async {
        await txn.update(
          AppConstants.tableMediaAttendance,
          {'member_id': primaryMemberId, 'updated_at': now},
          where: 'member_id = ?',
          whereArgs: [secondaryMemberId],
        );

        await txn.update(
          AppConstants.tableMembers,
          {
            ...merged.toSqlite(),
            'updated_at': now,
            'sync_status': AppConstants.syncStatusPending,
          },
          where: 'id = ?',
          whereArgs: [primaryMemberId],
        );

        await txn.update(
          AppConstants.tableMembers,
          {
            'is_merged': 1,
            'merged_into': primaryMemberId,
            'merged_at': now,
            'is_active': 0,
            'is_deleted': 0,
            'sync_status': AppConstants.syncStatusPending,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [secondaryMemberId],
        );
      });

      await _audit.recordMerge(
        actorId: actorId,
        actorName: actorName,
        primaryId: primaryMemberId,
        secondaryId: secondaryMemberId,
        primaryName: primary.displayName,
        secondaryName: secondary.displayName,
      );

      await _sync.syncNow(silent: true);

      return DuplicateMergeResult(
        success: true,
        message: 'Fusion réussie. Données synchronisées.',
        primaryMemberId: primaryMemberId,
      );
    } catch (e) {
      return const DuplicateMergeResult(
        success: false,
        message: 'Fusion impossible pour le moment.',
      );
    }
  }

  IfcmMemberRecord _mergeFields(IfcmMemberRecord primary, IfcmMemberRecord secondary) {
    return primary.copyWith(
      phone: primary.phone?.trim().isNotEmpty == true ? primary.phone : secondary.phone,
      email: primary.email?.trim().isNotEmpty == true ? primary.email : secondary.email,
      address: primary.address?.trim().isNotEmpty == true ? primary.address : secondary.address,
      departmentId: primary.departmentId ?? secondary.departmentId,
      departmentName: primary.departmentName ?? secondary.departmentName,
      pastorName: primary.pastorName ?? secondary.pastorName,
      discipleName: primary.discipleName ?? secondary.discipleName,
      qrData: primary.qrData.isNotEmpty ? primary.qrData : secondary.qrData,
      cloudId: primary.cloudId ?? secondary.cloudId,
    );
  }
}

class DuplicateMergeResult {
  const DuplicateMergeResult({
    required this.success,
    required this.message,
    this.comparison,
    this.primaryMemberId,
  });

  final bool success;
  final String message;
  final DuplicateComparison? comparison;
  final String? primaryMemberId;
}
