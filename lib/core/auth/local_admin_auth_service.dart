import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../app/constants.dart';
import '../../shared/models/admin_staff_account_model.dart';
import '../database/database_helper.dart';
import 'staff_seed_credentials.dart';
import '../security/role_permission_matrix.dart';
import '../security/secure_password_hash_service.dart';
import '../security/sensitive_action_logger.dart';
import '../sync/background_sync_trigger.dart';
import '../sync/offline_action_queue.dart';

class AdminAuthResult {
  const AdminAuthResult({
    required this.success,
    this.account,
    this.message,
    this.isDisabled = false,
    this.isLocked = false,
  });

  final bool success;
  final AdminStaffAccount? account;
  final String? message;
  final bool isDisabled;
  final bool isLocked;
}

/// Authentification staff admin — SQLite local, hash uniquement.
class LocalAdminAuthService {
  LocalAdminAuthService({
    Uuid? uuid,
    SecurePasswordHashService? hashService,
  })  : _uuid = uuid ?? const Uuid(),
        _hash = hashService ?? const SecurePasswordHashService();

  final Uuid _uuid;
  final SecurePasswordHashService _hash;

  Future<Database> _db() async {
    return DatabaseHelper.instance.database.timeout(
      const Duration(seconds: 8),
      onTimeout: () => throw TimeoutException('sqlite_not_ready'),
    );
  }

  Future<AdminAuthResult> authenticate({
    required String identifier,
    required String password,
  }) async {
    final Database db;
    try {
      db = await _db();
    } on TimeoutException {
      return const AdminAuthResult(
        success: false,
        message:
            'Service en préparation. Réessayez dans quelques secondes.',
      );
    }

    final normalized = identifier.trim().toLowerCase();
    final rows = await db.query(
      AppConstants.tableAdminStaffAccounts,
      where:
          'LOWER(login_identifier) = ? OR LOWER(email) = ?',
      whereArgs: [normalized, normalized],
      limit: 1,
    );

    if (rows.isEmpty) {
      return const AdminAuthResult(
        success: false,
        message: 'Identifiant ou mot de passe incorrect.',
      );
    }

    final account = AdminStaffAccount.fromMap(rows.first);
    if (!account.isActive) {
      return const AdminAuthResult(
        success: false,
        isDisabled: true,
        message: 'Compte désactivé. Contactez le responsable principal.',
      );
    }
    if (account.isLocked) {
      return const AdminAuthResult(
        success: false,
        isLocked: true,
        message: 'Compte verrouillé. Utilisez la récupération responsable.',
      );
    }

    final hash = account.passwordHash;
    final salt = account.passwordSalt;
    if (hash == null || salt == null) {
      return const AdminAuthResult(
        success: false,
        message: 'Compte non configuré.',
      );
    }

    if (!_hash.verifyPassword(
      password: password,
      salt: salt,
      expectedHash: hash,
    )) {
      return const AdminAuthResult(
        success: false,
        message: 'Identifiant ou mot de passe incorrect.',
      );
    }

    return AdminAuthResult(success: true, account: account);
  }

