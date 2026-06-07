import '../../app/constants.dart';
import 'first_login_password_change_guard.dart';

class AuthRedirectResult {
  const AuthRedirectResult._({
    required this.isSuccess,
    this.route,
    this.error,
  });

  final bool isSuccess;
  final String? route;
  final String? error;

  factory AuthRedirectResult.route(String path) =>
      AuthRedirectResult._(isSuccess: true, route: path);

  factory AuthRedirectResult.error(String message) =>
      AuthRedirectResult._(isSuccess: false, error: message);
}

/// Redirects users after login based on role and account type.
class AuthRoleRedirector {
  AuthRoleRedirector._();

  static AuthRedirectResult redirectForRole(String role) {
    if (role == AppConstants.roleAttendanceOperator) {
      return AuthRedirectResult.route('/media/attendance');
    }
    if (AppConstants.adminRoles.contains(role)) {
      return AuthRedirectResult.route('/dashboard');
    }
    if (role == AppConstants.roleMediaMember) {
      return AuthRedirectResult.route('/media/member/dashboard');
    }
    if (role == AppConstants.roleMember) {
      return AuthRedirectResult.route('/member/dashboard');
    }
    return AuthRedirectResult.route('/dashboard');
  }

  static String? guardRoute({
    required String path,
    required String? role,
    required String? accountType,
    required bool mustChangePassword,
    String? activationStatus,
  }) {
    if (mustChangePassword) {
      final guardPath = FirstLoginPasswordChangeGuard.redirectPath(
        accountType: accountType,
        mustChangePassword: mustChangePassword,
        path: path,
      );
      if (guardPath != null) return guardPath;
    }

    if (accountType == AppConstants.accountTypeMember) {
      if (_isAdminPath(path)) return '/auth/access-denied';
      if (role == AppConstants.roleMediaMember &&
          activationStatus == AppConstants.activationStatusPending &&
          !path.startsWith('/auth/')) {
        return '/auth/pending-activation';
      }
      return null;
    }

    if (accountType == AppConstants.accountTypeAdmin &&
        path.startsWith('/member/')) {
      return '/dashboard';
    }

    if (role == AppConstants.roleMember && _isAdminPath(path)) {
      return '/auth/access-denied';
    }

    return null;
  }

  static bool _isAdminPath(String path) {
    if (path.startsWith('/member/')) return false;
    return path.startsWith('/admin') ||
        path.startsWith('/media') ||
        path.startsWith('/members') ||
        path.startsWith('/departments') ||
        path == '/dashboard' ||
        path == '/settings' ||
        path.startsWith('/login/admin') ||
        path.startsWith('/login/legacy');
  }
}
