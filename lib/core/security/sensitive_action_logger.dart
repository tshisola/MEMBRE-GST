import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../app/constants.dart';
import '../database/database_helper.dart';

/// Logs sensitive actions to local audit_logs (visible to Admin Général).
class SensitiveActionLogger {
  SensitiveActionLogger._();

  static final _uuid = Uuid();

  static Future<void> log({
    required String action,
    String? actorId,
    String? targetId,
    Map<String, dynamic>? metadata,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().toIso8601String();

    await db.insert(AppConstants.tableAuditLogs, {
      'id': _uuid.v4(),
      'action': action,
      'actor_id': actorId,
      'target_id': targetId,
      'metadata_json': metadata != null ? jsonEncode(metadata) : null,
      'city': AppConstants.city,
      'created_at': now,
    });
  }
}
