/// Messages utilisateur — jamais de détails techniques (SQLite, Timeout, etc.).
class UserFacingMessages {
  UserFacingMessages._();

  static const String preparingTitle = 'Chargement';
  static const String preparingBody = 'Veuillez patienter un instant.';
  static const String preparingContinue =
      'L\'application se charge. Vous pouvez continuer.';

  static const String backgroundPrep = 'Préparation des données…';
  static const String backgroundSync = 'Mise à jour en arrière-plan…';
  static const String syncInProgress = 'Synchronisation en cours…';
  static const String actionInProgress = 'Action en cours…';
  static const String pleaseWait = 'Veuillez patienter.';
  static const String retryLater = 'Réessayez dans un instant.';
  static const String contactAdmin =
      'Contactez l\'administrateur si le problème persiste.';
  static const String genericIssue =
      'Une vérification est en cours. Veuillez patienter.';
  static const String pageNotFound =
      'Cette page n\'est pas disponible pour le moment.';
  static const String displayIssue =
      'L\'affichage a rencontré un problème temporaire.';
  static const String offlineHint = 'Hors ligne — vos actions seront synchronisées.';
  static const String dataUpToDate = 'Données à jour';
}
