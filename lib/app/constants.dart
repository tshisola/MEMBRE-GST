/// Constantes globales — MEDIA LUBUMBASHI (organisation IFCM conservée en interne).
class AppConstants {
  AppConstants._();

  /// Nom visible de l'application partout (UI, Android, exports titre).
  static const String appName = 'MEDIA LUBUMBASHI';
  static const String appFullName = 'MEDIA LUBUMBASHI';

  /// Organisation officielle (listes PDF/CSV, mentions légales).
  static const String organizationFullName = 'IMPACT FOR CHRIST MINISTRIES';
  static const String organizationLegalLine =
      'Impact For Christ Ministries Lubumbashi';

  static const String city = 'Lubumbashi';
  static const String country = 'RDC';
  static const String mediaDepartmentId = 'media';

  // SQLite table names
  static const String tableMembers = 'members';
  static const String tableMediaAttendance = 'media_attendance';
  static const String tableMediaLists = 'media_lists';
  static const String tableMediaRoles = 'media_roles';
  static const String tableMemberAccounts = 'member_accounts';
  static const String tableMemberLoginCredentials = 'member_login_credentials';
  static const String tableMemberPasswordResetLogs = 'member_password_reset_logs';
  static const String tableMemberAccountSecurity = 'member_account_security';
  static const String tableDepartmentManualLists = 'department_manual_lists';
  static const String tableDepartmentManualListEntries =
      'department_manual_list_entries';
  static const String tableAuditLogs = 'audit_logs';
  static const String tableOfflineActionQueue = 'offline_action_queue';
  static const String tableOfflineSyncQueue = 'offline_sync_queue';
  static const String tableMemberQrCodes = 'member_qr_codes';
  static const String tableSyncConflicts = 'sync_conflicts';
  static const String tableDeletedMembers = 'deleted_members';
  static const String tableMemberDeleteRequests = 'member_delete_requests';
  static const String tableMemberRestoreLogs = 'member_restore_logs';
  static const String tableAppNotifications = 'app_notifications';
  static const String tableApprovalRequests = 'approval_requests';
  static const String tableSmartActionHistory = 'smart_action_history';

  // Firestore collection names
  static const String collectionMembers = 'members';
  static const String collectionMediaAttendance = 'media_attendance';
  static const String collectionMediaLists = 'media_lists';
  static const String collectionMediaRoles = 'media_roles';
  static const String collectionDepartments = 'departments';
  static const String collectionUsers = 'users';
  static const String collectionSyncQueue = 'sync_queue';
  static const String collectionMemberAccounts = 'memberAccounts';
  static const String collectionMemberLoginProfiles = 'memberLoginProfiles';
  static const String collectionPasswordResetLogs = 'passwordResetLogs';
  static const String collectionAccountSecurityLogs = 'accountSecurityLogs';
  static const String collectionDepartmentManualLists = 'departmentManualLists';
  static const String collectionAuditLogs = 'audit_logs';
  static const String collectionMemberQrCodes = 'memberQrCodes';
  static const String collectionWeeklyResults = 'weekly_results';
  static const String collectionSyncLogs = 'syncLogs';
  static const String collectionMessages = 'messages';
  static const String collectionConversations = 'conversations';
  static const String collectionAppointments = 'appointments';
  static const String collectionAiChatHistory = 'aiChatHistory';
  static const String collectionAdminRecoveryLogs = 'adminRecoveryLogs';
  static const String collectionRoles = 'roles';
  static const String collectionPermissions = 'permissions';

  // Remote / online config collections
  static const String collectionAppConfig = 'app_config';
  static const String collectionUiConfig = 'ui_config';
  static const String collectionFeatureFlags = 'feature_flags';
  static const String collectionRemoteTexts = 'remote_texts';
  static const String collectionRemoteTheme = 'remote_theme';
  static const String collectionRemoteMenus = 'remote_menus';
  static const String collectionRemoteDashboards = 'remote_dashboards';
  static const String collectionRemotePermissions = 'remote_permissions';
  static const String collectionRemoteAttendanceRules = 'remote_attendance_rules';
  static const String collectionRemotePdfTemplates = 'remote_pdf_templates';
  static const String collectionRemoteScreens = 'remote_screens';
  static const String collectionRemoteComponents = 'remote_components';
  static const String collectionRemoteActions = 'remote_actions';
  static const String collectionRemoteLayouts = 'remote_layouts';
  static const String collectionAppVersions = 'app_versions';
  static const String collectionRoleConfig = 'role_config';

  // Offline sync queue statuses
  static const String queueStatusPending = 'pending';
  static const String queueStatusSyncing = 'syncing';
  static const String queueStatusSynced = 'synced';
  static const String queueStatusFailed = 'failed';
  static const String queueStatusConflict = 'conflict';

  // Offline sync action types
  static const String syncActionCreateMember = 'create_member';
  static const String syncActionUpdateMember = 'update_member';
  static const String syncActionCreateMemberAccount = 'create_member_account';
  static const String syncActionUpdateAttendance = 'update_attendance';
  static const String syncActionSendMessage = 'send_message';
  static const String syncActionCreateDepartmentList = 'create_department_list';
  static const String syncActionDeleteDepartmentList = 'delete_department_list';
  static const String syncActionAssignRole = 'assign_role';
  static const String syncActionDeleteMember = 'delete_member';
  static const String syncActionRestoreMember = 'restore_member';
  static const String syncActionDeactivateMember = 'deactivate_member';

