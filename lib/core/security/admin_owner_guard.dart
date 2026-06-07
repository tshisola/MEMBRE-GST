import '../../app/constants.dart';
import '../../shared/models/role_models.dart';
import 'role_permission_matrix.dart';

/// Garde propriétaire — seul Verdick (admin_general_owner) a accès total.
class AdminOwnerGuard {
  const AdminOwnerGuard();

  bool isOwner(UserRole? user) =>
      user != null &&
      (user.hasRole(AppConstants.roleAdminGeneralOwner) ||
          user.hasPermission(RolePermissionMatrix.canManageEverything));

  bool canAccessDiagnostics(UserRole? user) =>
      isOwner(user) ||
      (user != null && user.hasPermission(RolePermissionMatrix.canViewDiagnostics));

  bool canManageFirebase(UserRole? user) =>
      isOwner(user) ||
      (user != null &&
          user.hasPermission(RolePermissionMatrix.canManageFirebaseFromApp));
}
