import '../../app/constants.dart';
import '../../shared/models/admin_staff_account_model.dart';
import '../../shared/models/role_models.dart';
import '../security/delete_member_guard.dart';
import '../security/sensitive_action_guard.dart';
import '../services/permission_service.dart';
import '../sync/member_sync_manager.dart';
import 'admin_password_reset_service.dart';
import 'local_admin_auth_service.dart';
import 'member_auth_service.dart';
import 'staff_firebase_linker.dart';
import 'staff_seed_credentials.dart';

export '../../shared/models/role_models.dart' show UserRole;

/// Gestion comptes locale — création, activation, réinitialisation.
class LocalAccountManagementService {
  LocalAccountManagementService({
    LocalAdminAuthService? staffAuth,
    MemberAuthService? memberAuth,
    AdminPasswordResetService? resetService,
    PermissionService? permissions,
    DeleteMemberGuard? deleteGuard,
    SensitiveActionGuard? sensitiveGuard,
    StaffFirebaseLinker? linker,
  })  : _staff = staffAuth ?? LocalAdminAuthService(),
        _member = memberAuth ?? MemberAuthService(),
        _reset = resetService ?? AdminPasswordResetService(),
        _permissions = permissions ?? PermissionService(),
        _deleteGuard = deleteGuard ?? const DeleteMemberGuard(),
        _sensitive = sensitiveGuard ?? const SensitiveActionGuard(),
        _linker = linker ?? StaffFirebaseLinker();

  final LocalAdminAuthService _staff;
  final MemberAuthService _member;
  final AdminPasswordResetService _reset;
  final PermissionService _permissions;
  final DeleteMemberGuard _deleteGuard;
  final SensitiveActionGuard _sensitive;
  final StaffFirebaseLinker _linker;

  Future<List<AdminStaffAccount>> listStaff(UserRole? actor) async {
    if (!_permissions.isNotMemberTryingAdminData(actor)) return [];
    return _staff.listStaff();
  }

  Future<({AdminStaffAccount account, String temporaryPassword})?> createStaffAccount({
    required UserRole actor,
    required String loginIdentifier,
    required String displayName,
    required String role,
    required String email,
    bool isOwner = false,
  }) async {
    if (role == AppConstants.roleAdminGeneralOwner &&
        !actor.hasRole(AppConstants.roleAdminGeneralOwner)) {
      return null;
    }
    if (role == AppConstants.roleAdminGeneral &&
        !actor.hasRole(AppConstants.roleAdminGeneralOwner)) {
      return null;
    }
    if (!_sensitive.canResetPasswords(actor) &&
        !_permissions.canAssignRoles(actor) &&
        !actor.hasPermission('can_create_accounts')) {
      return null;
    }

    final tempPwd = StaffSeedCredentials.seedPassword(loginIdentifier) ??
        'Ml${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}!9';

    final account = await _staff.upsertStaff(
      loginIdentifier: loginIdentifier,
      displayName: displayName,
      role: role,
      email: email.trim(),
      plainPassword: tempPwd,
      isOwner: isOwner,
      mustChangePassword: true,
      skipIfExists: false,
    );
    if (account == null) return null;

    await _linker.linkStaffAccount(
      account: account,
      password: tempPwd,
      signOutAfter: true,
    );

    await MemberSyncManager().syncNow(silent: true);
    return (account: account, temporaryPassword: tempPwd);
  }

  Future<PasswordResetOutcome?> resetStaffPassword({
    required UserRole actor,
    required String accountId,
  }) async {
    if (!_sensitive.canResetPasswords(actor)) return null;
    final outcome = await _reset.resetStaff(
      accountId: accountId,
      actorId: actor.uid,
    );
    await MemberSyncManager().syncNow(silent: true);
    return outcome;
  }

  Future<PasswordResetOutcome?> resetMemberPassword({
    required UserRole actor,
    required String accountId,
  }) async {
    if (!_sensitive.canResetPasswords(actor)) return null;
    return _reset.resetMember(accountId: accountId, actorId: actor.uid);
  }

  bool canDeleteMember(UserRole? actor) => _deleteGuard.canDelete(actor);

  String get deleteDenialMessage => _deleteGuard.denialMessage();
}

typedef AccountManagementService = LocalAccountManagementService;
