import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

/// Hash sécurisé — jamais de mot de passe en clair stocké.
class SecurePasswordHashService {
  const SecurePasswordHashService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  String generateSalt() => _uuid.v4();

  String hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt:$password');
    return sha256.convert(bytes).toString();
  }

  bool verifyPassword({
    required String password,
    required String salt,
    required String expectedHash,
  }) {
    return hashPassword(password, salt) == expectedHash;
  }

  String generateTemporaryPassword({int length = 12}) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }
}

/// Alias demandé — même implémentation que [SecurePasswordHashService].
typedef SecurePasswordService = SecurePasswordHashService;
