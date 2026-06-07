import '../../app/constants.dart';
import '../../features/members/data/deleted_member_repository.dart';
import '../../features/members/data/local_member_repository.dart';
import '../../shared/models/ifcm_member_record.dart';
import '../../shared/models/role_models.dart';
import '../auth/local_admin_auth_service.dart';
import '../messaging/app_error_presenter.dart';
import 'member_deletion_audit_service.dart';
import 'member_deletion_permission_checker.dart';
import 'member_deletion_service.dart';
import 'member_deletion_sync_service.dart';

/// Restauration de membres depuis la corbeille.
class MemberRestoreService {
  MemberRestoreService({
    LocalMemberRepository? memberRepo,
    DeletedMemberRepository? deletedRepo,
    MemberDeletionPermissionChecker? permissions,
    MemberDeletionAuditService? audit,
    MemberDeletionSyncService? sync,
    LocalAdminAuthService? adminAuth,
  })  : _members = memberRepo ?? LocalMemberRepository(),
        _deleted = deletedRepo ?? DeletedMemberRepository(),
        _permissions = permissions ?? const MemberDeletionPermissionChecker(),
        _audit = audit ?? MemberDeletionAuditService(),
        _sync = sync ?? MemberDeletionSyncService(),
        _adminAuth = adminAuth ?? LocalAdminAuthService();

  final LocalMemberRepository _members;
  final DeletedMemberRepository _deleted;
  final MemberDeletionPermissionChecker _permissions;
  final MemberDeletionAuditService _audit;
  final MemberDeletionSyncService _sync;
  final LocalAdminAuthService _adminAuth;

  Future<MemberDeletionResult> restore({
    required UserRole actor,
    required String actorName,
    required String memberId,
    required String adminPassword,
    String? reason,
  }) async {
    try {
      if (!_permissions.canRestore(actor)) {
        return MemberDeletionResult(
          success: false,
          message: _permissions.denialMessage(),
        );
      }

      final passwordOk = await _adminAuth.verifyPasswordForAccount(
        actor.uid,
        adminPassword,
      );
      if (!passwordOk) {
        return const MemberDeletionResult(
          success: false,
          message: 'Mot de passe administrateur incorrect.',
        );
      }

      final member = await _members.getById(memberId);
      if (member == null) {
        return const MemberDeletionResult(
          success: false,
          message: 'Membre introuvable.',
        );
      }

      final now = DateTime.now();
      final restored = member.copyWith(
        isActive: true,
        isDeleted: false,
        clearDeletionMeta: true,
        updatedAt: now,
        syncStatus: AppConstants.syncStatusPending,
      );
      await _members.upsert(restored);
      await _deleted.removeByMemberId(memberId);
      await _deleted.insertRestoreLog(
        memberId: memberId,
        restoredBy: actor.uid,
        reason: reason,
      );
      await _audit.logRestore(
        actorId: actor.uid,
        actorName: actorName,
        memberId: memberId,
        reason: reason,
      );
      await _sync.enqueueRestore(
        member: restored,
        actorId: actor.uid,
        actorName: actorName,
      );
      await _sync.pushRestoreNow(restored);

      return const MemberDeletionResult(
        success: true,
        message: 'Membre restauré avec succès.',
      );
    } catch (e, st) {
      AppErrorPresenter.recordOnly(e, source: 'member_restore', stack: st);
      return const MemberDeletionResult(
        success: false,
        message: 'Impossible de restaurer ce membre pour le moment.',
      );
    }
  }
}
