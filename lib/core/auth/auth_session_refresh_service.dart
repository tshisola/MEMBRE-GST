import 'package:firebase_auth/firebase_auth.dart';

import '../firebase/firebase_initializer.dart';
import '../logging/technical_error_repository.dart';

/// Rafraîchit la session Firebase après changement mot de passe.
class AuthSessionRefreshService {
  AuthSessionRefreshService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Future<void> refreshAfterPasswordChange() async {
    if (!FirebaseInitializer.isInitialized) return;
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      await user.reload();
      await user.getIdToken(true);
    } catch (e, st) {
      TechnicalErrorRepository.record(
        source: 'auth_session_refresh',
        error: e,
        stack: st,
      );
    }
  }
}
