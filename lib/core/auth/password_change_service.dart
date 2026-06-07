import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../app/constants.dart';
import '../../shared/models/admin_staff_account_model.dart';
import '../../shared/models/member_account_model.dart';
import '../firebase/firebase_initializer.dart';
import '../logging/technical_error_repository.dart';
import '../messaging/auth_error_sanitizer.dart';
import 'auth_session_refresh_service.dart';
import 'local_admin_auth_service.dart';
import 'member_password_change_service.dart';
import 'password_change_cloud_service.dart';
import 'staff_seed_credentials.dart';

/// Changement mot de passe unifié — Firebase Auth source officielle + SQLite local.
class PasswordChangeService {
  PasswordChangeService({
    LocalAdminAuthService? staffAuth,
    PasswordChangeCloudService? cloud,
    AuthSessionRefreshService? sessionRefresh,
  })  : _staff = staffAuth ?? LocalAdminAuthService(),
        _cloud = cloud ?? PasswordChangeCloudService(),
        _sessionRefresh = sessionRefresh ?? AuthSessionRefreshService();

  final LocalAdminAuthService _staff;
  final PasswordChangeCloudService _cloud;
  final AuthSessionRefreshService _sessionRefresh;

  String? validate({
    required String newPassword,
    required String confirmPassword,
  }) {
    if (newPassword != confirmPassword) {
      return 'Les mots de passe ne correspondent pas.';
    }
    final strength = PasswordStrength.evaluate(newPassword);
    if (!strength.isValid) return strength.message;
    return null;
  }

  Future<String?> changeStaffPassword({
    required String accountId,
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final err = validate(newPassword: newPassword, confirmPassword: confirmPassword);
    if (err != null) return err;

    if (kIsWeb) {
      return _changeViaFirebaseOnly(
        email: await _resolveStaffEmail(accountId),
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
    }

    try {
      await _staff.changePassword(
        accountId: accountId,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
    } catch (_) {
      return 'Mot de passe actuel incorrect.';
    }

    final email = await _resolveStaffEmail(accountId);
    final syncErr = await _syncToFirebaseAuth(
      email: email,
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
    return syncErr;
  }

  Future<String?> changeMemberPassword({
    required MemberAccount account,
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final err = validate(newPassword: newPassword, confirmPassword: confirmPassword);
    if (err != null) return err;

    if (kIsWeb) {
      final email = _resolveMemberEmail(account);
      if (email == null) return 'Compte invalide.';
      return _changeViaFirebaseOnly(
        email: email,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
    }

    final localErr = await MemberPasswordChangeService().changePassword(
      accountId: account.id,
      oldPassword: oldPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
    if (localErr != null) return localErr;

    final email = _resolveMemberEmail(account);
    if (email == null) return null;

    return _syncToFirebaseAuth(
      email: email,
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }

  Future<String?> _changeViaFirebaseOnly({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    if (!FirebaseInitializer.isInitialized) {
      return 'Connexion en ligne requise.';
    }
    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;
      if (user == null || user.email?.toLowerCase() != email.toLowerCase()) {
        await auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: oldPassword,
        );
      } else {
        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(
            email: email.trim(),
            password: oldPassword,
          ),
        );
      }

      final result = await _cloud.changePassword(newPassword: newPassword);
      if (!result.success) {
        await _updatePasswordClientFallback(newPassword: newPassword);
      }
      await _sessionRefresh.refreshAfterPasswordChange();
      return null;
    } catch (e, st) {
      TechnicalErrorRepository.record(
        source: 'password_change_web',
        error: e,
        stack: st,
      );
      return AuthErrorSanitizer.sanitize(e);
    }
  }

  Future<String?> _syncToFirebaseAuth({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    if (!FirebaseInitializer.isInitialized) return null;

    try {
      final auth = FirebaseAuth.instance;
      var user = auth.currentUser;

      if (user == null || user.email?.toLowerCase() != email.toLowerCase()) {
        await auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: oldPassword,
        );
        user = auth.currentUser;
      } else {
        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(
            email: email.trim(),
            password: oldPassword,
          ),
        );
      }

      final result = await _cloud.changePassword(newPassword: newPassword);
      if (result.success) {
        await _sessionRefresh.refreshAfterPasswordChange();
        return null;
      }
      await _updatePasswordClientFallback(newPassword: newPassword);
      await _sessionRefresh.refreshAfterPasswordChange();
      return null;
    } catch (e, st) {
      TechnicalErrorRepository.record(
        source: 'password_change_sync',
        error: e,
        stack: st,
      );
      return null;
    }
  }

  Future<void> _updatePasswordClientFallback({
    required String newPassword,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await user.updatePassword(newPassword);
    if (!FirebaseInitializer.isInitialized) return;
    await FirebaseFirestore.instance
        .collection(AppConstants.collectionUsers)
        .doc(user.uid)
        .set(
      {
        'mustChangePassword': false,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      SetOptions(merge: true),
    );
  }

  Future<String> _resolveStaffEmail(String accountId) async {
    final staff = await _staff.listStaff();
    AdminStaffAccount? account;
    for (final s in staff) {
      if (s.id == accountId) {
        account = s;
        break;
      }
    }
    if (account == null) {
      return StaffSeedCredentials.resolvedEmail('');
    }
    return account.email?.trim().isNotEmpty == true
        ? account.email!.trim()
        : StaffSeedCredentials.resolvedEmail(account.loginIdentifier);
  }

  String? _resolveMemberEmail(MemberAccount account) {
    if (account.email?.trim().isNotEmpty == true) {
      return account.email!.trim();
    }
    if (account.loginIdentifier.contains('@')) {
      return account.loginIdentifier.trim();
    }
    return null;
  }
}

/// Alias Web demandé.
typedef WebPasswordChangeService = PasswordChangeService;

/// Garde changement mot de passe obligatoire.
class MustChangePasswordGuard {
  const MustChangePasswordGuard();

  String? routeIfRequired({required bool mustChangePassword}) {
    if (!mustChangePassword) return null;
    return '/auth/change-password';
  }
}
