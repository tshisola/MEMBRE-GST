import '../../app/constants.dart';
import '../storage/local_session.dart';

/// Contrôle qui peut fusionner des doublons.
class DuplicateMergePermissionGuard {
  DuplicateMergePermissionGuard._();

  static bool canMerge(LocalSession session) {
    if (session.role == AppConstants.roleAdminGeneral ||
        session.role == AppConstants.roleAdminGeneralOwner ||
        session.isAdminGeneralOwner) {
      return true;
    }

    final login = session.loginIdentifier?.toLowerCase() ?? '';
    final email = session.email?.toLowerCase() ?? '';

    if (login == AppConstants.staffLoginJeno ||
        email == AppConstants.staffEmailJeno.toLowerCase()) {
      return session.hasPermission(AppConstants.permissionMergeDuplicates);
    }

    if (login == AppConstants.staffLoginMechack ||
        email == AppConstants.staffEmailMechack.toLowerCase()) {
      return false;
    }

    if (session.accountType == AppConstants.accountTypeMember ||
        session.role == AppConstants.roleMember) {
      return false;
    }

    return session.role == AppConstants.roleAdmin &&
        session.hasPermission(AppConstants.permissionMergeDuplicates);
  }

  static String deniedMessage() =>
      'Vous n\'êtes pas autorisé à effectuer cette action.';
}

typedef SensitiveActionGuard = DuplicateMergePermissionGuard;
