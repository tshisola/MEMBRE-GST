import '../../app/constants.dart';
import '../firebase/firebase_initializer.dart';
import '../logging/technical_error_repository.dart';
import '../members/staff_firestore_profile_ensurer.dart';
import '../security/role_permission_matrix.dart';
import '../sync/sync_all_system_service.dart';
import '../sync/system_sync_client_service.dart';
import '../web/web_role_compatibility_service.dart';
import 'remote_update_applier.dart';

/// Synchronisation complète : config cloud + permissions + données.
class SyncAllCloudConfigService {
  SyncAllCloudConfigService({
    RemoteUpdateApplier? applier,
    SyncAllSystemService? systemSync,
    SystemSyncClientService? clientSync,
  })  : _applier = applier ?? RemoteUpdateApplier(),
        _systemSync = systemSync ?? SyncAllSystemService(),
        _clientSync = clientSync ?? SystemSyncClientService();

  final RemoteUpdateApplier _applier;
  final SyncAllSystemService _systemSync;
  final SystemSyncClientService _clientSync;

  bool canRun({required String? role}) => _systemSync.canRun(role: role);

  Future<SyncAllCloudResult> syncAll({
    required String? role,
  }) async {
    if (!canRun(role: role)) {
      return const SyncAllCloudResult(
        success: false,
        message: 'Action réservée au responsable principal.',
      );
    }

    if (!FirebaseInitializer.isInitialized) {
      return const SyncAllCloudResult(
        success: false,
        message: 'Connexion en ligne requise.',
      );
    }

    try {
      final configResult = await _applier.applyAll();
      final systemResult = await _systemSync.syncAll();
      final clientResult = await _clientSync.syncAllPermissions();

      return SyncAllCloudResult(
        success: true,
        message: 'Synchronisation terminée avec succès.',
        configVersion: configResult.configVersion,
        usersUpdated: systemResult.usersUpdated + clientResult.updated,
        permissionsFixed: systemResult.permissionsFixed + clientResult.permissionsFixed,
      );
    } catch (e, st) {
      TechnicalErrorRepository.record(
        source: 'sync_all_cloud_config',
        error: e,
        stack: st,
      );
      return const SyncAllCloudResult(
        success: false,
        message: 'Veuillez réessayer.',
      );
    }
  }
}

class SyncAllCloudResult {
  const SyncAllCloudResult({
    required this.success,
    this.message,
    this.configVersion,
    this.usersUpdated = 0,
    this.permissionsFixed = 0,
  });

  final bool success;
  final String? message;
  final String? configVersion;
  final int usersUpdated;
  final int permissionsFixed;
}

/// Alias demandés.
typedef SyncAllSystemDataService = SyncAllCloudConfigService;

/// Miroir compte Firebase Auth ↔ Firestore users.
class FirebaseAuthAccountMirror {
  FirebaseAuthAccountMirror({
    StaffFirestoreProfileEnsurer? ensurer,
  }) : _ensurer = ensurer ?? StaffFirestoreProfileEnsurer();

  final StaffFirestoreProfileEnsurer _ensurer;

  Future<void> ensureWebFields({
    required dynamic account,
  }) async {
    if (!FirebaseInitializer.isInitialized) return;
    await _ensurer.ensureForAccount(account);
  }
}

/// Compatibilité comptes mobile ↔ Web.
class AccountCompatibilityService {
  AccountCompatibilityService();

  List<String> webPermissionsForRole(String role, List<String> existing) {
    final template = RolePermissionMatrix.permissionsForRole(role);
    final merged = {...existing, ...template}.toList();
    return WebRoleCompatibilityService.ensureWebPermissions(
      role: role,
      permissions: merged,
    );
  }

  bool canAccessWeb({required String role, required List<String> permissions}) {
    return WebRoleCompatibilityService.canAccessWebApp(
      role: role,
      permissions: permissions,
    );
  }
}

typedef WebAccessSyncService = AccountCompatibilityService;

class RolePermissionWebSyncService {
  RolePermissionWebSyncService({SystemSyncClientService? client})
      : _client = client ?? SystemSyncClientService();

  final SystemSyncClientService _client;

  Future<int> syncAll() async {
    final result = await _client.syncAllPermissions();
    return result.updated;
  }
}
