import '../../app/constants.dart';

/// Navigation helpers based on role and account type.
class RoleBasedNavigationService {
  RoleBasedNavigationService._();

  static String homeFor({
    required String? role,
    required String? accountType,
    required bool mustChangePassword,
  }) {
    if (mustChangePassword && accountType == AppConstants.accountTypeMember) {
      return '/auth/change-password';
    }
    if (role == AppConstants.roleMediaMember) {
      return '/media/member/dashboard';
    }
    if (accountType == AppConstants.accountTypeMember ||
        role == AppConstants.roleMember) {
      return '/member/dashboard';
    }
    return '/dashboard';
  }

  static String loginEntry() => '/login/member';

  static bool isAdminRole(String? role) =>
      role != null && AppConstants.adminRoles.contains(role);

  static bool isMemberAccount(String? accountType) =>
      accountType == AppConstants.accountTypeMember;
}
