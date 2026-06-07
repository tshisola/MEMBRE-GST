import 'admin_recovery_cloud_service.dart';
import '../../app/constants.dart';
import '../../shared/models/admin_staff_account_model.dart';
import '../firebase/firebase_auth_service.dart';
import '../firebase/firebase_initializer.dart';
import '../logging/app_logger.dart';
import '../sync/member_sync_manager.dart';
import 'admin_owner_seed_service.dart';
import 'firebase_account_management_service.dart';
import 'local_admin_auth_service.dart';
import 'staff_firebase_linker.dart';
import 'staff_seed_credentials.dart';

/// Résultat professionnel — jamais de détail technique côté UI.
class AdminRecoveryResult {
  const AdminRecoveryResult({
    required this.success,
    required this.message,
    this.temporaryPassword,
    this.emailSent = false,
    this.ownerLocal = false,
    this.ownerOnline = false,
  });

  final bool success;
  final String message;
  final String? temporaryPassword;
  final bool emailSent;
  final bool ownerLocal;
  final bool ownerOnline;
}

/// État de vérification multi-source (SQLite + Firebase).
class AdminRecoveryStatusReport {
  const AdminRecoveryStatusReport({
    required this.ownerEmail,
    required this.existsLocally,
    required this.isActiveLocally,
    required this.isLockedLocally,
    required this.firebaseAvailable,
    required this.needsRecovery,
  });

  final String ownerEmail;
  final bool existsLocally;
  final bool isActiveLocally;
  final bool isLockedLocally;
  final bool firebaseAvailable;
  final bool needsRecovery;
}

