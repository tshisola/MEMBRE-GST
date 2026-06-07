import '../../app/constants.dart';
import '../auth/auth_role_redirector.dart';

/// Redirections Web après login selon rôle.
class WebRoleRedirector {
  WebRoleRedirector._();

  static AuthRedirectResult redirectForProfile({
    required String role,
    required String accountType,
  }) {
    if (accountType == AppConstants.accountTypeMember) {
      if (role == AppConstants.roleMediaMember) {
        return AuthRedirectResult.route('/media/member/dashboard');
      }
      return AuthRedirectResult.route('/member/dashboard');
    }
    return AuthRoleRedirector.redirectForRole(role);
  }
}

/// Alias demandé.
typedef WebAuthRedirector = WebRoleRedirector;
