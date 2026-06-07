import '../../shared/models/role_models.dart';
import '../security/role_permission_matrix.dart';
import '../../app/constants.dart';
import '../sync/member_sync_manager.dart';
import 'admin_password_reset_service.dart';
import 'local_account_management_service.dart';

/// Sécurité comptes — création, reset (jamais mot de passe en audit).
class AccountSecurityService {
  AccountSecurityService({LocalAccountManagementService? mgmt})
      : _mgmt = mgmt ?? LocalAccountManagementService();

  final LocalAccountManagementService _mgmt;

  Future<PasswordResetOutcome?> resetStaff({
    required UserRole actor,
    required String accountId,
  }) =>
      _mgmt.resetStaffPassword(actor: actor, accountId: accountId);

  bool canCreateAdmin(UserRole? actor) =>
      actor != null &&
      (actor.hasPermission(RolePermissionMatrix.canCreateAdmin) ||
          actor.hasRole(AppConstants.roleAdminGeneralOwner));

  bool canCreateOperator(UserRole? actor) =>
      actor != null &&
      (actor.hasPermission(RolePermissionMatrix.canCreateAccounts) ||
          actor.hasRole(AppConstants.roleAdminGeneralOwner) ||
          actor.hasRole(AppConstants.roleAdminGeneral));
}

/// Sync comptes SQLite ↔ Firebase après toute action.
class AccountSyncService {
  AccountSyncService._();
  static final AccountSyncService instance = AccountSyncService._();

  Future<void> afterAccountChange({String trigger = 'account_change'}) async {
    await MemberSyncManager().syncNow(silent: true);
  }
}
