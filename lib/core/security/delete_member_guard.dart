import '../../app/constants.dart';
import '../../shared/models/ifcm_member_record.dart';
import '../../shared/models/role_models.dart';
import 'role_permission_matrix.dart';

/// Contrôle d'accès pour la suppression de membres.
class DeleteMemberGuard {
  const DeleteMemberGuard();

  bool canDelete(UserRole? user) {
    if (user == null) return false;
    if (_isBlockedRole(user)) return false;
    if (user.hasRole(AppConstants.roleAdminGeneralOwner)) return true;
    if (user.hasRole(AppConstants.roleAdminGeneral)) {
      return user.hasPermission(AppPermissions.canDeleteMember);
    }
    return false;
  }

  bool canDeactivate(UserRole? user) => canDelete(user);

  bool canRequestDelete(UserRole? user, IfcmMemberRecord member) {
    if (user == null) return false;
    if (_isBlockedRole(user)) return false;
    if (canDelete(user)) return true;
    if (user.hasRole(AppConstants.roleDepartmentChief)) {
      final dept = user.departmentId;
      return dept != null &&
          dept.isNotEmpty &&
          dept == member.departmentId;
    }
    return false;
  }

  bool canRestore(UserRole? user) {
    if (user == null) return false;
    if (_isBlockedRole(user)) return false;
    if (user.hasRole(AppConstants.roleAdminGeneralOwner)) return true;
    if (user.hasRole(AppConstants.roleAdminGeneral)) {
      return user.hasPermission(AppPermissions.canDeleteMember);
    }
    return false;
  }

  bool canPermanentDelete(UserRole? user) {
    if (user == null) return false;
    return user.hasRole(AppConstants.roleAdminGeneralOwner);
  }

  bool canViewTrash(UserRole? user) => canRestore(user) || canDelete(user);

  bool canApproveDeleteRequests(UserRole? user) => canDelete(user);

  bool _isBlockedRole(UserRole user) {
    if (user.hasRole(AppConstants.roleMember)) return true;
    if (user.hasRole(AppConstants.roleMediaMember)) return true;
    if (user.hasRole(AppConstants.roleAttendanceOperator)) return true;
    return false;
  }

  String denialMessage() =>
      'Vous n\'êtes pas autorisé à supprimer ce membre.';

  String requestSubmittedMessage() =>
      'Votre demande de suppression a été enregistrée. '
      'Elle sera traitée par un administrateur autorisé.';
}
