import '../../app/constants.dart';
import '../security/role_permission_matrix.dart';

/// Emails et mots de passe seed staff — provisioning Firebase Auth uniquement.
class StaffSeedCredentials {
  StaffSeedCredentials._();

  static const firebaseEmailDomain = 'medialubumbashi.app';

  static const _primaryEmails = {
    AppConstants.staffLoginVerdick: AppConstants.staffOwnerPrimaryEmail,
    AppConstants.staffLoginMechack: AppConstants.staffEmailMechack,
    AppConstants.staffLoginBisibo: AppConstants.staffEmailBisibo,
    AppConstants.staffLoginAlex: AppConstants.staffEmailAlex,
  };

  /// Email Firebase / connexion pour un login staff.
  static String resolvedEmail(String login) {
    final key = login.trim().toLowerCase();
    return _primaryEmails[key] ?? '${key}@$firebaseEmailDomain';
  }

  static String firebaseEmail(String login) => resolvedEmail(login);

  static String? seedPassword(String login) {
    switch (login.trim().toLowerCase()) {
      case AppConstants.staffLoginVerdick:
        return 'Verd@2026';
      case AppConstants.staffLoginJeno:
        return 'Jeno@2026';
      case AppConstants.staffLoginMechack:
        return 'Mechack@2026';
      case AppConstants.staffLoginBisibo:
        return 'Bisibo@2026';
      case AppConstants.staffLoginAlex:
        return 'Alex@2026';
      default:
        return null;
    }
  }

  static List<StaffSeedEntry> allEntries() => [
        StaffSeedEntry(
          login: AppConstants.staffLoginVerdick,
          displayName: AppConstants.staffOwnerDisplayName,
          role: AppConstants.roleAdminGeneralOwner,
          isOwner: true,
          permissions: RolePermissionMatrix.permissionsForRole(
            AppConstants.roleAdminGeneralOwner,
          ),
        ),
        StaffSeedEntry(
          login: AppConstants.staffLoginJeno,
          displayName: 'Jeno',
          role: AppConstants.roleAdminGeneral,
          permissions: RolePermissionMatrix.permissionsForRole(
            AppConstants.roleAdminGeneral,
          ),
        ),
        StaffSeedEntry(
          login: AppConstants.staffLoginAlex,
          displayName: 'Alex',
          role: AppConstants.roleAdminSimple,
          permissions: RolePermissionMatrix.permissionsForRole(
            AppConstants.roleAdminSimple,
          ),
        ),
        StaffSeedEntry(
          login: AppConstants.staffLoginMechack,
          displayName: 'Mechack',
          role: AppConstants.roleAttendanceOperator,
          departmentId: AppConstants.mediaDepartmentId,
          permissions: RolePermissionMatrix.permissionsForRole(
            AppConstants.roleAttendanceOperator,
          ),
        ),
        StaffSeedEntry(
          login: AppConstants.staffLoginBisibo,
          displayName: 'Bisibo',
          role: AppConstants.roleAttendanceOperator,
          departmentId: AppConstants.mediaDepartmentId,
          permissions: RolePermissionMatrix.permissionsForRole(
            AppConstants.roleAttendanceOperator,
          ),
        ),
      ];
}

class StaffSeedEntry {
  const StaffSeedEntry({
    required this.login,
    required this.displayName,
    required this.role,
    this.isOwner = false,
    this.departmentId,
    this.permissions = const [],
  });

  final String login;
  final String displayName;
  final String role;
  final bool isOwner;
  final String? departmentId;
  final List<String> permissions;

  String get email => StaffSeedCredentials.resolvedEmail(login);

  String? get password => StaffSeedCredentials.seedPassword(login);
}
