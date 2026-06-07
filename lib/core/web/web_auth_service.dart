import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../firebase/firebase_auth_service.dart';
import '../firebase/firebase_initializer.dart';
import '../messaging/auth_error_sanitizer.dart';
import 'web_firebase_config_checker.dart';

/// Authentification Web — Firebase Auth + messages propres.
class WebAuthService {
  WebAuthService({FirebaseAuthService? auth}) : _auth = auth ?? FirebaseAuthService();

  final FirebaseAuthService _auth;

  bool get isAvailable => kIsWeb && FirebaseInitializer.isInitialized;

  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    await _ensureWebReady();
    try {
      return await _auth.signInWithEmail(email: email, password: password);
    } catch (e) {
      throw AuthErrorSanitizer.sanitize(e);
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email);

  Stream<User?> authStateChanges() {
    if (!isAvailable) return Stream<User?>.value(null);
    return _auth.authStateChanges();
  }

  User? get currentUser => _auth.currentUser;

  Future<void> _ensureWebReady() async {
    if (!kIsWeb) return;
    if (!FirebaseInitializer.isInitialized) {
      await FirebaseWebInitializer.ensureInitialized();
    }
    if (!WebFirebaseConfigChecker.validateProject()) {
      throw AuthErrorSanitizer.sanitize('project_mismatch');
    }
  }
}

/// Alias demandé — orchestration login Web.
typedef WebLoginController = WebAuthService;
