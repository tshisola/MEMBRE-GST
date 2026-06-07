import '../../app/constants.dart';
import 'staff_seed_credentials.dart';
import 'local_admin_auth_service.dart';
/// Seed initial des comptes staff — ne recrée jamais un compte existant.
class AdminOwnerSeedService {
  AdminOwnerSeedService({LocalAdminAuthService? auth})
      : _auth = auth ?? LocalAdminAuthService();

  final LocalAdminAuthService _auth;

  /// Retourne les mots de passe créés (affichage unique) pour les nouveaux comptes.
  Future<Map<String, String>> seedIfMissing() async {
    final created = <String, String>{};

    created.addAll(await _createIfMissing(
      login: AppConstants.staffLoginVerdick,
      name: AppConstants.staffOwnerDisplayName,
      role: AppConstants.roleAdminGeneralOwner,
      email: StaffSeedCredentials.resolvedEmail(AppConstants.staffLoginVerdick),
      password: StaffSeedCredentials.seedPassword(AppConstants.staffLoginVerdick)!,
      isOwner: true,
    ));

    created.addAll(await _createIfMissing(
      login: AppConstants.staffLoginJeno,
      name: 'Jeno',
      role: AppConstants.roleAdminGeneral,
      email: StaffSeedCredentials.firebaseEmail(AppConstants.staffLoginJeno),
      password: StaffSeedCredentials.seedPassword(AppConstants.staffLoginJeno)!,
    ));

    created.addAll(await _createIfMissing(
      login: AppConstants.staffLoginAlex,
      name: 'Alex',
      role: AppConstants.roleAdminSimple,
      email: StaffSeedCredentials.resolvedEmail(AppConstants.staffLoginAlex),
      password: StaffSeedCredentials.seedPassword(AppConstants.staffLoginAlex)!,
    ));

    created.addAll(await _createIfMissing(
      login: AppConstants.staffLoginMechack,
      name: 'Mechack',
      role: AppConstants.roleAttendanceOperator,
      email: StaffSeedCredentials.firebaseEmail(AppConstants.staffLoginMechack),
      password: StaffSeedCredentials.seedPassword(AppConstants.staffLoginMechack)!,
    ));

    created.addAll(await _createIfMissing(
      login: AppConstants.staffLoginBisibo,
      name: 'Bisibo',
      role: AppConstants.roleAttendanceOperator,
      email: StaffSeedCredentials.firebaseEmail(AppConstants.staffLoginBisibo),
      password: StaffSeedCredentials.seedPassword(AppConstants.staffLoginBisibo)!,
    ));

    await _auth.ensureStaffFirebaseEmails();
    return created;
  }

  Future<Map<String, String>> _createIfMissing({
    required String login,
    required String name,
    required String role,
    required String password,
    String? email,
    bool isOwner = false,
  }) async {
    final before = await _auth.findByLogin(login);
    if (before != null) return const {};

    await _auth.upsertStaff(
      loginIdentifier: login,
      displayName: name,
      role: role,
      email: email,
      plainPassword: password,
      isOwner: isOwner,
      mustChangePassword: true,
      skipIfExists: false,
    );
    return {name: password};
  }
}