  Future<AdminStaffAccount?> findByLogin(String login) async {
    final db = await _db();
    final normalized = login.trim().toLowerCase();
    final rows = await db.query(
      AppConstants.tableAdminStaffAccounts,
      where: 'LOWER(login_identifier) = ?',
      whereArgs: [normalized],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AdminStaffAccount.fromMap(rows.first);
  }

  Future<AdminStaffAccount?> findOwner() async {
    final db = await _db();
    final rows = await db.query(
      AppConstants.tableAdminStaffAccounts,
      where: 'is_owner = 1 OR role = ?',
      whereArgs: [AppConstants.roleAdminGeneralOwner],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AdminStaffAccount.fromMap(rows.first);
  }

  Future<bool> ownerExists() async => (await findOwner()) != null;

  Future<List<AdminStaffAccount>> listStaff({bool? activeOnly}) async {
    final db = await _db();
    final rows = await db.query(
      AppConstants.tableAdminStaffAccounts,
      where: activeOnly == null ? null : 'is_active = ?',
      whereArgs: activeOnly == null ? null : [activeOnly ? 1 : 0],
      orderBy: 'display_name ASC',
    );
    return rows.map(AdminStaffAccount.fromMap).toList();
  }

  Future<AdminStaffAccount?> upsertStaff({
    required String loginIdentifier,
    required String displayName,
    required String role,
    required String plainPassword,
    String? email,
    bool isOwner = false,
    bool mustChangePassword = true,
    bool skipIfExists = true,
  }) async {
    final existing = await findByLogin(loginIdentifier);
    if (existing != null && skipIfExists) return existing;

    final db = await _db();
    final now = DateTime.now();
    final salt = _hash.generateSalt();
    final hash = _hash.hashPassword(plainPassword, salt);
    final permissions = RolePermissionMatrix.permissionsForRole(role);
    final id = existing?.id ?? _uuid.v4();

    final account = AdminStaffAccount(
      id: id,
      loginIdentifier: loginIdentifier,
      displayName: displayName,
      role: role,
      email: email,
      permissions: permissions,
      isOwner: isOwner,
      isActive: true,
      mustChangePassword: mustChangePassword,
      passwordHash: hash,
      passwordSalt: salt,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    await db.insert(
      AppConstants.tableAdminStaffAccounts,
      {
        ...account.toMap(includeSecrets: true),
        'created_at': (existing?.createdAt ?? now).toIso8601String(),
        'updated_at': now.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await SensitiveActionLogger.log(
      action: existing == null ? 'create_staff_account' : 'update_staff_account',
      actorId: 'system_seed',
      targetId: id,
      metadata: {
        'login': loginIdentifier,
        'role': role,
        'is_owner': isOwner,
      },
    );

    await _enqueueSync(account);
    return account;
  }

  Future<({AdminStaffAccount account, String temporaryPassword})> resetPassword({
    required String accountId,
    required String actorId,
  }) async {
    return applyProvisionalPassword(
      accountId: accountId,
      actorId: actorId,
    );
  }

  /// Applique le mot de passe seed (hashé) ou un mot de passe provisoire aléatoire.
  Future<({AdminStaffAccount account, String temporaryPassword})>
      applyProvisionalPassword({
    required String accountId,
    required String actorId,
    String? loginIdentifier,
  }) async {
    final db = await _db();
    final rows = await db.query(
      AppConstants.tableAdminStaffAccounts,
      where: 'id = ?',
      whereArgs: [accountId],
      limit: 1,
    );
    if (rows.isEmpty) throw StateError('account_not_found');

    final account = AdminStaffAccount.fromMap(rows.first);
    final login = loginIdentifier ?? account.loginIdentifier;
    final temp = StaffSeedCredentials.seedPassword(login) ??
        _hash.generateTemporaryPassword();
    final salt = _hash.generateSalt();
    final hash = _hash.hashPassword(temp, salt);
    final now = DateTime.now().toIso8601String();

    await db.update(
      AppConstants.tableAdminStaffAccounts,
      {
        'password_hash': hash,
        'password_salt': salt,
        'must_change_password': 1,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [accountId],
    );

    await db.insert(AppConstants.tableMemberPasswordResetLogs, {
      'id': _uuid.v4(),
      'account_id': accountId,
      'action': 'staff_password_reset',
      'actor_id': actorId,
      'city': AppConstants.city,
      'created_at': now,
    });

    await _enqueueSync(account);
    return (account: account, temporaryPassword: temp);
  }

  Future<void> setActive({
    required String accountId,
    required bool isActive,
    required String actorId,
  }) async {
    final db = await _db();
    final now = DateTime.now().toIso8601String();
    await db.update(
      AppConstants.tableAdminStaffAccounts,
      {'is_active': isActive ? 1 : 0, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [accountId],
    );
    await SensitiveActionLogger.log(
      action: isActive ? 'staff_account_activated' : 'staff_account_deactivated',
      actorId: actorId,
      targetId: accountId,
    );
  }

  Future<void> unlockOwner(String accountId, {required String actorId}) async {
    final db = await _db();
    final now = DateTime.now().toIso8601String();
    await db.update(
      AppConstants.tableAdminStaffAccounts,
      {'is_locked': 0, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [accountId],
    );
    await SensitiveActionLogger.log(
      action: 'owner_account_unlocked',
      actorId: actorId,
      targetId: accountId,
    );
  }

  Future<bool> verifyPasswordForAccount(
    String accountId,
    String password,
  ) async {
    final db = await _db();
    final rows = await db.query(
      AppConstants.tableAdminStaffAccounts,
      where: 'id = ?',
      whereArgs: [accountId],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    final account = AdminStaffAccount.fromMap(rows.first);
    if (account.passwordHash == null || account.passwordSalt == null) {
      return false;
    }
    return _hash.verifyPassword(
      password: password,
      salt: account.passwordSalt!,
      expectedHash: account.passwordHash!,
    );
  }

  Future<void> changePassword({
    required String accountId,
    required String oldPassword,
    required String newPassword,
  }) async {
    final db = await _db();
    final rows = await db.query(
      AppConstants.tableAdminStaffAccounts,
      where: 'id = ?',
      whereArgs: [accountId],
      limit: 1,
    );
    if (rows.isEmpty) throw StateError('account_not_found');

    final account = AdminStaffAccount.fromMap(rows.first);
    if (!_hash.verifyPassword(
      password: oldPassword,
      salt: account.passwordSalt!,
      expectedHash: account.passwordHash!,
    )) {
      throw StateError('wrong_password');
    }

    final salt = _hash.generateSalt();
    final hash = _hash.hashPassword(newPassword, salt);
    final now = DateTime.now().toIso8601String();

    await db.update(
      AppConstants.tableAdminStaffAccounts,
      {
        'password_hash': hash,
        'password_salt': salt,
        'must_change_password': 0,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [accountId],
    );
  }

  Future<void> _enqueueSync(AdminStaffAccount account) async {
    final payload = account.toMap(includeSecrets: false);
    await OfflineActionQueue().enqueue(
      actionType: 'admin_staff_upsert',
      payload: payload,
    );
    await BackgroundSyncTrigger().afterLocalWrite(
      entityType: 'admin_staff_account',
      entityId: account.id,
      actionType: 'admin_staff_upsert',
      payload: payload,
    );
  }

  Future<void> ensureStaffFirebaseEmails() async {
    final db = await _db();
    final staff = await listStaff();
    final now = DateTime.now().toIso8601String();
    for (final account in staff) {
      final expectedEmail = StaffSeedCredentials.resolvedEmail(
        account.loginIdentifier,
      );
      if (account.email == expectedEmail) continue;
      await db.update(
        AppConstants.tableAdminStaffAccounts,
        {'email': expectedEmail, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [account.id],
      );
    }
  }

  Future<AdminStaffAccount> ensureOwnerAccount({
    required String actorId,
  }) async {
    var owner = await findOwner();
    final email = AppConstants.staffOwnerPrimaryEmail;
    if (owner == null) {
      owner = await upsertStaff(
        loginIdentifier: AppConstants.staffLoginVerdick,
        displayName: AppConstants.staffOwnerDisplayName,
        role: AppConstants.roleAdminGeneralOwner,
        email: email,
        plainPassword: StaffSeedCredentials.seedPassword(
              AppConstants.staffLoginVerdick,
            ) ??
            'Verd@2026',
        isOwner: true,
        mustChangePassword: true,
        skipIfExists: false,
      );
      return owner!;
    }

    final db = await _db();
    final now = DateTime.now().toIso8601String();
    await db.update(
      AppConstants.tableAdminStaffAccounts,
      {
        'email': email,
        'display_name': AppConstants.staffOwnerDisplayName,
        'role': AppConstants.roleAdminGeneralOwner,
        'is_owner': 1,
        'is_active': 1,
        'is_locked': 0,
        'must_change_password': 1,
        'permissions_json': permissionsJson(
          RolePermissionMatrix.permissionsForRole(
            AppConstants.roleAdminGeneralOwner,
          ),
        ),
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [owner.id],
    );

    await SensitiveActionLogger.log(
      action: 'owner_account_restored',
      actorId: actorId,
      targetId: owner.id,
      metadata: {'email': email},
    );

    final refreshed = await findOwner();
    return refreshed ?? owner;
  }

  Future<AdminStaffAccount> ensureJenoAccount({
    required String actorId,
    String? email,
  }) async {
    final resolvedEmail = email?.trim().isNotEmpty == true
        ? email!.trim()
        : AppConstants.staffEmailJeno;
    var jeno = await findByLogin(AppConstants.staffLoginJeno);
    if (jeno == null) {
      jeno = await upsertStaff(
        loginIdentifier: AppConstants.staffLoginJeno,
        displayName: 'Jeno',
        role: AppConstants.roleAdminGeneral,
        email: resolvedEmail,
        plainPassword: StaffSeedCredentials.seedPassword(
              AppConstants.staffLoginJeno,
            ) ??
            'Jeno@2026',
        mustChangePassword: true,
        skipIfExists: false,
      );
      return jeno!;
    }

    final db = await _db();
    final now = DateTime.now().toIso8601String();
    await db.update(
      AppConstants.tableAdminStaffAccounts,
      {
        'email': resolvedEmail,
        'role': AppConstants.roleAdminGeneral,
        'is_active': 1,
        'is_locked': 0,
        'permissions_json': permissionsJson(
          RolePermissionMatrix.permissionsForRole(
            AppConstants.roleAdminGeneral,
          ),
        ),
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [jeno.id],
    );

    await SensitiveActionLogger.log(
      action: 'jeno_account_updated',
      actorId: actorId,
      targetId: jeno.id,
      metadata: {'email': resolvedEmail},
    );

    return (await findByLogin(AppConstants.staffLoginJeno)) ?? jeno;
  }

  Future<void> updateStaffEmail({
    required String accountId,
    required String email,
    required String actorId,
  }) async {
    final db = await _db();
    final now = DateTime.now().toIso8601String();
    await db.update(
      AppConstants.tableAdminStaffAccounts,
      {'email': email.trim(), 'updated_at': now},
      where: 'id = ?',
      whereArgs: [accountId],
    );
    await SensitiveActionLogger.log(
      action: 'staff_email_updated',
      actorId: actorId,
      targetId: accountId,
      metadata: {'email': email.trim()},
    );
  }

  Future<void> updateStaffRole({
    required String accountId,
    required String role,
    required String actorId,
    List<String>? permissions,
  }) async {
    final db = await _db();
    final now = DateTime.now().toIso8601String();
    final perms = permissions ?? RolePermissionMatrix.permissionsForRole(role);
    await db.update(
      AppConstants.tableAdminStaffAccounts,
      {
        'role': role,
        'permissions_json': permissionsJson(perms),
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [accountId],
    );
    await SensitiveActionLogger.log(
      action: 'staff_role_updated',
      actorId: actorId,
      targetId: accountId,
      metadata: {'role': role},
    );
  }

  Future<void> updateFirebaseUid(
    String accountId, {
    required String firebaseUid,
    String? email,
  }) async {
    final db = await _db();
    final now = DateTime.now().toIso8601String();
    await db.update(
      AppConstants.tableAdminStaffAccounts,
      {
        'firebase_uid': firebaseUid,
        if (email != null) 'email': email,
        'updated_at': now,
        'synced_at': now,
      },
      where: 'id = ?',
      whereArgs: [accountId],
    );
  }

  Map<String, dynamic> staffDocForFirebase(AdminStaffAccount account) {
    return {
      'id': account.id,
      'loginIdentifier': account.loginIdentifier,
      'fullName': account.displayName,
      'displayName': account.displayName,
      'role': account.role,
      'roles': [account.role],
      'permissions': account.permissions,
      'email': account.email,
      'isOwner': account.isOwner,
      'isActive': account.isActive,
      'mustChangePassword': account.mustChangePassword,
      if (account.isOwner) 'canManageEverything': true,
      'city': account.city,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  String permissionsJson(List<String> permissions) => jsonEncode(permissions);
}
