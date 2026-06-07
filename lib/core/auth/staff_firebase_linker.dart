import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../app/constants.dart';
import '../../shared/models/admin_staff_account_model.dart';
import '../firebase/firebase_auth_service.dart';
import '../firebase/firebase_initializer.dart';
import '../logging/technical_error_repository.dart';
import '../security/role_permission_matrix.dart';
import 'local_admin_auth_service.dart';
import 'staff_seed_credentials.dart';

class StaffFirebaseLinkResult {
  const StaffFirebaseLinkResult({
    required this.uid,
    required this.created,
    required this.linked,
  });

  final String uid;
  final bool created;
  final bool linked;
}

/// Lie un compte staff local à Firebase Auth + Firestore — sans Cloud Functions.
/// Fonctionne sur le plan Spark (gratuit).
class StaffFirebaseLinker {
  StaffFirebaseLinker({
    LocalAdminAuthService? auth,
    FirebaseAuthService? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? LocalAdminAuthService(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuthService(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  final LocalAdminAuthService _auth;
  final FirebaseAuthService _firebaseAuth;
  final FirebaseFirestore _firestore;

  Future<StaffFirebaseLinkResult?> linkStaffAccount({
    required AdminStaffAccount account,
    required String password,
    bool signOutAfter = false,
  }) async {
    if (!FirebaseInitializer.isInitialized) return null;

    final email = account.email?.trim().isNotEmpty == true
        ? account.email!.trim()
        : StaffSeedCredentials.resolvedEmail(account.loginIdentifier);

    try {
      final session = await _createOrSignIn(email: email, password: password);
      await _writeFirestoreUserDoc(account: account, uid: session.uid, email: email);

      if (account.firebaseUid != session.uid) {
        await _auth.updateFirebaseUid(
          account.id,
          firebaseUid: session.uid,
          email: email,
        );
      }

      return StaffFirebaseLinkResult(
        uid: session.uid,
        created: session.created,
        linked: session.linked,
      );
    } catch (e, st) {
      TechnicalErrorRepository.record(
        source: 'staff_firebase_link_${account.loginIdentifier}',
        error: e,
        stack: st,
      );
      return null;
    } finally {
      if (signOutAfter) {
        await _firebaseAuth.signOut();
      }
    }
  }

  Future<({String uid, bool created, bool linked})> _createOrSignIn({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _firebaseAuth.signInWithEmail(
        email: email,
        password: password,
      );
      final uid = cred.user?.uid;
      if (uid == null) throw StateError('uid_missing');
      return (uid: uid, created: false, linked: true);
    } on FirebaseAuthException catch (e) {
      if (!_isMissingAccountError(e)) rethrow;
    }

    try {
      final cred = await _firebaseAuth.signUpWithEmail(
        email: email,
        password: password,
      );
      final uid = cred.user?.uid;
      if (uid == null) throw StateError('uid_missing');
      return (uid: uid, created: true, linked: false);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        final cred = await _firebaseAuth.signInWithEmail(
          email: email,
          password: password,
        );
        final uid = cred.user?.uid;
        if (uid == null) throw StateError('uid_missing');
        return (uid: uid, created: false, linked: true);
      }
      rethrow;
    }
  }

  bool _isMissingAccountError(FirebaseAuthException e) {
    return e.code == 'user-not-found' ||
        e.code == 'invalid-credential' ||
        e.code == 'invalid-login-credentials';
  }

  Future<void> _writeFirestoreUserDoc({
    required AdminStaffAccount account,
    required String uid,
    required String email,
  }) async {
    final seed = StaffSeedCredentials.allEntries().firstWhere(
      (e) => e.login == account.loginIdentifier,
      orElse: () => StaffSeedEntry(
        login: account.loginIdentifier,
        displayName: account.displayName,
        role: account.role,
        isOwner: account.isOwner,
        permissions: account.permissions,
      ),
    );

    final doc = _auth.staffDocForFirebase(account);
    doc['email'] = email;
    final mergedPerms = {
      ...RolePermissionMatrix.permissionsForRole(account.role),
      ...seed.permissions,
      ...account.permissions,
    }.toList();
    doc['permissions'] = mergedPerms;
    if (seed.departmentId != null) {
      doc['departmentId'] = seed.departmentId;
    }

    await _firestore.collection(AppConstants.collectionUsers).doc(uid).set(
          doc,
          SetOptions(merge: true),
        );
  }

  /// Indique si Email/Mot de passe est désactivé côté Firebase (gratuit à activer).
  static bool isEmailPasswordDisabled(Object error) {
    if (error is FirebaseAuthException) {
      return error.code == 'operation-not-allowed';
    }
    return error.toString().contains('OPERATION_NOT_ALLOWED');
  }
}
