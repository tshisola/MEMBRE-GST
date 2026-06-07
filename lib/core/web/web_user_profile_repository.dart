import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app/constants.dart';
import '../../shared/models/admin_staff_account_model.dart';
import '../../shared/models/member_account_model.dart';
import '../auth/staff_seed_credentials.dart';
import '../security/role_permission_matrix.dart';
import 'web_role_compatibility_service.dart';

/// Charge profils Firestore pour connexion Web (users + memberAccounts).
class WebUserProfileRepository {
  WebUserProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<WebUserProfile?> loadByUid({
    required String uid,
    String? email,
  }) async {
    final usersSnap =
        await _firestore.collection(AppConstants.collectionUsers).doc(uid).get();
    if (usersSnap.exists) {
      final data = usersSnap.data() ?? {};
      if ((data['role'] as String?)?.isNotEmpty == true) {
        return WebUserProfile.fromUsersDoc(data, uid: uid, email: email);
      }
    }

    if (email != null && email.isNotEmpty) {
      final byEmail = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();
      if (byEmail.docs.isNotEmpty) {
        final doc = byEmail.docs.first;
        return WebUserProfile.fromUsersDoc(doc.data(), uid: doc.id, email: email);
      }
    }

    final memberSnap = await _firestore
        .collection(AppConstants.collectionMemberAccounts)
        .doc(uid)
        .get();
    if (memberSnap.exists) {
      return WebUserProfile.fromMemberAccountsDoc(
        memberSnap.data() ?? {},
        uid: uid,
        email: email,
      );
    }

    final seed = _staffFromSeedEmail(email);
    if (seed != null) {
      return WebUserProfile.staff(seed, uid: uid, email: email);
    }

    return null;
  }

  Future<void> ensureStaffUserDoc({
    required String uid,
    required AdminStaffAccount account,
    required String email,
  }) async {
    final permissions = account.permissions.isNotEmpty
        ? account.permissions
        : RolePermissionMatrix.permissionsForRole(account.role);
    final withWeb = WebRoleCompatibilityService.ensureWebPermissions(
      role: account.role,
      permissions: permissions,
    );

    await _firestore.collection(AppConstants.collectionUsers).doc(uid).set(
      {
        'id': account.id,
        'loginIdentifier': account.loginIdentifier,
        'fullName': account.displayName,
        'displayName': account.displayName,
        'email': email.trim().toLowerCase(),
        'role': account.role,
        'roles': [account.role],
        'permissions': withWeb,
        'isOwner': account.isOwner,
        'isActive': account.isActive,
        'mustChangePassword': account.mustChangePassword,
        'city': account.city,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      SetOptions(merge: true),
    );
  }

  AdminStaffAccount? _staffFromSeedEmail(String? email) {
    if (email == null || email.isEmpty) return null;
    final normalized = email.trim().toLowerCase();
    for (final entry in StaffSeedCredentials.allEntries()) {
      if (entry.email.toLowerCase() == normalized) {
        return AdminStaffAccount(
          id: normalized,
          loginIdentifier: entry.login,
          displayName: entry.displayName,
          role: entry.role,
          email: entry.email,
          permissions: WebRoleCompatibilityService.ensureWebPermissions(
            role: entry.role,
            permissions: entry.permissions,
          ),
          isOwner: entry.isOwner,
          isActive: true,
          mustChangePassword: true,
        );
      }
    }
    if (normalized == AppConstants.staffOwnerPrimaryEmail) {
      return AdminStaffAccount(
        id: normalized,
        loginIdentifier: AppConstants.staffLoginVerdick,
        displayName: AppConstants.staffOwnerDisplayName,
        role: AppConstants.roleAdminGeneralOwner,
        email: normalized,
        permissions: RolePermissionMatrix.permissionsForRole(
          AppConstants.roleAdminGeneralOwner,
        ),
        isOwner: true,
        isActive: true,
        mustChangePassword: true,
      );
    }
    return null;
  }
}

class WebUserProfile {
  const WebUserProfile({
    required this.uid,
    required this.role,
    required this.accountType,
    this.email,
    this.displayName,
    this.loginIdentifier,
    this.permissions = const [],
    this.memberId,
    this.departmentId,
    this.isActive = true,
    this.mustChangePassword = false,
    this.isOwner = false,
  });

