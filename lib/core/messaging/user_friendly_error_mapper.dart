import '../messaging/user_facing_messages.dart';

/// Messages utilisateur — jamais de texte technique Firebase/SQLite.
class UserFriendlyErrorMapper {
  UserFriendlyErrorMapper._();

  static String map(Object? error, {String? fallback}) {
    if (error == null) {
      return fallback ?? UserFacingMessages.genericIssue;
    }
    final raw = error.toString().toLowerCase();

    if (raw.contains('permission-denied') ||
        raw.contains('permission denied') ||
        raw.contains('not authorized')) {
      return 'Vous n\'êtes pas autorisé à effectuer cette action.';
    }
    if (raw.contains('unavailable') ||
        raw.contains('network') ||
        raw.contains('socket') ||
        raw.contains('connection')) {
      return 'Connexion instable. Les données seront synchronisées automatiquement.';
    }
    if (raw.contains('not-found') || raw.contains('introuvable')) {
      return 'Aucune liste disponible pour le moment.';
    }
    if (raw.contains('timeout') || raw.contains('deadline')) {
      return 'Une vérification est en cours. Réessayez dans un instant.';
    }
    if (raw.contains('failed-precondition') || raw.contains('index')) {
      return 'Synchronisation en cours. Les données locales sont affichées.';
    }
    if (raw.contains('sqlite') ||
        raw.contains('database') ||
        raw.contains('sqflite')) {
      return 'Données locales en cours de vérification.';
    }
    if (raw.contains('firebase') ||
        raw.contains('firestore') ||
        raw.contains('cloud_')) {
      return 'Connexion instable. Les données seront synchronisées automatiquement.';
    }
    if (raw.contains('exception') ||
        raw.contains('error code') ||
        raw.contains('stacktrace') ||
        raw.contains('stack trace')) {
      return fallback ?? UserFacingMessages.genericIssue;
    }

    return fallback ?? UserFacingMessages.genericIssue;
  }

  static bool isPermissionDenied(Object? error) {
    final raw = error.toString().toLowerCase();
    return raw.contains('permission-denied') ||
        raw.contains('permission denied');
  }

  static bool isNetworkIssue(Object? error) {
    final raw = error.toString().toLowerCase();
    return raw.contains('unavailable') ||
        raw.contains('network') ||
        raw.contains('socket');
  }
}
