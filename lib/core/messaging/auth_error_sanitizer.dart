/// Convertit les erreurs techniques en messages utilisateur professionnels.
class AuthErrorSanitizer {
  AuthErrorSanitizer._();

  static String sanitize(Object? error) {
    if (error == null) {
      return 'Connexion impossible. Vérifiez vos identifiants.';
    }
    final raw = error.toString().toLowerCase();
    if (raw.contains('wrong-password') ||
        raw.contains('invalid-credential') ||
        raw.contains('user-not-found') ||
        raw.contains('incorrect')) {
      return 'Identifiant ou mot de passe incorrect.';
    }
    if (raw.contains('network') || raw.contains('socket')) {
      return 'Connexion réseau indisponible. Réessayez.';
    }
    if (raw.contains('disabled') || raw.contains('désactivé')) {
      return 'Compte désactivé. Contactez un responsable.';
    }
    if (raw.contains('locked') || raw.contains('verrouillé')) {
      return 'Compte verrouillé. Contactez le responsable principal.';
    }
    if (raw.contains('timeout') || raw.contains('sqlite')) {
      return 'Service en préparation. Réessayez dans un instant.';
    }
    return 'Connexion impossible. Vérifiez vos identifiants.';
  }
}
