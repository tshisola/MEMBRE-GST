import 'package:uuid/uuid.dart';

import '../../app/constants.dart';
import '../../features/members/data/deleted_member_repository.dart';
import '../../features/members/data/local_member_repository.dart';
import '../../shared/models/deleted_member_record.dart';
import '../../shared/models/ifcm_member_record.dart';
import '../../shared/models/member_delete_request.dart';
import '../../shared/models/role_models.dart';
import '../auth/local_admin_auth_service.dart';
import '../messaging/app_error_presenter.dart';
import 'member_deletion_audit_service.dart';
import 'member_deletion_permission_checker.dart';
import 'member_deletion_sync_service.dart';

enum MemberDeletionMode { deactivate, softDelete, permanentDelete }

class MemberDeletionResult {
  const MemberDeletionResult({
    required this.success,
    this.message,
    this.isRequest = false,
  });

  final bool success;
  final String? message;
  final bool isRequest;
}

/// Suppression sécurisée de membres — offline-first, soft delete par défaut.
class MemberDeletionService {
  MemberDeletionService({
    LocalMemberRepository? memberRepo,
    DeletedMemberRepository? deletedRepo,
    MemberDeletionPermissionChecker? permissions,
    MemberDeletionAuditService? audit,
    MemberDeletionSyncService? sync,
    LocalAdminAuthService? adminAuth,
    Uuid? uuid,
  })  : _members = memberRepo ?? LocalMemberRepository(),
        _deleted = deletedRepo ?? DeletedMemberRepository(),
        _permissions = permissions ?? const MemberDeletionPermissionChecker(),
        _audit = audit ?? MemberDeletionAuditService(),
        _sync = sync ?? MemberDeletionSyncService(),
        _adminAuth = adminAuth ?? LocalAdminAuthService(),
        _uuid = uuid ?? const Uuid();

  final LocalMemberRepository _members;
  final DeletedMemberRepository _deleted;
  final MemberDeletionPermissionChecker _permissions;
  final MemberDeletionAuditService _audit;
  final MemberDeletionSyncService _sync;
  final LocalAdminAuthService _adminAuth;
  final Uuid _uuid;

