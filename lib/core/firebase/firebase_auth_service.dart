import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_initializer.dart';

/// Email/password authentication wrapper with auth state stream.
class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  bool get isAvailable => FirebaseInitializer.isInitialized;

  User? get currentUser => isAvailable ? _auth.currentUser : null;

  Stream<User?> authStateChanges() {
    if (!isAvailable) {
      return Stream<User?>.value(null);
    }
    return _auth.authStateChanges();
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _ensureAvailable();
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    _ensureAvailable();
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() async {
    if (!isAvailable) return;
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    _ensureAvailable();
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  void _ensureAvailable() {
    if (!isAvailable) {
      throw StateError(
        'Firebase Auth is unavailable. App is running in offline mode.',
      );
    }
  }
}
