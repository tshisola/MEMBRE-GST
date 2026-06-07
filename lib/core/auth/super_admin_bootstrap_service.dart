import 'package:flutter/foundation.dart';

import 'admin_owner_seed_service.dart';
import 'local_admin_auth_service.dart';
import 'staff_firebase_provisioning_service.dart';
/// Bootstrap au démarrage — crée Verdick si absent, ne touche pas aux existants.
class SuperAdminBootstrapService {
  SuperAdminBootstrapService({
    AdminOwnerSeedService? seedService,
    LocalAdminAuthService? auth,
  })  : _seed = seedService ?? AdminOwnerSeedService(),
        _auth = auth ?? LocalAdminAuthService();

  final AdminOwnerSeedService _seed;
  final LocalAdminAuthService _auth;

  static bool bootstrapCompleted = false;

  Future<SuperAdminBootstrapResult> run() async {
    if (bootstrapCompleted) {
      return const SuperAdminBootstrapResult(alreadyDone: true);
    }

    try {
      final createdPasswords = await _seed.seedIfMissing();
      final owner = await _auth.findOwner();

      StaffProvisionResult? provisionResult;
      if (owner != null) {
        provisionResult =
            await StaffFirebaseProvisioningService().provisionAllIfNeeded();
      }

      bootstrapCompleted = true;

      return SuperAdminBootstrapResult(
        ownerExists: owner != null,
        newlyCreatedPasswords: createdPasswords,
        staffProvisionResult: provisionResult,
      );
    } catch (e, st) {
      debugPrint('[SuperAdminBootstrap] $e\n$st');
      return SuperAdminBootstrapResult(error: e);
    }
  }
}

class SuperAdminBootstrapResult {
  const SuperAdminBootstrapResult({
    this.ownerExists = false,
    this.newlyCreatedPasswords = const {},
    this.alreadyDone = false,
    this.error,
    this.staffProvisionResult,
  });

  final bool ownerExists;
  final Map<String, String> newlyCreatedPasswords;
  final bool alreadyDone;
  final Object? error;
  final StaffProvisionResult? staffProvisionResult;
}
