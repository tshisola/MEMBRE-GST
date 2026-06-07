import 'package:cloud_functions/cloud_functions.dart';

import '../../app/constants.dart';
import '../firebase/firebase_initializer.dart';
import '../logging/technical_error_repository.dart';
import '../messaging/auth_error_sanitizer.dart';
import 'system_sync_client_service.dart';

/// Bouton Admin Général « Synchroniser tout » — Cloud Function owner.
class SyncAllSystemService {
  SyncAllSystemService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  bool get isAvailable => FirebaseInitializer.isInitialized;

  bool canRun({required String? role}) {
    return role == AppConstants.roleAdminGeneralOwner;
  }

  Future<SyncAllSystemResult> syncAll() async {
    if (!isAvailable) {
      return const SyncAllSystemResult(
        success: false,
        message: 'Connexion en ligne requise.',
      );
    }
    try {
      final result =
          await _functions.httpsCallable('syncAllSystemDataCallable').call();
      final raw = result.data;
      if (raw is Map) {
        return SyncAllSystemResult(
          success: raw['success'] == true,
          message: raw['message'] as String? ??
              'Synchronisation terminée avec succès.',
          usersUpdated: raw['usersUpdated'] as int? ?? 0,
          permissionsFixed: raw['permissionsFixed'] as int? ?? 0,
          webAccessGranted: raw['webAccessGranted'] as int? ?? 0,
        );
      }
      return const SyncAllSystemResult(
        success: true,
        message: 'Synchronisation terminée avec succès.',
      );
    } catch (e, st) {
      TechnicalErrorRepository.record(
        source: 'sync_all_system',
        error: e,
        stack: st,
      );
      final fallback = await SystemSyncClientService().syncAllPermissions();
      if (fallback.success) {
        return SyncAllSystemResult(
          success: true,
          message: fallback.message ?? 'Synchronisation terminée avec succès.',
          usersUpdated: fallback.updated,
          permissionsFixed: fallback.permissionsFixed,
          webAccessGranted: fallback.webAccessGranted,
        );
      }
      return SyncAllSystemResult(
        success: false,
        message: AuthErrorSanitizer.sanitize(e),
      );
    }
  }

  Future<SyncAllSystemResult> enableWebAccessForExistingAccounts() async {
    if (!isAvailable) {
      return const SyncAllSystemResult(
        success: false,
        message: 'Connexion en ligne requise.',
      );
    }
    try {
      final result = await _functions
          .httpsCallable('enableWebAccessForExistingAccountsCallable')
          .call();
      final raw = result.data;
      if (raw is Map) {
        return SyncAllSystemResult(
          success: raw['success'] == true,
          message: raw['message'] as String? ?? 'Accès Web mis à jour.',
          usersUpdated: raw['updated'] as int? ?? 0,
        );
      }
      return const SyncAllSystemResult(
        success: true,
        message: 'Accès Web mis à jour.',
      );
    } catch (e, st) {
      TechnicalErrorRepository.record(
        source: 'enable_web_access',
        error: e,
        stack: st,
      );
      return SyncAllSystemResult(
        success: false,
        message: AuthErrorSanitizer.sanitize(e),
      );
    }
  }
}

class SyncAllSystemResult {
  const SyncAllSystemResult({
    required this.success,
    this.message,
    this.usersUpdated = 0,
    this.permissionsFixed = 0,
    this.webAccessGranted = 0,
  });

  final bool success;
  final String? message;
  final int usersUpdated;
  final int permissionsFixed;
  final int webAccessGranted;
}
