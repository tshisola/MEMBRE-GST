import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../app/constants.dart';
import '../../shared/models/admin_staff_account_model.dart';
import '../auth/local_admin_auth_service.dart';
import '../auth/staff_seed_credentials.dart';
import '../firebase/firebase_auth_service.dart';
import '../firebase/firebase_initializer.dart';
import '../logging/technical_error_repository.dart';
import '../messaging/auth_error_sanitizer.dart';
import '../security/role_permission_matrix.dart';
import 'web_role_compatibility_service.dart';
import 'web_user_profile_repository.dart';

/// Connexion Admin Web — Firebase Auth + profil Firestore (sans SQLite).
class WebAdminLoginService {
  WebAdminLoginService({
    FirebaseAuthService? firebaseAuth,
    WebUserProfileRepository? profiles,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuthService(),
        _profiles = profiles ?? WebUserProfileRepository();

  final FirebaseAuthService _firebaseAuth;
  final WebUserProfileRepository _profiles;

  Future<AdminAuthResult> authenticate({
    required String identifier,
    required String password,
  }) async {
    if (!kIsWeb) {
      return const AdminAuthResult(
        success: false,
        message: 'Connexion Web indisponible.',
      );
    }

    if (!FirebaseInitializer.isInitialized) {
      final init = await FirebaseInitializer.initialize();
      if (!init.success) {
        return const AdminAuthResult(
          success: false,
          message: 'Connexion en ligne requise.',
        );
      }
    }

    final normalized = identifier.trim().toLowerCase();
    if (normalized.isEmpty || password.isEmpty) {
      return const AdminAuthResult(
        success: false,
        message: 'Identifiant et mot de passe requis.',
      );
    }

    final emails = _resolveEmails(normalized);
    Object? lastError;

    for (final email in emails) {
      try {
        await _firebaseAuth.signInWithEmail(email: email, password: password);
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) {
          return const AdminAuthResult(
            success: false,
            message: 'Connexion impossible. Vérifiez vos identifiants.',
          );
        }

        var account = await _loadStaffAccount(uid: uid, email: email);
        if (account == null) {
          await _firebaseAuth.signOut();
          return const AdminAuthResult(
            success: false,
            message: 'Compte non autorisé.',
          );
        }

        if (!account.isActive) {
          return const AdminAuthResult(
            success: false,
            isDisabled: true,
            message: 'Compte désactivé. Contactez le responsable principal.',
          );
        }

        if (account.isLocked) {
          return const AdminAuthResult(
            success: false,
            isLocked: true,
            message: 'Compte verrouillé. Utilisez la récupération responsable.',
          );
        }

        if (!AppConstants.adminRoles.contains(account.role)) {
          return const AdminAuthResult(
            success: false,
            message: 'Accès non autorisé.',
          );
        }

        if (!WebAccessGuard.allow(
          role: account.role,
          permissions: account.permissions,
        )) {
          return const AdminAuthResult(
            success: false,
            message: 'Accès non autorisé.',
          );
        }

        await _profiles.ensureStaffUserDoc(
          uid: uid,
          account: account,
          email: email,
        );

        account = AdminStaffAccount(
          id: account.id,
          loginIdentifier: account.loginIdentifier,
          displayName: account.displayName,
          role: account.role,
          email: account.email ?? email,
          permissions: account.permissions,
          isOwner: account.isOwner,
          isActive: account.isActive,
          isLocked: account.isLocked,
          mustChangePassword: account.mustChangePassword,
          firebaseUid: uid,
          city: account.city,
        );

        return AdminAuthResult(success: true, account: account);
      } on FirebaseAuthException catch (e, st) {
        lastError = e;
        TechnicalErrorRepository.record(
          source: 'web_admin_login',
          error: e,
          stack: st,
        );
        if (!_isCredentialError(e)) {
          return AdminAuthResult(
            success: false,
            message: AuthErrorSanitizer.sanitize(e),
          );
        }
      } catch (e, st) {
        lastError = e;
        TechnicalErrorRepository.record(
          source: 'web_admin_login',
          error: e,
          stack: st,
        );
        return AdminAuthResult(
          success: false,
          message: AuthErrorSanitizer.sanitize(e),
        );
      }
    }

    return AdminAuthResult(
      success: false,
      message: AuthErrorSanitizer.sanitize(lastError),
    );
  }

  List<String> _resolveEmails(String identifier) {
    if (identifier.contains('@')) return [identifier];
    return [
      StaffSeedCredentials.resolvedEmail(identifier),
      '$identifier@${StaffSeedCredentials.firebaseEmailDomain}',
    ];
  }

  bool _isCredentialError(FirebaseAuthException e) {
    return e.code == 'wrong-password' ||
        e.code == 'invalid-credential' ||
        e.code == 'invalid-login-credentials' ||
        e.code == 'user-not-found';
  }

  Future<AdminStaffAccount?> _loadStaffAccount({
    required String uid,
    required String email,
  }) async {
    final profile = await _profiles.loadByUid(uid: uid, email: email);
    if (profile == null || !profile.isStaff) return null;

    var account = profile.toStaffAccount();
    if (account.permissions.isEmpty) {
      account = AdminStaffAccount(
        id: account.id,
        loginIdentifier: account.loginIdentifier,
        displayName: account.displayName,
        role: account.role,
        email: account.email ?? email,
        permissions: RolePermissionMatrix.permissionsForRole(account.role),
        isOwner: account.isOwner,
        isActive: account.isActive,
        isLocked: account.isLocked,
        mustChangePassword: account.mustChangePassword,
        firebaseUid: uid,
        city: account.city,
      );
    }
    return account;
  }
}
