import '../../app/constants.dart';
import '../../shared/models/role_models.dart';

/// Matrice rôle → permissions par défaut (exécutée côté app, jamais affichée).
class RolePermissionMatrix {
  RolePermissionMatrix._();

  static const canManageEverything = 'can_manage_everything';
  static const canCreateAdmin = 'can_create_admin';
  static const canAssignRoles = 'can_assign_roles';
  static const canRemoveRoles = 'can_remove_roles';
  static const canResetPasswords = 'can_reset_passwords';
  static const canCreateAccounts = 'can_create_accounts';
  static const canCreateMember = 'can_create_member';
  static const canCreateMemberAccount = 'can_create_member_account';
  static const canActivateAccounts = 'can_activate_accounts';
  static const canSuspendAccounts = 'can_suspend_accounts';
  static const canTakeAttendance = AppPermissions.canTakeAttendance;
  static const canScanQr = 'can_scan_qr';
  static const canManageDepartments = 'can_manage_departments';
  static const canManageDepartmentLists = 'can_manage_department_lists';
  static const canManageLists = 'can_manage_lists';
  static const canViewAuditLogs = 'can_view_audit_logs';
  static const canViewDiagnostics = 'can_view_diagnostics';
  static const canForceSync = 'can_force_sync';
  static const canManageFirebaseFromApp = 'can_manage_firebase_from_app';
  static const canDeleteMember = AppPermissions.canDeleteMember;
  static const canRestoreMember = 'can_restore_member';
  static const canResetMemberPasswords = 'can_reset_member_passwords';
  static const canManageMembers = 'can_manage_members';
  static const canManageMediaLists = 'can_manage_media_lists';
  static const canViewSync = 'can_view_sync';
  static const canRemoveOwner = 'can_remove_owner';
  static const canManageAiAssistant = 'can_manage_ai_assistant';
  static const canManageMessaging = 'can_manage_messaging';
  static const canManageAppointments = 'can_manage_appointments';
  static const canAccessWebAdmin = 'can_access_web_admin';
  static const canAccessWeb = 'can_access_web';

  // Visibilité membres — tous les Admins autorisés
  static const canReadAllMembers = 'can_read_all_members';
  static const canReadMembersForAttendance = 'can_read_members_for_attendance';
  static const canViewMemberList = 'can_view_member_list';
  static const canSearchMembers = 'can_search_members';
  static const canViewMemberDetail = 'can_view_member_detail';
  static const canViewAttendanceDashboard = 'can_view_attendance_dashboard';
  static const canCreateAttendanceRecord = 'can_create_attendance_record';

  // Export listes
  static const canExportPdf = 'can_export_pdf';
  static const canExportCsv = 'can_export_csv';
  static const canExportMemberList = 'can_export_member_list';
  static const canExportAttendanceList = 'can_export_attendance_list';
  static const canExportMediaList = 'can_export_media_list';
  static const canExportDepartmentList = 'can_export_department_list';

  static const _ownerPermissions = [
    canManageEverything,
    canCreateAdmin,
    canAssignRoles,
    canRemoveRoles,
    canResetPasswords,
    canCreateAccounts,
    canCreateMember,
    canCreateMemberAccount,
    canActivateAccounts,
    canSuspendAccounts,
    canTakeAttendance,
    canScanQr,
    canManageDepartments,
    canManageDepartmentLists,
    canManageLists,
    canViewAuditLogs,
    canViewDiagnostics,
    canForceSync,
    canManageFirebaseFromApp,
    canDeleteMember,
    canRestoreMember,
    canManageAiAssistant,
    canManageMessaging,
    canManageAppointments,
    canAccessWebAdmin,
    canAccessWeb,
    canReadAllMembers,
    canReadMembersForAttendance,
    canViewMemberList,
    canSearchMembers,
    canViewMemberDetail,
    canViewAttendanceDashboard,
    canCreateAttendanceRecord,
    canExportPdf,
    canExportCsv,
    canExportMemberList,
    canExportAttendanceList,
    canExportMediaList,
    canExportDepartmentList,
    AppPermissions.canManageMediaRoles,
    AppPermissions.canManageMediaLists,
    AppPermissions.canExportMediaReports,
  ];

  static const _adminGeneralPermissions = [
    canAssignRoles,
    canResetPasswords,
    canResetMemberPasswords,
    canCreateAccounts,
    canCreateMember,
    canCreateMemberAccount,
    canManageMembers,
    canManageLists,
    canActivateAccounts,
    canSuspendAccounts,
    canTakeAttendance,
    canScanQr,
    canManageDepartments,
    canManageDepartmentLists,
    canViewAuditLogs,
    canViewSync,
    canForceSync,
    canManageFirebaseFromApp,
    canRestoreMember,
    canManageMessaging,
    canManageAppointments,
    canAccessWebAdmin,
    canAccessWeb,
    canReadAllMembers,
    canReadMembersForAttendance,
    canViewMemberList,
    canSearchMembers,
    canViewMemberDetail,
    canViewAttendanceDashboard,
    canCreateAttendanceRecord,
    canExportPdf,
    canExportCsv,
    canExportMemberList,
    canExportMediaList,
    canExportDepartmentList,
    AppPermissions.canManageMediaRoles,
    AppPermissions.canManageMediaLists,
  ];

  static const _adminSimplePermissions = [
    canCreateMember,
    canCreateMemberAccount,
    canManageMembers,
    canManageLists,
    canTakeAttendance,
    canScanQr,
    canManageMessaging,
    canAccessWebAdmin,
    canAccessWeb,
    canReadAllMembers,
    canViewMemberList,
    canSearchMembers,
    canViewMemberDetail,
    canExportPdf,
    canExportCsv,
    canExportMemberList,
    'can_view_media_lists',
  ];

  static const _attendanceOperatorPermissions = [
    canTakeAttendance,
    canScanQr,
    canAccessWeb,
    canReadMembersForAttendance,
    canSearchMembers,
    canViewMemberDetail,
    canViewAttendanceDashboard,
    canCreateAttendanceRecord,
    'can_view_media_lists',
    AppPermissions.canTakeAttendance,
  ];

  static List<String> permissionsForRole(String role) {
    switch (role) {
      case AppConstants.roleAdminGeneralOwner:
        return List<String>.from(_ownerPermissions);
      case AppConstants.roleAdminGeneral:
        return List<String>.from(_adminGeneralPermissions);
      case AppConstants.roleAdminSimple:
        return List<String>.from(_adminSimplePermissions);
      case AppConstants.roleAttendanceOperator:
        return List<String>.from(_attendanceOperatorPermissions);
      default:
        return const [];
    }
  }

  static bool roleHasPermission(String role, String permission) {
    return permissionsForRole(role).contains(permission);
  }

  static bool onlyOwnerCanDelete() => false;
}
