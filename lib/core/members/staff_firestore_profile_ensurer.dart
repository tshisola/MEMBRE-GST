import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../app/constants.dart';
import '../../shared/models/admin_staff_account_model.dart';
import '../auth/local_admin_auth_service.dart';
import '../auth/staff_seed_credentials.dart';
import '../firebase/firebase_initializer.dart';
import '../logging/technical_error_repository.dart';
import '../security/role_permission_matrix.dart';

/// Garantit le document Firestore users/{uid} avec rôle + permissions visibilité membres.
class StaffFirestoreProfileEnsurer {
  StaffFirestoreProfileEnsurer({
    LocalAdminAuthService? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? LocalAdminAuthService(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  final LocalAdminAuthService _auth;
  final FirebaseFirestore _firestore;

  Future<void> ensureForAccount(AdminStaffAccount account) async {
    if (!FirebaseInitializer.isInitialized) return;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? account.firebaseUid;
    if (uid == null || uid.isEmpty) return;

    final email = account.email?.trim().isNotEmpty == true
        ? account.email!.trim().toLowerCase()
        : StaffSeedCredentials.resolvedEmail(account.loginIdentifier);

    final permissions = _resolvedPermissions(account);

    try {
      final doc = _auth.staffDocForFirebase(account);
      doc['email'] = email;
      doc['permissions'] = permissions;
      doc['role'] = account.role;
      doc['roles'] = [account.role];
      doc['isActive'] = account.isActive;
      doc['updatedAt'] = DateTime.now().toIso8601String();

      await _firestore.collection(AppConstants.collectionUsers).doc(uid).set(
            doc,
            SetOptions(merge: true),
          );
    } catch (e, st) {
      TechnicalErrorRepository.record(
        source: 'staff_firestore_profile_ensurer',
        error: e,
        stack: st,
      );
    }
  }

  List<String> _resolvedPermissions(AdminStaffAccount account) {
    final fromRole = RolePermissionMatrix.permissionsForRole(account.role);
    if (account.permissions.isEmpty) return fromRole;
    final merged = {...account.permissions, ...fromRole}.toList();
    return merged;
  }
}

/// Met à jour les permissions visibilité membres pour tous les staff existants.
class StaffPermissionsMigrationService {
  StaffPermissionsMigrationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<int> migrateMemberVisibilityPermissions() async {
    if (!FirebaseInitializer.isInitialized) return 0;
    var updated = 0;
    final snap = await _firestore.collection(AppConstants.collectionUsers).get();
    for (final doc in snap.docs) {
      final data = doc.data();
      final role = data['role'] as String? ?? '';
      if (role.isEmpty) continue;
      final perms = RolePermissionMatrix.permissionsForRole(role);
      await doc.reference.set(
        {
          'permissions': perms,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );
      updated++;
    }
    return updated;
  }
}
