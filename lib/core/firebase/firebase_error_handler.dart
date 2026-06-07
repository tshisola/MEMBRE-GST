import 'package:flutter/foundation.dart';

/// Normalizes Firebase/Firestore errors for UI display.
class FirebaseErrorHandler {
  FirebaseErrorHandler._();

  static String message(Object error) {
    final text = error.toString();
    if (text.contains('permission-denied')) {
      return 'Accès Firebase refusé. Vérifiez vos droits administrateur.';
    }
    if (text.contains('unavailable') || text.contains('network')) {
      return 'Firebase indisponible. Les données restent en local.';
    }
    if (text.contains('not-found')) {
      return 'Document introuvable sur Firebase.';
    }
    return 'Erreur Firebase : ${text.length > 120 ? '${text.substring(0, 120)}…' : text}';
  }

  static void log(Object error, [StackTrace? stack]) {
    debugPrint('[FirebaseError] $error');
    if (stack != null) debugPrint(stack.toString());
  }
}
