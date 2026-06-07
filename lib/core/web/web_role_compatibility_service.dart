import '../../app/constants.dart';
import '../security/role_permission_matrix.dart';

/// Compatibilité permissions Web — n'exige pas can_access_web si absent.
class WebRoleCompatibilityService {
  WebRoleCompatibilityService._();

  static const canAccessWeb = 'can_access_web';
  static const canAccessWebAdmin = RolePermissionMatrix.canAccessWebAdmin;

  static List<String> ensureWebPermissions({
    required String role,
    required List<String> permissions,
  }) {
    final base = permissions.isNotEmpty
        ? List<String>.from(permissions)
        : RolePermissionMatrix.permissionsForRole(role);
    _addIfMissing(base, canAccessWeb);
    if (_needsWebAdmin(role)) {
      _addIfMissing(base, canAccessWebAdmin);
    }
    return base;
  }

  static bool canAccessWebApp({
    required String role,
    required List<String> permissions,
  }) {
    if (permissions.contains(RolePermissionMatrix.canManageEverything)) {
      return true;
    }
    if (permissions.contains(canAccessWeb) ||
        permissions.contains(canAccessWebAdmin)) {
      return true;
    }
    return _defaultWebAccessForRole(role);
  }

  static bool _defaultWebAccessForRole(String role) {
    return AppConstants.adminRoles.contains(role) ||
        role == AppConstants.roleMember ||
        role == AppConstants.roleMediaMember;
  }

  static bool _needsWebAdmin(String role) {
    return role == AppConstants.roleAdminGeneralOwner ||
        role == AppConstants.roleAdminGeneral ||
        role == AppConstants.roleAdminSimple;
  }

  static void _addIfMissing(List<String> list, String permission) {
    if (!list.contains(permission)) list.add(permission);
  }
}

/// Charge rôles + permissions avec défauts Web.
class WebRolePermissionLoader {
  WebRolePermissionLoader._();

  static List<String> loadForRole(String role, {List<String>? stored}) {
    return WebRoleCompatibilityService.ensureWebPermissions(
      role: role,
      permissions: stored ?? const [],
    );
  }
}

/// Garde accès Web — ne bloque pas les comptes mobiles existants.
class WebAccessGuard {
  WebAccessGuard._();

  static bool allow({
    required String role,
    required List<String> permissions,
  }) {
    return WebRoleCompatibilityService.canAccessWebApp(
      role: role,
      permissions: permissions,
    );
  }

  static String? denyMessage() => 'Accès non autorisé.';
}
