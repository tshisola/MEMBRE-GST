import '../../app/constants.dart';
import '../../shared/models/role_models.dart';
import '../security/role_permission_matrix.dart';
import 'permission_service.dart';

/// Permissions listes Média — jamais affichées à l'écran.
class MediaPermissionService {
  MediaPermissionService({PermissionService? base})
      : _base = base ?? PermissionService();

  final PermissionService _base;

  static const canViewMediaLists = 'can_view_media_lists';
  static const canCreateMediaList = 'can_create_media_list';
  static const canGenerateMediaAutoList = 'can_generate_media_auto_list';
  static const canCreateMediaManualList = 'can_create_media_manual_list';
  static const canExportMediaPdf = 'can_export_media_pdf';
  static const canExportMediaCsv = 'can_export_media_csv';

  bool canViewLists(UserRole? user) {
    if (user == null) return false;
    if (_base.canManageEverything(user)) return true;
    if (_base.isAdminGeneral(user)) return true;
    return user.hasPermission(canViewMediaLists) ||
        user.hasPermission(AppPermissions.canManageMediaLists) ||
        _base.canTakeAttendance(user);
  }

  bool canManageLists(UserRole? user) => _base.canManageMediaFirestore(user);

  bool canGenerateAuto(UserRole? user) {
    if (!canManageLists(user)) return false;
    return user!.hasPermission(canGenerateMediaAutoList) ||
        user.hasPermission(RolePermissionMatrix.canManageEverything) ||
        _base.isAdminGeneral(user);
  }

  bool canCreateManual(UserRole? user) {
    if (!canManageLists(user)) return false;
    return user!.hasPermission(canCreateMediaManualList) ||
        user.hasPermission(AppPermissions.canManageMediaLists) ||
        _base.isAdminGeneral(user);
  }

  bool canExport(UserRole? user) {
    if (user == null) return false;
    if (_base.canManageEverything(user)) return true;
    return user.hasPermission(RolePermissionMatrix.canExportPdf) ||
        user.hasPermission(RolePermissionMatrix.canExportCsv) ||
        user.hasPermission(RolePermissionMatrix.canExportMediaList) ||
        user.hasPermission(RolePermissionMatrix.canExportMemberList) ||
        user.hasPermission(RolePermissionMatrix.canExportAttendanceList) ||
        user.hasPermission(RolePermissionMatrix.canExportDepartmentList) ||
        user.hasPermission(canExportMediaPdf) ||
        user.hasPermission(canExportMediaCsv) ||
        user.hasPermission(AppPermissions.canExportMediaReports);
  }

  bool isMediaStaff(UserRole? user) {
    if (user == null) return false;
    return user.roles.any((r) =>
        AppConstants.adminRoles.contains(r) ||
        r.contains('media') ||
        r.contains('attendance'));
  }
}