  static const String collectionDeletedMembers = 'deletedMembers';
  static const String collectionMemberDeleteRequests = 'memberDeleteRequests';

  static const int syncMaxRetries = 3;

  // Member sync status
  static const String syncStatusLocal = 'local';
  static const String syncStatusPending = 'pending';
  static const String syncStatusSyncing = 'syncing';
  static const String syncStatusSynced = 'synced';
  static const String syncStatusError = 'error';
  static const String syncStatusConflict = 'conflict';

  static const String memberCodePrefix = 'IFCM-LUB';

  // Shared preferences keys
  static const String prefSessionUserId = 'session_user_id';
  static const String prefSessionEmail = 'session_email';
  static const String prefSessionRole = 'session_role';
  static const String prefSessionDepartment = 'session_department';
  static const String prefIsMediaAttendanceOperator =
      'is_media_attendance_operator';
  static const String prefSessionAccountType = 'session_account_type';
  static const String prefSessionMustChangePassword =
      'session_must_change_password';
  static const String prefSessionMemberId = 'session_member_id';
  static const String prefRememberMe = 'remember_me';
  static const String prefLastLoginIdentifier = 'last_login_identifier';
  static const String prefCachedConfigVersion = 'cached_config_version';
  static const String prefCachedWebVersion = 'cached_web_version';

  // Roles — admin / responsables
  static const String roleAdminGeneralOwner = 'admin_general_owner';
  static const String roleAdminGeneral = 'admin_general';
  static const String roleAdminSimple = 'admin_simple';
  static const String roleAdmin = 'admin';
  static const String rolePasteur = 'pasteur';
  static const String roleDisciple = 'disciple';
  static const String roleDepartmentChief = 'department_chief';
  static const String roleLeader = 'leader';
  static const String roleAttendanceOperator = 'attendance_operator';
  static const String roleMediaLead = 'media_lead';
  static const String roleMediaOperator = 'media_operator';
  static const String roleMember = 'member';
  static const String roleMediaMember = 'media_member';

  // Google Media activation
  static const String activationStatusPending = 'pending_activation';
  static const String activationStatusActive = 'active';
  static const String activationStatusRejected = 'rejected';
  static const String activationStatusSuspended = 'suspended';
  static const String activationStatusDisabled = 'disabled';

  static const String authProviderGoogle = 'google';
  static const String requestedRoleMediaMember = 'media_member';
  static const String departmentNameMedia = 'Media';

  static const String tableMediaGoogleActivationRequests =
      'media_google_activation_requests';
  static const String tableMediaMembers = 'media_members';
  static const String tableActivationLogs = 'activation_logs';
  static const String tableAdminStaffAccounts = 'admin_staff_accounts';

  /// Identifiants staff principaux (seed local — jamais affichés aux membres).
  static const String staffLoginVerdick = 'verdick';
  static const String staffLoginJeno = 'jeno';
  static const String staffLoginMechack = 'mechack';
  static const String staffLoginBisibo = 'bisibo';
  static const String staffLoginAlex = 'alex';
  static const String staffEmailVerdick = 'verdicky9@gmail.com';
  static const String staffOwnerPrimaryEmail = 'verdicky9@gmail.com';
  static const String staffOwnerDisplayName = 'Verdick Yav';
  static const String staffEmailJeno = 'jeno@medialubumbashi.app';
  static const String staffEmailMechack = 'mechack@gmail.com';
  static const String staffEmailBisibo = 'bisibo@gmail.com';
  static const String staffEmailAlex = 'alex@gmail.com';
  static const String staffFirebaseEmailDomain = 'medialubumbashi.app';

  static const String prefStaffFirebaseProvisioned = 'staff_firebase_provisioned_v1';

  /// Provisioning staff via SDK client uniquement (plan Spark gratuit).
  static const bool staffProvisioningUsesCloudFunctions = false;

  static const String collectionMediaActivationRequests =
      'media_member_activation_requests';
  static const String collectionMediaMembers = 'mediaMembers';

  static const String prefFirebaseUid = 'session_firebase_uid';
  static const String prefGooglePhotoUrl = 'session_google_photo_url';
  static const String prefGoogleDisplayName = 'session_google_display_name';
  static const String prefActivationStatus = 'session_activation_status';
  static const String prefAuthProvider = 'session_auth_provider';
  static const String prefSessionPermissions = 'session_permissions';
  static const String permissionMergeDuplicates = 'merge_duplicates';
  static const String prefSessionDisplayName = 'session_display_name';
  static const String prefSessionIsOwner = 'session_is_owner';
  static const String prefStaffSeedCompleted = 'staff_seed_completed_v1';

  static const String syncActionMediaActivation = 'media_activation_sync';

  static const List<String> adminRoles = [
    roleAdminGeneralOwner,
    roleAdminGeneral,
    roleAdminSimple,
    roleAdmin,
    rolePasteur,
    roleDisciple,
    roleDepartmentChief,
    roleLeader,
    roleAttendanceOperator,
    roleMediaLead,
    roleMediaOperator,
  ];

  static const String accountTypeAdmin = 'admin';
  static const String accountTypeMember = 'member';

  static const String databaseName = 'ifcm_lubumbashi.db';
  static const int databaseVersion = 10;
  static const String tableMigrationHistory = 'migration_history';

  static const String securityLoginMessage =
      'Pour votre sécurité, tapez vos identifiants manuellement.';
}
