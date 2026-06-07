import 'secure_error_mapper.dart';
import 'user_facing_messages.dart';

/// Messages professionnels centralisés pour toute l'application.
class UserFriendlyMessageService {
  UserFriendlyMessageService._();

  static String actionInProgress() => UserFacingMessages.actionInProgress;
  static String syncing() => UserFacingMessages.syncInProgress;
  static String dataUpdated() => 'Données mises à jour.';
  static String dataAvailable() => 'Données disponibles.';
  static String unauthorized() =>
      'Vous n\'êtes pas autorisé à effectuer cette action.';
  static String verificationInProgress() => UserFacingMessages.genericIssue;
  static String retryLater() => UserFacingMessages.retryLater;
  static String success() => 'Opération réussie.';
  static String saved() => 'Données enregistrées avec succès.';
  static String unstableConnection() =>
      'Connexion instable, vos données seront mises à jour automatiquement.';
  static String autoFixDone() => 'Correction automatique terminée.';
  static String genericError() => SecureErrorMapper.map(null);
  static String fromError(Object? error) => SecureErrorMapper.map(error);
  static String attendanceSaved() => 'Présence enregistrée.';
  static String accountActivated() => 'Compte activé avec succès.';
}
