import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../../app/constants.dart';
import '../database/database_helper.dart';
import '../sync/offline_action_queue.dart';

class PasswordStrength {
  const PasswordStrength({required this.isValid, required this.message});

  final bool isValid;
  final String message;

  static PasswordStrength evaluate(String password) {
    if (password.length < 8) {
      return const PasswordStrength(
        isValid: false,
        message: 'Minimum 8 caractères.',
      );
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return const PasswordStrength(
        isValid: false,
        message: 'Ajoutez une majuscule.',
      );
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return const PasswordStrength(
        isValid: false,
        message: 'Ajoutez une minuscule.',
      );
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return const PasswordStrength(
        isValid: false,
        message: 'Ajoutez un chiffre.',
      );
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/`~]').hasMatch(password)) {
      return const PasswordStrength(
        isValid: false,
        message: 'Ajoutez un caractère spécial.',
      );
    }
    return const PasswordStrength(isValid: true, message: 'Mot de passe fort.');
  }
}

/// Member password change — first login and voluntary change.
class MemberPasswordChangeService {
  MemberPasswordChangeService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  Future<String?> changePassword({
    required String accountId,
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword != confirmPassword) {
      return 'Les mots de passe ne correspondent pas.';
    }
    final strength = PasswordStrength.evaluate(newPassword);
    if (!strength.isValid) return strength.message;

    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      AppConstants.tableMemberAccounts,
      where: 'id = ?',
      whereArgs: [accountId],
      limit: 1,
    );
    if (rows.isEmpty) return 'Compte introuvable.';

    final account = rows.first;
    final salt = account['password_salt'] as String?;
    final hash = account['password_hash'] as String?;
    if (salt == null || hash == null) return 'Compte invalide.';

    final oldHash = _hash(oldPassword, salt);
    if (oldHash != hash) return 'Ancien mot de passe incorrect.';

    final newSalt = _uuid.v4();
    final newHash = _hash(newPassword, newSalt);
    final now = DateTime.now().toIso8601String();

    await db.update(
      AppConstants.tableMemberAccounts,
      {
        'password_hash': newHash,
        'password_salt': newSalt,
        'must_change_password': 0,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [accountId],
    );

    await db.insert(AppConstants.tableMemberPasswordResetLogs, {
      'id': _uuid.v4(),
      'account_id': accountId,
      'action': 'password_changed',
      'city': AppConstants.city,
      'created_at': now,
    });

    await OfflineActionQueue().enqueue(
      actionType: 'member_account_upsert',
      payload: {
        'id': accountId,
        'must_change_password': 0,
        'updated_at': now,
        'city': AppConstants.city,
      },
    );

    return null;
  }

  String _hash(String password, String salt) {
    final bytes = utf8.encode('$salt:$password');
    return sha256.convert(bytes).toString();
  }
}
