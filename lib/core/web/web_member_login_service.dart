import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../app/constants.dart';
import '../auth/member_auth_service.dart';
import '../auth/staff_seed_credentials.dart';
import '../firebase/firebase_auth_service.dart';
import '../firebase/firebase_initializer.dart';
import '../logging/technical_error_repository.dart';
import '../messaging/auth_error_sanitizer.dart';
import 'web_role_compatibility_service.dart';
import 'web_user_profile_repository.dart';

/// Connexion Membre Web — Firebase Auth + profil Firestore.
class WebMemberLoginService {
  WebMemberLoginService({
    FirebaseAuthService? firebaseAuth,
    WebUserProfileRepository? profiles,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuthService(),
        _profiles = profiles ?? WebUserProfileRepository();

  final FirebaseAuthService _firebaseAuth;
  final WebUserProfileRepository _profiles;

  Future<MemberAuthResult> authenticate({
    required String identifier,
    required String password,
  }) async {
    if (!kIsWeb) {
      return const MemberAuthResult(
        success: false,
        message: 'Connexion Web indisponible.',
      );
    }

    if (!FirebaseInitializer.isInitialized) {
      final init = await FirebaseInitializer.initialize();
      if (!init.success) {
        return const MemberAuthResult(
          success: false,
          message: 'Connexion en ligne requise.',
        );
      }
    }

    final normalized = identifier.trim();
    if (normalized.isEmpty || password.isEmpty) {
      return const MemberAuthResult(
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
        if (uid == null) continue;

        final profile = await _profiles.loadByUid(uid: uid, email: email);
        if (profile == null) {
          await _firebaseAuth.signOut();
          return const MemberAuthResult(
            success: false,
            message: 'Compte non autorisé.',
          );
        }

        if (AppConstants.adminRoles.contains(profile.role)) {
          await _firebaseAuth.signOut();
          return const MemberAuthResult(
            success: false,
            message: 'Utilisez la connexion responsable.',
          );
        }

        if (!profile.isActive) {
          return const MemberAuthResult(
            success: false,
            isDisabled: true,
            message: 'Compte désactivé. Contactez votre responsable.',
          );
        }

        if (!WebAccessGuard.allow(
          role: profile.role,
          permissions: profile.permissions,
        )) {
          return const MemberAuthResult(
            success: false,
            message: 'Accès non autorisé.',
          );
        }

        return MemberAuthResult(
          success: true,
          account: profile.toMemberAccount(),
        );
      } on FirebaseAuthException catch (e, st) {
        lastError = e;
        TechnicalErrorRepository.record(
          source: 'web_member_login',
          error: e,
          stack: st,
        );
        if (!_isCredentialError(e)) rethrow;
      } catch (e, st) {
        lastError = e;
        TechnicalErrorRepository.record(
          source: 'web_member_login',
          error: e,
          stack: st,
        );
      }
    }

    if (!normalized.contains('@')) {
      return const MemberAuthResult(
        success: false,
        message:
            'Identifiant ou mot de passe incorrect. Sur le Web, utilisez votre e-mail.',
      );
    }

    return MemberAuthResult(
      success: false,
      message: AuthErrorSanitizer.sanitize(lastError),
    );
  }

  List<String> _resolveEmails(String identifier) {
    final lower = identifier.toLowerCase();
    if (lower.contains('@')) return [lower];
    return [
      StaffSeedCredentials.resolvedEmail(lower),
      '$lower@${StaffSeedCredentials.firebaseEmailDomain}',
    ];
  }

  bool _isCredentialError(FirebaseAuthException e) {
    return e.code == 'wrong-password' ||
        e.code == 'invalid-credential' ||
        e.code == 'invalid-login-credentials' ||
        e.code == 'user-not-found';
  }
}
