import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../app/constants.dart';
import '../firebase/firebase_initializer.dart';
import '../logging/technical_error_repository.dart';
import '../security/role_permission_matrix.dart';
import '../sync/system_sync_client_service.dart';
import 'web_role_compatibility_service.dart';

/// Migration can_access_web pour comptes existants (sans recréer les comptes).
class EnableWebAccessForExistingAccountsService {
  EnableWebAccessForExistingAccountsService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<WebAccessMigrationResult> migrateAll({bool preferCloud = true}) async {
    if (!FirebaseInitializer.isInitialized) {
      return const WebAccessMigrationResult(
        success: false,
        message: 'Connexion en ligne requise.',
      );
    }

    if (preferCloud) {
      try {
        final result = await _functions
            .httpsCallable('enableWebAccessForExistingAccountsCallable')
            .call();
        final raw = result.data;
        if (raw is Map && raw['success'] == true) {
          return WebAccessMigrationResult(
            success: true,
            updated: raw['updated'] as int? ?? 0,
            skipped: raw['skipped'] as int? ?? 0,
            message: raw['message'] as String?,
          );
        }
      } catch (e, st) {
        TechnicalErrorRepository.record(
          source: 'enable_web_access_cloud',
          error: e,
          stack: st,
        );
      }
    }

    final clientResult = await SystemSyncClientService().syncAllPermissions();
    return WebAccessMigrationResult(
      success: clientResult.success,
      updated: clientResult.updated,
      skipped: clientResult.skipped,
      message: clientResult.message ??
          (clientResult.success
              ? 'Accès Web activé pour ${clientResult.updated} compte(s).'
              : 'Connexion en ligne requise.'),
    );
  }
}

class WebAccessMigrationResult {
  const WebAccessMigrationResult({
    required this.success,
    this.updated = 0,
    this.skipped = 0,
    this.message,
  });

  final bool success;
  final int updated;
  final int skipped;
  final String? message;
}

/// Alias demandé.
typedef WebAccessPermissionMigration = EnableWebAccessForExistingAccountsService;

/// Réparation profil manquant côté Admin.
class WebProfileRepairService {
  WebProfileRepairService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<bool> markNeedsRepair({
    required String uid,
    required String email,
  }) async {
    if (!FirebaseInitializer.isInitialized) return false;
    await _firestore.collection(AppConstants.collectionUsers).doc(uid).set(
      {
        'email': email,
        'profileRepairNeeded': true,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      SetOptions(merge: true),
    );
    return true;
  }
}

/// Vérifie permission migration (Owner ou Jeno autorisé).
class WebAccessMigrationGuard {
  const WebAccessMigrationGuard();

  bool canRun({required String? role, required List<String> permissions}) {
    if (role == AppConstants.roleAdminGeneralOwner) return true;
    if (role == AppConstants.roleAdminGeneral &&
        permissions.contains(RolePermissionMatrix.canManageFirebaseFromApp)) {
      return true;
    }
    return false;
  }
}
