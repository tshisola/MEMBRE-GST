import '../../app/constants.dart';
import '../storage/local_session.dart';
import 'app_deep_link_service.dart';

/// Vérifie les permissions avant navigation deep-link.
class DeepLinkPermissionGuard {
  DeepLinkPermissionGuard._();

  static bool canAccess(LocalSession session, String path) {
    if (session.accountType == AppConstants.accountTypeMember ||
        session.role == AppConstants.roleMember) {
      return DeepLinkGuard.isMemberSafe(path);
    }

    if (path.startsWith('/admin/sync/diagnostic')) {
      return session.role == AppConstants.roleAdminGeneral ||
          session.role == AppConstants.roleAdminGeneralOwner ||
          session.isAdminGeneralOwner;
    }

    if (path.startsWith('/advanced/duplicate-merge')) {
      return session.accountType != AppConstants.accountTypeMember;
    }

    return true;
  }
}

class PdfAccessGuard {
  PdfAccessGuard._();

  static bool canPreview(LocalSession session) {
    return session.accountType != AppConstants.accountTypeMember ||
        session.role != AppConstants.roleMember;
  }
}
