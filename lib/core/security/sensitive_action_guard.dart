import '../../shared/models/role_models.dart';
import 'role_permission_matrix.dart';

/// Actions sensibles — vérification permissions sans afficher les règles.
class SensitiveActionGuard {
  const SensitiveActionGuard();

  bool canPerform(UserRole? user, String permission) {
    if (user == null) return false;
    if (user.hasPermission(RolePermissionMatrix.canManageEverything)) {
      return true;
    }
    return user.hasPermission(permission);
  }

  bool canAssignRoles(UserRole? user) =>
      canPerform(user, RolePermissionMatrix.canAssignRoles);

  bool canResetPasswords(UserRole? user) =>
      canPerform(user, RolePermissionMatrix.canResetPasswords);

  bool canViewAuditLogs(UserRole? user) =>
      canPerform(user, RolePermissionMatrix.canViewAuditLogs);

  String denialMessage() => 'Vous n\'êtes pas autorisé.';
}
