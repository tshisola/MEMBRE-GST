import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../app/constants.dart';
import '../../shared/models/member_account_model.dart';
import '../database/database_helper.dart';
import '../security/sensitive_action_logger.dart';
import '../sync/offline_action_queue.dart';
import '../sync/background_sync_trigger.dart';

class MemberAuthResult {
  const MemberAuthResult({
    required this.success,
    this.account,
    this.message,
    this.isDisabled = false,
  });

  final bool success;
  final MemberAccount? account;
  final String? message;
  final bool isDisabled;
}

/// Local-first member authentication (hash only, never plain password).
class MemberAuthService {
  MemberAuthService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  Future<Database> _databaseOrThrow() async {
    return DatabaseHelper.instance.database.timeout(
      const Duration(seconds: 8),
      onTimeout: () => throw TimeoutException('sqlite_not_ready'),
    );
  }

  Future<MemberAuthResult> authenticate({
    required String identifier,
    required String password,
  }) async {
    final Database db;
    try {
      db = await _databaseOrThrow();
    } on TimeoutException {
      return const MemberAuthResult(
        success: false,
        message:
            'Base locale en cours de préparation. Réessayez dans quelques secondes.',
      );
    }
    final normalized = identifier.trim().toLowerCase();

    final rows = await db.query(
      AppConstants.tableMemberAccounts,
      where:
          'LOWER(login_identifier) = ? OR LOWER(email) = ? OR phone = ? OR LOWER(member_id) = ?',
      whereArgs: [normalized, normalized, identifier.trim(), normalized],
      limit: 1,
    );

    if (rows.isEmpty) {
      return const MemberAuthResult(
        success: false,
        message: 'Identifiant ou mot de passe incorrect.',
      );
    }

    final account = MemberAccount.fromMap(rows.first);
    if (!account.isActive) {
      return const MemberAuthResult(
        success: false,
        isDisabled: true,
        message: 'Compte désactivé, contactez votre responsable.',
      );
    }

    final hash = rows.first['password_hash'] as String?;
    final salt = rows.first['password_salt'] as String?;
    if (hash == null || salt == null) {
      return const MemberAuthResult(
        success: false,
        message: 'Compte non configuré.',
      );
    }

    final computed = _hashPassword(password, salt);
    if (computed != hash) {
      return const MemberAuthResult(
        success: false,
        message: 'Identifiant ou mot de passe incorrect.',
      );
    }

    return MemberAuthResult(success: true, account: account);
  }

  String generateMemberCode() {
    final year = DateTime.now().year;
    final suffix = _uuid.v4().substring(0, 6).toUpperCase();
    return 'IFCM-$year-$suffix';
  }

  String generateTemporaryPassword({int length = 10}) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#';
    final seed = _uuid.v4().replaceAll('-', '');
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(chars[seed.codeUnitAt(i % seed.length) % chars.length]);
    }
    return buffer.toString();
  }

  Future<({MemberAccount account, String temporaryPassword})> createAccount({
    required String memberId,
    required String memberName,
    String? email,
    String? phone,
    String? departmentId,
    required String createdBy,
    String? customIdentifier,
  }) async {
    final db = await _databaseOrThrow();
    final id = _uuid.v4();
    final loginId = customIdentifier ?? generateMemberCode();
    final tempPassword = generateTemporaryPassword();
    final salt = _uuid.v4();
    final hash = _hashPassword(tempPassword, salt);
    final now = DateTime.now().toIso8601String();

    final account = MemberAccount(
      id: id,
      memberId: memberId,
      loginIdentifier: loginId,
      email: email,
      phone: phone,
      departmentId: departmentId,
      isActive: true,
      mustChangePassword: true,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      passwordHash: hash,
      passwordSalt: salt,
    );

    await db.insert(AppConstants.tableMemberAccounts, {
      'id': id,
      'member_id': memberId,
      'login_identifier': loginId,
      'email': email,
      'phone': phone,
      'department_id': departmentId,
      'is_active': 1,
      'must_change_password': 1,
      'created_by': createdBy,
      'password_hash': hash,
      'password_salt': salt,
      'city': AppConstants.city,
      'created_at': now,
      'updated_at': now,
    });

    await db.insert(AppConstants.tableMemberAccountSecurity, {
      'id': _uuid.v4(),
      'account_id': id,
      'must_change_password': 1,
      'failed_attempts': 0,
      'city': AppConstants.city,
      'updated_at': now,
    });

    await SensitiveActionLogger.log(
      action: 'create_member_account',
      actorId: createdBy,
      targetId: id,
      metadata: {'login_identifier': loginId, 'member_id': memberId},
    );

    await _enqueueAccountSync(account);

    return (account: account, temporaryPassword: tempPassword);
  }

  Future<void> _enqueueAccountSync(MemberAccount account) async {
    await OfflineActionQueue().enqueue(
      actionType: 'member_account_upsert',
      payload: account.toMap(includeSecrets: false),
    );
    await BackgroundSyncTrigger().afterLocalWrite(
      entityType: 'member_account',
      entityId: account.id,
      actionType: AppConstants.syncActionCreateMemberAccount,
      payload: account.toMap(includeSecrets: false),
    );
  }

  Future<List<MemberAccount>> listAccounts({bool? activeOnly}) async {
    final db = await _databaseOrThrow();
    final rows = await db.query(
      AppConstants.tableMemberAccounts,
      where: activeOnly == null ? null : 'is_active = ?',
      whereArgs: activeOnly == null ? null : [activeOnly ? 1 : 0],
      orderBy: 'created_at DESC',
    );
    return rows.map((r) => MemberAccount.fromMap(r)).toList();
  }

  Future<({MemberAccount account, String temporaryPassword})> resetPassword({
    required String accountId,
    required String actorId,
  }) async {
    final db = await _databaseOrThrow();
    final rows = await db.query(
      AppConstants.tableMemberAccounts,
      where: 'id = ?',
      whereArgs: [accountId],
      limit: 1,
    );
    if (rows.isEmpty) throw StateError('Compte introuvable');

    final tempPassword = generateTemporaryPassword();
    final salt = _uuid.v4();
    final hash = _hashPassword(tempPassword, salt);
    final now = DateTime.now().toIso8601String();

    await db.update(
      AppConstants.tableMemberAccounts,
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
      'action': 'password_reset_by_admin',
      'actor_id': actorId,
      'city': AppConstants.city,
      'created_at': now,
    });

    final account = MemberAccount.fromMap(rows.first);
    await _enqueueAccountSync(account);

    return (
      account: account,
      temporaryPassword: tempPassword,
    );
  }

  Future<void> setAccountActive({
    required String accountId,
    required bool isActive,
    required String actorId,
  }) async {
    final db = await _databaseOrThrow();
    final now = DateTime.now().toIso8601String();
    await db.update(
      AppConstants.tableMemberAccounts,
      {'is_active': isActive ? 1 : 0, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [accountId],
    );
    await db.insert(AppConstants.tableMemberPasswordResetLogs, {
      'id': _uuid.v4(),
      'account_id': accountId,
      'action': isActive ? 'account_activated' : 'account_deactivated',
      'actor_id': actorId,
      'city': AppConstants.city,
      'created_at': now,
    });

    final rows = await db.query(
      AppConstants.tableMemberAccounts,
      where: 'id = ?',
      whereArgs: [accountId],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      await _enqueueAccountSync(MemberAccount.fromMap(rows.first));
    }
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt:$password');
    return sha256.convert(bytes).toString();
  }
}
