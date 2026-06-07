import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../app/constants.dart';
import '../../features/members/data/local_member_repository.dart';
import '../database/database_helper.dart';
import '../firebase/firebase_initializer.dart';
import '../firebase/firestore_service.dart';

/// Offline action queue for auth and account operations.
class OfflineActionQueue {
  OfflineActionQueue({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  Future<void> enqueue({
    required String actionType,
    Map<String, dynamic>? payload,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().toIso8601String();
    await db.insert(AppConstants.tableOfflineActionQueue, {
      'id': _uuid.v4(),
      'action_type': actionType,
      'payload_json': payload != null ? jsonEncode(payload) : null,
      'status': 'pending',
      'retry_count': 0,
      'city': AppConstants.city,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<int> flushPending() async {
    if (!FirebaseInitializer.isInitialized) return 0;

    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      AppConstants.tableOfflineActionQueue,
      where: 'status IN (?, ?)',
      whereArgs: ['pending', 'failed'],
      orderBy: 'created_at ASC',
    );

    var processed = 0;
    for (final row in rows) {
      try {
        final actionType = row['action_type'] as String;
        final payloadRaw = row['payload_json'] as String?;
        final payload = payloadRaw != null
            ? jsonDecode(payloadRaw) as Map<String, dynamic>
            : <String, dynamic>{};

        await _dispatch(actionType, payload);

        await db.update(
          AppConstants.tableOfflineActionQueue,
          {'status': 'completed', 'updated_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [row['id']],
        );
        processed++;
      } catch (e) {
        await db.update(
          AppConstants.tableOfflineActionQueue,
          {
            'status': 'failed',
            'retry_count': (row['retry_count'] as int? ?? 0) + 1,
            'last_error': e.toString(),
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      }
    }
    return processed;
  }

  /// Marks pending member_upsert actions as completed after direct push.
  Future<void> completeMemberUpsert(String localId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      AppConstants.tableOfflineActionQueue,
      where: "action_type = 'member_upsert' AND status IN ('pending', 'failed')",
    );
    for (final row in rows) {
      final raw = row['payload_json'] as String?;
      if (raw == null) continue;
      final payload = jsonDecode(raw) as Map<String, dynamic>;
      final id = payload['localId'] as String? ?? payload['id'] as String?;
      if (id == localId) {
        await db.update(
          AppConstants.tableOfflineActionQueue,
          {
            'status': 'completed',
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      }
    }
  }

  Future<void> _dispatch(String actionType, Map<String, dynamic> payload) async {
    switch (actionType) {
      case 'member_account_upsert':
        await FirestoreService().createDocument(
          AppConstants.collectionMemberAccounts,
          payload,
          id: payload['id'] as String,
        );
      case 'department_list_upsert':
        await FirestoreService().createDocument(
          AppConstants.collectionDepartmentManualLists,
          payload,
          id: payload['id'] as String,
        );
      case 'audit_log_upsert':
        await FirestoreService().createDocument(
          AppConstants.collectionAuditLogs,
          payload,
          id: payload['id'] as String,
        );
      case 'member_upsert':
        final localId = payload['localId'] as String? ?? payload['id'] as String;
        await FirestoreService().createDocument(
          AppConstants.collectionMembers,
          payload,
          id: localId,
        );
        final qrCodeId = payload['qrCodeId'] as String?;
        if (qrCodeId != null) {
          await FirestoreService().createDocument(
            AppConstants.collectionMemberQrCodes,
            {
              'memberId': localId,
              'memberCode': payload['memberCode'],
              'qrCodeId': qrCodeId,
              'qrData': payload['qrData'],
              'isActive': payload['isActive'] ?? true,
            },
            id: qrCodeId,
          );
        }
        await LocalMemberRepository().updateSyncStatus(
          localId,
          syncStatus: AppConstants.syncStatusSynced,
          syncedAt: DateTime.now(),
        );
    }
  }
}
