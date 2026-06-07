import '../../shared/models/admin_staff_account_model.dart';
import '../firebase/firebase_initializer.dart';
import '../logging/technical_error_repository.dart';
import 'local_admin_auth_service.dart';
import 'staff_firebase_linker.dart';
import 'staff_seed_credentials.dart';

class StaffProvisionResult {
  const StaffProvisionResult({
    required this.success,
    this.created = 0,
    this.linked = 0,
    this.skipped = 0,
    this.errors = const [],
    this.emailPasswordDisabled = false,
  });

  final bool success;
  final int created;
  final int linked;
  final int skipped;
  final List<String> errors;
  final bool emailPasswordDisabled;

  bool get allProvisioned => errors.isEmpty && (created + linked + skipped) > 0;
}

/// Crée les comptes Firebase Auth + documents Firestore users pour le staff.
/// Plan Spark uniquement — aucune Cloud Function requise.
class StaffFirebaseProvisioningService {
  StaffFirebaseProvisioningService({
    LocalAdminAuthService? auth,
    StaffFirebaseLinker? linker,
  })  : _auth = auth ?? LocalAdminAuthService(),
        _linker = linker ?? StaffFirebaseLinker();

  final LocalAdminAuthService _auth;
  final StaffFirebaseLinker _linker;

  /// Provisionne tous les comptes staff si Firebase est disponible.
  Future<StaffProvisionResult> provisionAllIfNeeded() async {
    if (!FirebaseInitializer.isInitialized) {
      return const StaffProvisionResult(success: false, errors: ['Firebase offline']);
    }

    await _auth.ensureStaffFirebaseEmails();
    final staff = await _auth.listStaff(activeOnly: true);
    if (staff.isEmpty) {
      return const StaffProvisionResult(success: true, skipped: 0);
    }

    final needsWork = staff.any(
      (s) => s.firebaseUid == null || s.firebaseUid!.isEmpty,
    );
    if (!needsWork) {
      return StaffProvisionResult(success: true, skipped: staff.length);
    }

    return _provisionClientSide(_sortedStaff(staff));
  }

  List<AdminStaffAccount> _sortedStaff(List<AdminStaffAccount> staff) {
    final copy = List<AdminStaffAccount>.from(staff);
    copy.sort((a, b) {
      if (a.isOwner != b.isOwner) return a.isOwner ? -1 : 1;
      return a.loginIdentifier.compareTo(b.loginIdentifier);
    });
    return copy;
  }

  Future<StaffProvisionResult> _provisionClientSide(
    List<AdminStaffAccount> staff,
  ) async {
    var created = 0;
    var linked = 0;
    var skipped = 0;
    final errors = <String>[];
    var emailPasswordDisabled = false;

    for (final account in staff) {
      final pwd = StaffSeedCredentials.seedPassword(account.loginIdentifier);
      if (pwd == null) {
        skipped++;
        continue;
      }

      if (account.firebaseUid != null && account.firebaseUid!.isNotEmpty) {
        skipped++;
        continue;
      }

      final result = await _linker.linkStaffAccount(
        account: account,
        password: pwd,
        signOutAfter: true,
      );

      if (result == null) {
        errors.add('${account.displayName}: échec provisioning');
        continue;
      }

      if (result.created) {
        created++;
      } else if (result.linked) {
        linked++;
      }
    }

    if (errors.isNotEmpty) {
      emailPasswordDisabled = TechnicalErrorRepository.recent.any(
        (e) =>
            e.source.startsWith('staff_firebase_link_') &&
            (e.message.contains('operation-not-allowed') ||
                e.message.contains('OPERATION_NOT_ALLOWED')),
      );
    }

    return StaffProvisionResult(
      success: errors.isEmpty,
      created: created,
      linked: linked,
      skipped: skipped,
      errors: errors,
      emailPasswordDisabled: emailPasswordDisabled,
    );
  }
}