  final String uid;
  final String role;
  final String accountType;
  final String? email;
  final String? displayName;
  final String? loginIdentifier;
  final List<String> permissions;
  final String? memberId;
  final String? departmentId;
  final bool isActive;
  final bool mustChangePassword;
  final bool isOwner;

  bool get isStaff => accountType == AppConstants.accountTypeAdmin;

  AdminStaffAccount toStaffAccount() {
    return AdminStaffAccount(
      id: uid,
      loginIdentifier: loginIdentifier ?? email?.split('@').first ?? uid,
      displayName: displayName ?? loginIdentifier ?? 'Responsable',
      role: role,
      email: email,
      permissions: permissions,
      isOwner: isOwner,
      isActive: isActive,
      mustChangePassword: mustChangePassword,
      firebaseUid: uid,
    );
  }

  MemberAccount toMemberAccount() {
    return MemberAccount(
      id: uid,
      memberId: memberId ?? uid,
      loginIdentifier: loginIdentifier ?? email ?? uid,
      email: email,
      departmentId: departmentId,
      isActive: isActive,
      mustChangePassword: mustChangePassword,
    );
  }

  factory WebUserProfile.fromUsersDoc(
    Map<String, dynamic> data, {
    required String uid,
    String? email,
  }) {
    List<String> permissions = const [];
    final perms = data['permissions'];
    if (perms is List) {
      permissions = perms.map((e) => e.toString()).toList();
    }
    final role = data['role'] as String? ?? AppConstants.roleMember;
    permissions = WebRoleCompatibilityService.ensureWebPermissions(
      role: role,
      permissions: permissions,
    );
    final isStaff = AppConstants.adminRoles.contains(role);
    return WebUserProfile(
      uid: uid,
      role: role,
      accountType: isStaff
          ? AppConstants.accountTypeAdmin
          : AppConstants.accountTypeMember,
      email: email ?? data['email'] as String?,
      displayName: (data['displayName'] ?? data['fullName'])?.toString(),
      loginIdentifier: data['loginIdentifier'] as String?,
      permissions: permissions,
      memberId: data['memberId'] as String?,
      departmentId: data['departmentId'] as String?,
      isActive: data['isActive'] != false,
      mustChangePassword: data['mustChangePassword'] == true,
      isOwner: data['isOwner'] == true ||
          role == AppConstants.roleAdminGeneralOwner,
    );
  }

  factory WebUserProfile.fromMemberAccountsDoc(
    Map<String, dynamic> data, {
    required String uid,
    String? email,
  }) {
    return WebUserProfile(
      uid: uid,
      role: AppConstants.roleMember,
      accountType: AppConstants.accountTypeMember,
      email: email ?? data['email'] as String?,
      displayName: data['displayName'] as String?,
      loginIdentifier: data['loginIdentifier'] as String?,
      memberId: data['memberId'] as String?,
      departmentId: data['departmentId'] as String?,
      isActive: data['isActive'] != false,
      mustChangePassword: data['mustChangePassword'] == true,
    );
  }

  factory WebUserProfile.staff(
    AdminStaffAccount account, {
    required String uid,
    String? email,
  }) {
    return WebUserProfile(
      uid: uid,
      role: account.role,
      accountType: AppConstants.accountTypeAdmin,
      email: email ?? account.email,
      displayName: account.displayName,
      loginIdentifier: account.loginIdentifier,
      permissions: account.permissions,
      isActive: account.isActive,
      mustChangePassword: account.mustChangePassword,
      isOwner: account.isOwner,
    );
  }
}
