import '../../app/constants.dart';

/// Redirige vers changement de mot de passe obligatoire (admin + membre).
class FirstLoginPasswordChangeGuard {
  FirstLoginPasswordChangeGuard._();

  static String? redirectPath({
    required String? accountType,
    required bool mustChangePassword,
    required String path,
  }) {
    if (!mustChangePassword) return null;
    if (path.startsWith('/auth/change-password')) return null;
    if (path.startsWith('/login')) return null;
    if (accountType == AppConstants.accountTypeMember ||
        accountType == AppConstants.accountTypeAdmin) {
      return '/auth/change-password';
    }
    return null;
  }
}
