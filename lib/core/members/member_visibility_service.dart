import '../../app/constants.dart';
import '../security/role_permission_matrix.dart';
import '../storage/local_session.dart';

/// Détermine qui peut lire / synchroniser tous les membres actifs.
class MemberVisibilityService {
  MemberVisibilityService._();

  static const canReadAllMembers = 'can_read_all_members';
  static const canReadMembersForAttendance = 'can_read_members_for_attendance';
  static const canViewMemberList = 'can_view_member_list';
  static const canSearchMembers = 'can_search_members';
  static const canViewMemberDetail = 'can_view_member_detail';
  static const canViewAttendanceDashboard = 'can_view_attendance_dashboard';

  static bool shouldSyncAllMembers(LocalSession session) {
    if (!session.isLoggedIn) return false;
    if (session.isAdminAccount) return true;
    if (session.isMediaAttendanceOperator) return true;
    if (session.role == AppConstants.roleAttendanceOperator) return true;
    return session.hasPermission(canReadAllMembers) ||
        session.hasPermission(canReadMembersForAttendance) ||
        session.hasPermission(canViewMemberList);
  }

  static bool canReceiveMemberRealtime(LocalSession session) =>
      shouldSyncAllMembers(session);

  static bool canReadAllMembersForRole(String? role, List<String> permissions) {
    if (role == AppConstants.roleAdminGeneralOwner) return true;
    if (role == AppConstants.roleAdminGeneral) return true;
    if (role == AppConstants.roleAdminSimple) {
      return permissions.contains(canReadAllMembers) ||
          permissions.contains(RolePermissionMatrix.canCreateMember) ||
          permissions.contains(canViewMemberList);
    }
    if (role == AppConstants.roleAttendanceOperator) {
      return permissions.contains(canReadMembersForAttendance) ||
          permissions.contains(RolePermissionMatrix.canTakeAttendance);
    }
    return permissions.contains(canReadAllMembers);
  }

  static bool canReadForAttendance(String? role, List<String> permissions) {
    if (canReadAllMembersForRole(role, permissions)) return true;
    return role == AppConstants.roleAttendanceOperator ||
        permissions.contains(canReadMembersForAttendance) ||
        permissions.contains(RolePermissionMatrix.canTakeAttendance) ||
        permissions.contains(RolePermissionMatrix.canScanQr);
  }

  static bool shouldHideSensitiveFields(String? role) {
    return role == AppConstants.roleAttendanceOperator;
  }
}

/// Alias demandés par la spec.
typedef AdminMembersRepository = MemberVisibilityService;
typedef MembersRealtimeRepository = MemberVisibilityService;
typedef FirebaseMembersRepository = MemberVisibilityService;
typedef LocalMembersRepository = MemberVisibilityService;
typedef AdminMemberListController = MemberVisibilityService;
typedef PointageMemberLoader = MemberVisibilityService;
