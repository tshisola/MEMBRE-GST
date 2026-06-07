import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../app/constants.dart';
import '../database/database_helper.dart';
import '../security/sensitive_action_logger.dart';

/// Journal d'audit pour suppressions et restaurations de membres.
class MemberDeletionAuditService {
  MemberDeletionAuditService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  Future<void> logSoftDelete({
    required String actorId,
    required String actorName,
    required String memberId,
    required String reason,
    String? memberCode,
  }) async {
    await _write(
      action: 'member_soft_delete',
      actorId: actorId,
      actorName: actorName,
      targetType: 'member',
      targetId: memberId,
      metadata: {
        'reason': reason,
        if (memberCode != null) 'memberCode': memberCode,
      },
    );
  }

  Future<void> logDeactivate({
    required String actorId,
    required String actorName,
    required String memberId,
    required String reason,
  }) async {
    await _write(
      action: 'member_deactivate',
      actorId: actorId,
      actorName: actorName,
      targetType: 'member',
      targetId: memberId,
      metadata: {'reason': reason},
    );
  }

  Future<void> logRestore({
    required String actorId,
    required String actorName,
    required String memberId,
    String? reason,
  }) async {
    await _write(
      action: 'member_restore',
      actorId: actorId,
      actorName: actorName,
      targetType: 'member',
      targetId: memberId,
      metadata: {if (reason != null) 'reason': reason},
    );
  }

  Future<void> logPermanentDelete({
    required String actorId,
    required String actorName,
    required String memberId,
    required String reason,
  }) async {
    await _write(
      action: 'member_permanent_delete',
      actorId: actorId,
      actorName: actorName,
      targetType: 'member',
      targetId: memberId,
      metadata: {'reason': reason},
    );
  }

  Future<void> logDeleteRequest({
    required String actorId,
    required String actorName,
    required String memberId,
    required String reason,
  }) async {
    await _write(
      action: 'member_delete_request',
      actorId: actorId,
      actorName: actorName,
      targetType: 'member',
      targetId: memberId,
      metadata: {'reason': reason},
    );
  }

  Future<void> _write({
    required String action,
    required String actorId,
    required String actorName,
    required String targetType,
    required String targetId,
    Map<String, dynamic>? metadata,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().toIso8601String();
    await db.insert(AppConstants.tableAuditLogs, {
      'id': _uuid.v4(),
      'action': action,
      'actor_id': actorId,
      'actor_name': actorName,
      'target_type': targetType,
      'target_id': targetId,
      'metadata_json': metadata != null ? jsonEncode(metadata) : null,
      'city': AppConstants.city,
      'created_at': now,
    });
    await SensitiveActionLogger.log(
      action: action,
      actorId: actorId,
      targetId: targetId,
      metadata: metadata,
    );
  }
}
