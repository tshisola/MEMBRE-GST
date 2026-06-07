import '../../shared/models/role_models.dart';

/// Media-specific attendance and role permission checks (Lubumbashi).
class MediaAttendancePermissionService {
  const MediaAttendancePermissionService();

  bool canTakeAttendance(UserRole? user) {
    if (user == null) return false;
    return user.canTakeAttendance;
  }

  bool canManageMediaRoles(UserRole? user) {
    if (user == null) return false;
    return user.canManageMediaRoles;
  }

  bool canOpenAttendanceSession(UserRole? user) {
    return canTakeAttendance(user) || _isMediaChef(user);
  }

  bool canCloseAttendanceSession(UserRole? user) {
    return canManageMediaRoles(user);
  }

  bool canEditAttendanceRecord(UserRole? user, {String? recordedBy}) {
    if (user == null) return false;
    if (user.isAdminGeneral || _isMediaChef(user)) return true;
    if (canTakeAttendance(user)) {
      return recordedBy == null || recordedBy == user.uid;
    }
    return false;
  }

  bool canDeleteAttendanceRecord(UserRole? user) {
    if (user == null) return false;
    return user.isAdminGeneral || _isMediaChef(user);
  }

  bool canExportAttendance(UserRole? user) {
    if (user == null) return false;
    return user.hasPermission(AppPermissions.canExportMediaReports) ||
        canManageMediaRoles(user) ||
        canTakeAttendance(user);
  }

  bool _isMediaChef(UserRole? user) =>
      user != null &&
      (user.mediaRole == MediaRole.chefMedia ||
          (user.isDepartmentChief && user.departmentId == 'media'));
}