/// Orchestrateur récupération Admin Général — local d'abord, Firebase derrière.
class AdminRecoveryOrchestrator {
  AdminRecoveryOrchestrator({
    LocalAdminAuthService? auth,
    StaffFirebaseLinker? linker,
    FirebaseAuthService? firebaseAuth,
    FirebaseAccountManagementService? firebaseMgmt,
    AdminOwnerSeedService? seed,
  })  : _auth = auth ?? LocalAdminAuthService(),
        _linker = linker ?? StaffFirebaseLinker(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuthService(),
        _firebaseMgmt = firebaseMgmt ?? FirebaseAccountManagementService(),
        _seed = seed ?? AdminOwnerSeedService();

  final LocalAdminAuthService _auth;
  final StaffFirebaseLinker _linker;
  final FirebaseAuthService _firebaseAuth;
  final FirebaseAccountManagementService _firebaseMgmt;
  final AdminOwnerSeedService _seed;

  static const ownerEmail = AppConstants.staffOwnerPrimaryEmail;

  Future<AdminRecoveryStatusReport> evaluate() async {
    await _seed.seedIfMissing();
    await _auth.ensureStaffFirebaseEmails();
    final owner = await _auth.findOwner();
    final firebaseAvailable = FirebaseInitializer.isInitialized;

    return AdminRecoveryStatusReport(
      ownerEmail: ownerEmail,
      existsLocally: owner != null,
      isActiveLocally: owner?.isActive ?? false,
      isLockedLocally: owner?.isLocked ?? false,
      firebaseAvailable: firebaseAvailable,
      needsRecovery: owner == null || !owner.isActive || owner.isLocked,
    );
  }

  Future<AdminRecoveryResult> restoreVerdickOwner({
    String actorId = 'admin_recovery',
  }) async {
    try {
      await _seed.seedIfMissing();
      final owner = await _auth.ensureOwnerAccount(actorId: actorId);
      await _auth.unlockOwner(owner.id, actorId: actorId);
      await _auth.setActive(
        accountId: owner.id,
        isActive: true,
        actorId: actorId,
      );

      final reset = await _auth.applyProvisionalPassword(
        accountId: owner.id,
        actorId: actorId,
        loginIdentifier: AppConstants.staffLoginVerdick,
      );

      await _syncOwnerOnline(reset.account, reset.temporaryPassword);

      if (FirebaseInitializer.isInitialized) {
        try {
          await AdminRecoveryCloudService().seedOrResetVerdickOwner(
            email: ownerEmail,
            resetPassword: true,
          );
        } catch (e, st) {
          AppLogger.error('AdminRecovery', 'seedOrReset CF', e, st);
        }
      }

      await AdminRecoverySyncService.instance.runAfterRecovery(
        trigger: 'restore_verdick',
      );

      return AdminRecoveryResult(
        success: true,
        message: 'Compte Admin Général configuré avec succès.',
        temporaryPassword: reset.temporaryPassword,
        ownerLocal: true,
        ownerOnline: FirebaseInitializer.isInitialized,
      );
    } catch (e, st) {
      AppLogger.error('AdminRecovery', 'restoreVerdick', e, st);
      return const AdminRecoveryResult(
        success: false,
        message: 'Restauration impossible pour le moment.',
      );
    }
  }

  Future<AdminRecoveryResult> sendPasswordResetEmail({
    String email = ownerEmail,
  }) async {
    if (!FirebaseInitializer.isInitialized) {
      return const AdminRecoveryResult(
        success: false,
        message: 'Connexion en ligne requise pour envoyer le lien.',
      );
    }
    try {
      await _firebaseAuth.sendPasswordResetEmail(email);
      if (AppConstants.staffProvisioningUsesCloudFunctions) {
        await _firebaseMgmt.resetVerdickPassword(sendEmail: true);
      }
      await AdminRecoverySyncService.instance.runAfterRecovery(
        trigger: 'password_reset_email',
      );
      return AdminRecoveryResult(
        success: true,
        message:
            'Un lien de réinitialisation a été envoyé à votre adresse email.',
        emailSent: true,
        ownerOnline: true,
      );
    } catch (e, st) {
      AppLogger.error('AdminRecovery', 'sendResetEmail', e, st);
      return const AdminRecoveryResult(
        success: false,
        message: 'Envoi impossible pour le moment.',
      );
    }
  }

  Future<AdminRecoveryResult> createOrUpdateJeno({
    String? email,
    String actorId = 'admin_recovery',
  }) async {
    try {
      final jeno = await _auth.ensureJenoAccount(
        actorId: actorId,
        email: email,
      );
      final pwd = StaffSeedCredentials.seedPassword(AppConstants.staffLoginJeno);
      if (pwd != null && FirebaseInitializer.isInitialized) {
        await _linker.linkStaffAccount(
          account: jeno,
          password: pwd,
          signOutAfter: true,
        );
      }
      if (AppConstants.staffProvisioningUsesCloudFunctions &&
          FirebaseInitializer.isInitialized) {
        await _firebaseMgmt.createJenoAdminGeneral(
          email: jeno.email ?? AppConstants.staffEmailJeno,
        );
      }
      await AdminRecoverySyncService.instance.runAfterRecovery(
        trigger: 'jeno_upsert',
      );
      return AdminRecoveryResult(
        success: true,
        message: 'Compte Jeno Admin Général mis à jour.',
        ownerOnline: FirebaseInitializer.isInitialized,
      );
    } catch (e, st) {
      AppLogger.error('AdminRecovery', 'jeno', e, st);
      return const AdminRecoveryResult(
        success: false,
        message: 'Mise à jour impossible pour le moment.',
      );
    }
  }

  Future<void> _syncOwnerOnline(
    AdminStaffAccount account,
    String temporaryPassword,
  ) async {
    if (!FirebaseInitializer.isInitialized) return;

    await _linker.linkStaffAccount(
      account: account,
      password: temporaryPassword,
      signOutAfter: true,
    );

    if (AppConstants.staffProvisioningUsesCloudFunctions) {
      await _firebaseMgmt.seedVerdickOwner(
        email: account.email ?? ownerEmail,
        displayName: account.displayName,
      );
    }
  }
}

/// Synchronisation automatique après récupération admin.
class AdminRecoverySyncService {
  AdminRecoverySyncService._();
  static final AdminRecoverySyncService instance = AdminRecoverySyncService._();

  Future<void> runAfterRecovery({required String trigger}) async {
    await MemberSyncManager().syncNow(silent: true);
    AppLogger.sync('Sync après récupération admin ($trigger)');
  }
}

typedef AccountSyncService = AdminRecoverySyncService;
typedef RolePermissionSyncService = AdminRecoverySyncService;
typedef BackgroundSyncService = AdminRecoverySyncService;
