import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase/firebase_auth_service.dart';
import '../providers/app_providers.dart';
import '../storage/local_session.dart';

/// Déconnexion complète — session locale + Firebase, champs login jamais préremplis.
class LogoutService {
  LogoutService({
    FirebaseAuthService? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuthService();

  final FirebaseAuthService _firebaseAuth;

  Future<void> logout(WidgetRef ref) async {
    await _firebaseAuth.signOut();
    TextInput.finishAutofillContext(shouldSave: false);

    final prefs = await ref.read(sharedPreferencesProvider.future);
    await logoutAndClearLoginState(prefs);
    ref.invalidate(localSessionProvider);
  }

  Future<void> logoutWithPrefs(SharedPreferences prefs, WidgetRef ref) async {
    await _firebaseAuth.signOut();
    TextInput.finishAutofillContext(shouldSave: false);
    await logoutAndClearLoginState(prefs);
    ref.invalidate(localSessionProvider);
  }
}

final logoutServiceProvider = Provider<LogoutService>((ref) {
  return LogoutService(
    firebaseAuth: ref.watch(firebaseAuthServiceProvider),
  );
});

/// Empêche Android/iOS de restaurer des identifiants dans les champs login.
void disableLoginAutofill() {
  TextInput.finishAutofillContext(shouldSave: false);
}
