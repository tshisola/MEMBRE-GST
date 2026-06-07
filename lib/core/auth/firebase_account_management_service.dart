import 'package:cloud_functions/cloud_functions.dart';

import '../../app/constants.dart';
import 'admin_recovery_cloud_service.dart';
import '../firebase/firebase_initializer.dart';
import '../messaging/auth_error_sanitizer.dart';

/// Actions compte Firebase via Cloud Functions sécurisées.
class FirebaseAccountManagementService {
  FirebaseAccountManagementService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;
  final AdminRecoveryCloudService _recovery =
      AdminRecoveryCloudService();

  bool get isAvailable => FirebaseInitializer.isInitialized;

  Future<void> seedVerdickOwner({
    required String email,
    required String displayName,
  }) async {
    if (!AppConstants.staffProvisioningUsesCloudFunctions) return;
    await _recovery.seedOrResetVerdickOwner(email: email);
  }

  Future<void> resetVerdickPassword({bool sendEmail = false}) async {
    if (!AppConstants.staffProvisioningUsesCloudFunctions) return;
    await _recovery.resetVerdickPassword(sendEmail: sendEmail);
  }

  Future<void> createJenoAdminGeneral({required String email}) async {
    if (!AppConstants.staffProvisioningUsesCloudFunctions) return;
    await _recovery.createJenoAdminGeneral(email: email);
  }

  Future<void> resetUserPasswordSecure({
    required String uid,
    required String newPassword,
  }) async {
    if (!AppConstants.staffProvisioningUsesCloudFunctions) {
      await resetUserPassword(uid: uid, newPassword: newPassword);
      return;
    }
    await _recovery.resetUserPassword(uid: uid, newPassword: newPassword);
  }

  Future<void> resetUserPassword({
    required String uid,
    required String newPassword,
  }) async {
    if (!isAvailable) return;
    try {
      final callable = _functions.httpsCallable('resetMemberPasswordCallable');
      await callable.call({'uid': uid, 'newPassword': newPassword});
    } catch (e) {
      throw AuthErrorSanitizer.sanitize(e);
    }
  }

  Future<void> assignRole({
    required String uid,
    required String role,
  }) async {
    if (!isAvailable) return;
    try {
      final callable = _functions.httpsCallable('assignRoleCallable');
      await callable.call({'uid': uid, 'role': role});
    } catch (e) {
      throw AuthErrorSanitizer.sanitize(e);
    }
  }

  Future<void> disableAccount(String uid) async {
    if (!isAvailable) return;
    try {
      final callable = _functions.httpsCallable('deleteAccountCallable');
      await callable.call({'uid': uid});
    } catch (e) {
      throw AuthErrorSanitizer.sanitize(e);
    }
  }

  Future<void> enableAccount(String uid) async {
    if (!isAvailable) return;
    try {
      final callable = _functions.httpsCallable('restoreAccountCallable');
      await callable.call({'uid': uid});
    } catch (e) {
      throw AuthErrorSanitizer.sanitize(e);
    }
  }
}
