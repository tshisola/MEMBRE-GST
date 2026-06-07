import 'dart:convert';

import '../../app/constants.dart';

/// Compte staff admin / responsable — stocké localement (hash uniquement).
class AdminStaffAccount {
  const AdminStaffAccount({
    required this.id,
    required this.loginIdentifier,
    required this.displayName,
    required this.role,
    this.email,
    this.permissions = const [],
    this.isOwner = false,
    this.isActive = true,
    this.isLocked = false,
    this.mustChangePassword = true,
    this.passwordHash,
    this.passwordSalt,
    this.firebaseUid,
    this.createdAt,
    this.updatedAt,
    this.city = 'Lubumbashi',
  });

  final String id;
  final String loginIdentifier;
  final String displayName;
  final String role;
  final String? email;
  final List<String> permissions;
  final bool isOwner;
  final bool isActive;
  final bool isLocked;
  final bool mustChangePassword;
  final String? passwordHash;
  final String? passwordSalt;
  final String? firebaseUid;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String city;

  factory AdminStaffAccount.fromMap(Map<String, dynamic> map) {
    final permsRaw = map['permissions_json'] as String?;
    List<String> permissions = const [];
    if (permsRaw != null && permsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(permsRaw);
        if (decoded is List) {
          permissions = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    return AdminStaffAccount(
      id: map['id'] as String? ?? '',
      loginIdentifier: map['login_identifier'] as String? ?? '',
      displayName: map['display_name'] as String? ?? '',
      role: map['role'] as String? ?? '',
      email: map['email'] as String?,
      permissions: permissions,
      isOwner: (map['is_owner'] ?? 0) == 1,
      isActive: (map['is_active'] ?? 1) == 1,
      isLocked: (map['is_locked'] ?? 0) == 1,
      mustChangePassword: (map['must_change_password'] ?? 1) == 1,
      passwordHash: map['password_hash'] as String?,
      passwordSalt: map['password_salt'] as String?,
      firebaseUid: map['firebase_uid'] as String?,
      createdAt: _dt(map['created_at']),
      updatedAt: _dt(map['updated_at']),
      city: map['city'] as String? ?? 'Lubumbashi',
    );
  }

  Map<String, dynamic> toMap({bool includeSecrets = false}) {
    return {
      'id': id,
      'login_identifier': loginIdentifier,
      'display_name': displayName,
      'role': role,
      if (email != null) 'email': email,
      'permissions_json': jsonEncode(permissions),
      'is_owner': isOwner ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'is_locked': isLocked ? 1 : 0,
      'must_change_password': mustChangePassword ? 1 : 0,
      if (includeSecrets && passwordHash != null) 'password_hash': passwordHash,
      if (includeSecrets && passwordSalt != null) 'password_salt': passwordSalt,
      if (firebaseUid != null) 'firebase_uid': firebaseUid,
      'city': city,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  static DateTime? _dt(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());

  /// Profil staff depuis Firestore (connexion Web sans SQLite).
  factory AdminStaffAccount.fromFirestoreMap(
    Map<String, dynamic> data, {
    required String uid,
  }) {
    List<String> permissions = const [];
    final perms = data['permissions'];
    if (perms is List) {
      permissions = perms.map((e) => e.toString()).toList();
    }
    final role = data['role'] as String? ?? '';
    final loginId = data['loginIdentifier'] as String? ??
        (data['email'] as String?)?.split('@').first ??
        uid;
    return AdminStaffAccount(
      id: data['id'] as String? ?? uid,
      loginIdentifier: loginId,
      displayName: (data['displayName'] ?? data['fullName'] ?? loginId)
          .toString(),
      role: role,
      email: data['email'] as String?,
      permissions: permissions,
      isOwner: data['isOwner'] == true ||
          role == AppConstants.roleAdminGeneralOwner,
      isActive: data['isActive'] != false,
      isLocked: data['isLocked'] == true,
      mustChangePassword: data['mustChangePassword'] == true,
      firebaseUid: uid,
      city: data['city'] as String? ?? AppConstants.city,
    );
  }
}
