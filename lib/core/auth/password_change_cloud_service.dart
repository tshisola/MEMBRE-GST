import 'package:cloud_functions/cloud_functions.dart';

import '../firebase/firebase_initializer.dart';
import '../logging/technical_error_repository.dart';
import '../messaging/auth_error_sanitizer.dart';

/// Appels Cloud Function changement mot de passe — jamais de mot de passe en log.
class PasswordChangeCloudService {
  PasswordChangeCloudService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  bool get isAvailable => FirebaseInitializer.isInitialized;

  Future<PasswordChangeCloudResult> changePassword({
    required String newPassword,
  }) async {
    if (!isAvailable) {
      return const PasswordChangeCloudResult(
        success: false,
        message: 'Connexion en ligne requise.',
      );
    }
    try {
      final result = await _functions
          .httpsCallable('changeUserPasswordCallable')
          .call({'newPassword': newPassword});
      final raw = result.data;
      if (raw is Map) {
        return PasswordChangeCloudResult(
          success: raw['success'] == true,
          message: raw['message'] as String? ??
              'Mot de passe changé avec succès.',
          reconnectHint: raw['reconnectHint'] as String?,
        );
      }
      return const PasswordChangeCloudResult(
        success: true,
        message: 'Mot de passe changé avec succès.',
      );
    } catch (e, st) {
      TechnicalErrorRepository.record(
        source: 'password_change_cloud',
        error: e,
        stack: st,
      );
      return PasswordChangeCloudResult(
        success: false,
        message: AuthErrorSanitizer.sanitize(e),
      );
    }
  }
}

class PasswordChangeCloudResult {
  const PasswordChangeCloudResult({
    required this.success,
    this.message,
    this.reconnectHint,
  });

  final bool success;
  final String? message;
  final String? reconnectHint;
}