  Future<MemberDeletionResult> execute({
    required UserRole actor,
    required String actorName,
    required IfcmMemberRecord member,
    required String reason,
    required String adminPassword,
    MemberDeletionMode mode = MemberDeletionMode.softDelete,
  }) async {
    try {
      if (mode == MemberDeletionMode.permanentDelete) {
        if (!_permissions.canPermanentDelete(actor)) {
          return MemberDeletionResult(
            success: false,
            message: _permissions.denialMessage(),
          );
        }
      } else if (mode == MemberDeletionMode.deactivate) {
        if (!_permissions.canDeactivate(actor)) {
          return MemberDeletionResult(
            success: false,
            message: _permissions.denialMessage(),
          );
        }
      } else if (!_permissions.canDelete(actor)) {
        if (_permissions.canRequestDelete(actor, member)) {
          return submitDeleteRequest(
            actor: actor,
            actorName: actorName,
            member: member,
            reason: reason,
          );
        }
        return MemberDeletionResult(
          success: false,
          message: _permissions.denialMessage(),
        );
      }

      if (actor.memberId == member.id) {
        return const MemberDeletionResult(
          success: false,
          message: 'Vous n\'êtes pas autorisé à supprimer ce membre.',
        );
      }

      if (reason.trim().length < 5) {
        return const MemberDeletionResult(
          success: false,
          message: 'Veuillez indiquer un motif de suppression.',
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

      switch (mode) {
        case MemberDeletionMode.deactivate:
          return _deactivate(actor, actorName, member, reason.trim());
        case MemberDeletionMode.softDelete:
          return _softDelete(actor, actorName, member, reason.trim());
        case MemberDeletionMode.permanentDelete:
          return _permanentDelete(actor, actorName, member, reason.trim());
      }
    } catch (e, st) {
      AppErrorPresenter.recordOnly(e, source: 'member_deletion', stack: st);
      return const MemberDeletionResult(
        success: false,
        message: 'Impossible de traiter la suppression pour le moment.',
      );
    }
  }

  Future<MemberDeletionResult> submitDeleteRequest({
    required UserRole actor,
    required String actorName,
    required IfcmMemberRecord member,
    required String reason,
  }) async {
    if (!_permissions.canRequestDelete(actor, member)) {
      return MemberDeletionResult(
        success: false,
        message: _permissions.denialMessage(),
      );
    }
    if (reason.trim().length < 5) {
      return const MemberDeletionResult(
        success: false,
        message: 'Veuillez indiquer un motif de suppression.',
      );
    }

    final request = MemberDeleteRequest(
      id: _uuid.v4(),
      memberId: member.id,
      requestedBy: actor.uid,
      requestedByRole: actor.primaryRole,
      reason: reason.trim(),
      createdAt: DateTime.now(),
    );
    await _deleted.insertDeleteRequest(request);
    await _audit.logDeleteRequest(
      actorId: actor.uid,
      actorName: actorName,
      memberId: member.id,
      reason: reason.trim(),
    );

    return MemberDeletionResult(
      success: true,
      isRequest: true,
      message: _permissions.requestSubmittedMessage(),
    );
  }

  Future<MemberDeletionResult> approveRequest({
    required UserRole actor,
    required String actorName,
    required MemberDeleteRequest request,
    required IfcmMemberRecord member,
    required String adminPassword,
  }) async {
    if (!_permissions.canApproveRequests(actor)) {
      return MemberDeletionResult(
        success: false,
        message: _permissions.denialMessage(),
      );
    }
    final result = await execute(
      actor: actor,
      actorName: actorName,
      member: member,
      reason: request.reason,
      adminPassword: adminPassword,
      mode: MemberDeletionMode.softDelete,
    );
    if (result.success && !result.isRequest) {
      await _deleted.updateRequestStatus(
        id: request.id,
        status: 'approved',
        approvedBy: actor.uid,
      );
    }
    return result;
  }

  Future<MemberDeletionResult> _deactivate(
    UserRole actor,
    String actorName,
    IfcmMemberRecord member,
    String reason,
  ) async {
    final now = DateTime.now();
    final updated = member.copyWith(
      isActive: false,
      updatedAt: now,
    );
    await _members.upsert(updated);
    await _audit.logDeactivate(
      actorId: actor.uid,
      actorName: actorName,
      memberId: member.id,
      reason: reason,
    );
    await _sync.enqueueDeactivate(member: updated, actorId: actor.uid);
    return const MemberDeletionResult(
      success: true,
      message: 'Membre désactivé avec succès.',
    );
  }

  Future<MemberDeletionResult> _softDelete(
    UserRole actor,
    String actorName,
    IfcmMemberRecord member,
    String reason,
  ) async {
    final now = DateTime.now();
    final role = actor.primaryRole ?? AppConstants.roleAdmin;
    final updated = member.copyWith(
      isActive: false,
      isDeleted: true,
      deletedAt: now,
      deletedBy: actor.uid,
      deletedReason: reason,
      updatedAt: now,
      syncStatus: AppConstants.syncStatusPending,
    );
    await _members.upsert(updated);

    final snapshot = DeletedMemberRecord(
      id: _uuid.v4(),
      memberId: member.id,
      memberCode: member.memberCode,
      fullName: member.displayName,
      phone: member.phone,
      departmentId: member.departmentId,
      departmentName: member.departmentName,
      deletedBy: actor.uid,
      deletedByRole: role,
      deletedReason: reason,
      deletedAt: now,
      restoreAvailable: true,
    );
    await _deleted.insertDeleted(snapshot);
    await _audit.logSoftDelete(
      actorId: actor.uid,
      actorName: actorName,
      memberId: member.id,
      reason: reason,
      memberCode: member.memberCode,
    );
    await _sync.enqueueSoftDelete(
      member: updated,
      deletedSnapshot: snapshot,
      actorId: actor.uid,
      actorName: actorName,
    );
    await _sync.pushSoftDeleteNow(
      member: updated,
      deletedSnapshot: snapshot,
    );

    return const MemberDeletionResult(
      success: true,
      message: 'Membre supprimé avec succès.',
    );
  }

  Future<MemberDeletionResult> _permanentDelete(
    UserRole actor,
    String actorName,
    IfcmMemberRecord member,
    String reason,
  ) async {
    await _deleted.insertDeleted(
      DeletedMemberRecord(
        id: _uuid.v4(),
        memberId: member.id,
        memberCode: member.memberCode,
        fullName: member.displayName,
        phone: member.phone,
        departmentId: member.departmentId,
        departmentName: member.departmentName,
        deletedBy: actor.uid,
        deletedByRole: actor.primaryRole,
        deletedReason: 'backup_before_permanent: $reason',
        deletedAt: DateTime.now(),
        restoreAvailable: false,
      ),
    );

    final now = DateTime.now();
    final updated = member.copyWith(
      isActive: false,
      isDeleted: true,
      deletedAt: now,
      deletedBy: actor.uid,
      deletedReason: reason,
      updatedAt: now,
      syncStatus: AppConstants.syncStatusPending,
    );
    await _members.upsert(updated);
    await _audit.logPermanentDelete(
      actorId: actor.uid,
      actorName: actorName,
      memberId: member.id,
      reason: reason,
    );
    await _sync.enqueueSoftDelete(
      member: updated,
      deletedSnapshot: DeletedMemberRecord(
        id: _uuid.v4(),
        memberId: member.id,
        memberCode: member.memberCode,
        fullName: member.displayName,
        deletedBy: actor.uid,
        deletedReason: reason,
        deletedAt: now,
        restoreAvailable: false,
      ),
      actorId: actor.uid,
      actorName: actorName,
    );

    return const MemberDeletionResult(
      success: true,
      message: 'Suppression définitive enregistrée.',
    );
  }
}
