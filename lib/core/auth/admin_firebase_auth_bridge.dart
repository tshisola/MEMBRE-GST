import 'package:firebase_auth/firebase_auth.dart';

import '../firebase/firebase_initializer.dart';
import '../logging/technical_error_repository.dart';
import '../members/staff_firestore_profile_ensurer.dart';
import '../../shared/models/admin_staff_account_model.dart';
import 'staff_firebase_linker.dart';

/// Établit une session Firebase après auth locale admin (plan Spark, sans Cloud Functions).
class AdminFirebaseAuthBridge {
  AdminFirebaseAuthBridge({
    StaffFirebaseLinker? linker,
    StaffFirestoreProfileEnsurer? profileEnsurer,
  })  : _linker = linker ?? StaffFirebaseLinker(),
        _profileEnsurer = profileEnsurer ?? StaffFirestoreProfileEnsurer();

  final StaffFirebaseLinker _linker;
  final StaffFirestoreProfileEnsurer _profileEnsurer;

  Future<void> signInAfterLocalAuth({
    required AdminStaffAccount account,
    required String password,
  }) async {
    if (!FirebaseInitializer.isInitialized) return;

    if (FirebaseAuth.instance.currentUser != null) {
      await _profileEnsurer.ensureForAccount(account);
      return;
    }

    final result = await _linker.linkStaffAccount(
      account: account,
      password: password,
      signOutAfter: false,
    );

    if (result == null) {
      TechnicalErrorRepository.record(
        source: 'admin_firebase_auth_bridge',
        error: StateError('firebase_link_failed'),
      );
    } else {
      await _profileEnsurer.ensureForAccount(account);
    }
  }
}
