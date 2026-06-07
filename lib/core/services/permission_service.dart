import '../../app/constants.dart';
import '../../shared/models/role_models.dart';
import '../security/admin_owner_guard.dart';
import '../security/role_permission_matrix.dart';

/// Vérifications rôle / permission — aligné Firestore, jamais affiché à l'écran.
class PermissionService {
  PermissionService();

  final AdminOwnerGuard _ownerGuard = AdminOwnerGuard();

  bool isSignedIn(UserRole? user) => user != null;

  bool isAdminGeneral(UserRole? user) =>
      user != null &&
      (user.isAdminGeneral ||
          user.hasRole(AppConstants.roleAdminGeneralOwner));

  bool isAdminOwner(UserRole? user) => _ownerGuard.isOwner(user);

  bool hasRole(UserRole? user, String role) =>
      user != null && user.hasRole(role);

  bool hasPermission(UserRole? user, String permission) =>
      user != null && user.hasPermission(permission);

  bool canManageEverything(UserRole? user) =>
      hasPermission(user, RolePermissionMatrix.canManageEverything);

  bool canDeleteAccount(UserRole? user) {
    if (_ownerGuard.isOwner(user)) return true;
    if (RolePermissionMatrix.onlyOwnerCanDelete()) return false;
    return hasPermission(user, RolePermissionMatrix.canDeleteMember);
  }

  bool canTakeAttendance(UserRole? user) =>
      hasPermission(user, RolePermissionMatrix.canTakeAttendance) ||
      hasRole(user, AppConstants.roleAttendanceOperator);

  bool canManageDepartment(UserRole? user, String departmentId) {
    if (user == null) return false;
    if (isAdminGeneral(user) || canManageEverything(user)) return true;
    return hasRole(user, AppConstants.roleDepartmentChief) &&
        user.departmentId == departmentId;
  }

  bool isMemberRestricted(UserRole? user) =>
      hasRole(user, AppConstants.roleMember) ||
      hasRole(user, AppConstants.roleMediaMember);

  bool isNotMemberTryingAdminData(UserRole? user) {
    if (user == null) return false;
    return !isMemberRestricted(user);
  }

  bool canReadMembers(UserRole? user) => isNotMemberTryingAdminData(user);

  bool canWriteMember(
    UserRole? user, {
    required String targetDepartmentId,
    bool isOwner = false,
  }) {
    if (user == null) return false;
    if (isNotMemberTryingAdminData(user)) return true;
    return isOwner && canManageDepartment(user, targetDepartmentId);
  }

  bool canReadWeeklyResults(UserRole? user, {String? memberId}) {
    if (user == null) return false;
    if (isNotMemberTryingAdminData(user)) return true;
    return memberId != null && user.memberId == memberId;
  }

  bool canWriteWeeklyResults(UserRole? user) =>
      isNotMemberTryingAdminData(user);

  bool canReadAttendanceRecords(UserRole? user) =>
      isNotMemberTryingAdminData(user) || canTakeAttendance(user);

  bool canCreateAttendanceRecord(UserRole? user) => canTakeAttendance(user);

  bool canUpdateAttendanceRecord(UserRole? user) => isAdminGeneral(user);

  bool canDeleteAttendanceRecord(UserRole? user) => isAdminOwner(user);

  bool canReadSyncQueue(UserRole? user) => isNotMemberTryingAdminData(user);

  bool canWriteSyncQueue(UserRole? user) => isNotMemberTryingAdminData(user);

  bool canReadAuditLogs(UserRole? user) =>
      hasPermission(user, RolePermissionMatrix.canViewAuditLogs) ||
      isAdminGeneral(user);

  bool canViewDiagnostics(UserRole? user) =>
      _ownerGuard.canAccessDiagnostics(user);

  bool canForceSync(UserRole? user) =>
      hasPermission(user, RolePermissionMatrix.canForceSync) ||
      isAdminGeneral(user);

  bool canResetPasswords(UserRole? user) =>
      hasPermission(user, RolePermissionMatrix.canResetPasswords) ||
      isAdminOwner(user);

  bool canAssignRoles(UserRole? user) =>
      hasPermission(user, RolePermissionMatrix.canAssignRoles) ||
      isAdminOwner(user);

  bool canManageMediaFirestore(UserRole? user) {
    if (isAdminGeneral(user)) return true;
    return canManageDepartment(user, AppConstants.mediaDepartmentId) ||
        hasPermission(user, AppPermissions.canManageMediaLists);
  }

  UserRole? fromSession({
    required String? userId,
    required String? role,
    List<String> permissions = const [],
    String? departmentId,
    String? memberId,
  }) {
    if (userId == null || role == null) return null;
    return UserRole(
      uid: userId,
      roles: [role],
      permissions: permissions,
      departmentId: departmentId,
      memberId: memberId,
    );
  }
}
