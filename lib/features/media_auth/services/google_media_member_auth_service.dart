import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../app/constants.dart';
import '../../../core/firebase/firebase_auth_service.dart';
import '../../../core/firebase/firebase_initializer.dart';
import '../../../core/logging/technical_error_repository.dart';
import '../../../core/messaging/user_facing_messages.dart';
import '../data/activation_idempotency_service.dart';
import '../data/activation_request_repository.dart';
import 'media_google_account_resolver.dart';

class GoogleSignInResult {
  const GoogleSignInResult({
    required this.success,
    this.route,
    this.userMessage,
    this.firebaseUid,
    this.request,
  });

  final bool success;
  final String? route;
  final String? userMessage;
  final String? firebaseUid;
  final dynamic request;
}

/// Connexion Google pour membre Média — demande ou dashboard selon statut.
class GoogleMediaMemberAuthService {
  GoogleMediaMemberAuthService({
    GoogleSignIn? googleSignIn,
    FirebaseAuthService? firebaseAuth,
    MediaGoogleAccountResolver? resolver,
    ActivationRequestRepository? requests,
  })  : _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: ['email']),
        _firebaseAuth = firebaseAuth ?? FirebaseAuthService(),
        _resolver = resolver ?? MediaGoogleAccountResolver(),
        _requests = requests ?? ActivationRequestRepository();

  final GoogleSignIn _googleSignIn;
  final FirebaseAuthService _firebaseAuth;
  final MediaGoogleAccountResolver _resolver;
  final ActivationRequestRepository _requests;

  Future<GoogleSignInResult> signInWithGoogle() async {
    try {
      if (!FirebaseInitializer.isInitialized) {
        return GoogleSignInResult(
          success: false,
          userMessage: UserFacingMessages.offlineHint,
        );
      }

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return const GoogleSignInResult(
          success: false,
          userMessage: 'Connexion annulée.',
        );
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCred.user;
      if (user == null) {
        return GoogleSignInResult(
          success: false,
          userMessage: UserFacingMessages.genericIssue,
        );
      }

      final resolution = await _resolver.resolve(
        firebaseUid: user.uid,
        email: user.email ?? googleUser.email,
        displayName: user.displayName ?? googleUser.displayName,
        photoUrl: user.photoURL ?? googleUser.photoUrl,
        providerId: 'google.com',
      );

      return GoogleSignInResult(
        success: true,
        route: resolution.route,
        firebaseUid: user.uid,
        request: resolution.request,
        userMessage: resolution.userMessage,
      );
    } catch (e, st) {
      TechnicalErrorRepository.record(source: 'google_sign_in', error: e, stack: st);
      return GoogleSignInResult(
        success: false,
        userMessage: UserFacingMessages.genericIssue,
      );
    }
  }

  Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}
