import 'package:flutter/foundation.dart';

import '../../app/constants.dart';
import '../auth/role_based_navigation_service.dart';
import '../security/member_privacy_guard.dart';
import '../security/role_permission_matrix.dart';
import 'web_role_compatibility_service.dart';

/// Gardes routes Web — messages propres, rôles identiques au mobile.
class WebRoleGuard {
  WebRoleGuard._();

  static String? redirect({
    required String path,
    required String? role,
    required String? accountType,
    required List<String> permissions,
  }) {
    if (!kIsWeb) return null;
    if (path.startsWith('/admin') &&
        !RoleBasedNavigationService.isAdminRole(role)) {
      return '/login/admin';
    }
    if (path.startsWith('/member') &&
        !RoleBasedNavigationService.isMemberAccount(accountType)) {
      return '/login/member';
    }
    if (path.startsWith('/admin') || path == '/dashboard') {
      if (role != null &&
          !WebAccessGuard.allow(role: role, permissions: permissions)) {
        return '/auth/access-denied';
      }
    }
    return null;
  }
}

class WebPermissionGuard {
  WebPermissionGuard._();

  static bool canAccess({
    required String permission,
    required List<String> permissions,
  }) {
    if (!kIsWeb) return true;
    return permissions.contains(permission) ||
        permissions.contains(RolePermissionMatrix.canManageEverything);
  }
}

class WebMemberPrivacyGuard {
  WebMemberPrivacyGuard._();

  static Map<String, dynamic> sanitize(Map<String, dynamic> data) =>
      MemberPrivacyGuard.sanitizeMemberMap(data);
}

class WebAdminRouteGuard {
  WebAdminRouteGuard._();

  static bool isAdminPath(String path) =>
      path.startsWith('/admin') ||
      path.startsWith('/dashboard') ||
      path.startsWith('/members');

  static bool allow({
    required String path,
    required String? role,
    required String? accountType,
  }) {
    if (!isAdminPath(path)) return true;
    return RoleBasedNavigationService.isAdminRole(role) &&
        accountType == AppConstants.accountTypeAdmin;
  }
}

class WebSensitiveActionGuard {
  WebSensitiveActionGuard._();

  static bool canPerform({
    required String action,
    required List<String> permissions,
    required String? role,
  }) {
    if (role == AppConstants.roleAdminGeneralOwner) return true;
    return permissions.contains(action);
  }
}
