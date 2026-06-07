import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../app/constants.dart';
import '../database/database_helper.dart';

/// Unified offline sync queue item.
class OfflineSyncQueueItem {
  const OfflineSyncQueueItem({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.actionType,
    required this.status,
    this.payload,
    this.retryCount = 0,
    this.lastError,
    this.createdAt,
    this.updatedAt,
    this.syncedAt,
  });

  final String id;
  final String entityType;
  final String entityId;
  final String actionType;
  final String status;
  final Map<String, dynamic>? payload;
  final int retryCount;
  final String? lastError;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? syncedAt;

  factory OfflineSyncQueueItem.fromRow(Map<String, Object?> row) {
    return OfflineSyncQueueItem(
      id: row['id'] as String,
      entityType: row['entity_type'] as String,
      entityId: row['entity_id'] as String,
      actionType: row['action_type'] as String,
      status: row['status'] as String,
      payload: row['payload_json'] != null
          ? jsonDecode(row['payload_json'] as String) as Map<String, dynamic>
          : null,
      retryCount: row['retry_count'] as int? ?? 0,
      lastError: row['last_error'] as String?,
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? ''),
      syncedAt: DateTime.tryParse(row['synced_at'] as String? ?? ''),
    );
  }
}

/// SQLite queue for all offline-first actions (local first, cloud behind).
class OfflineSyncQueue {
  OfflineSyncQueue({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  Future<String> enqueue({
    required String entityType,
    required String entityId,
    required String actionType,
    Map<String, dynamic>? payload,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    await db.insert(AppConstants.tableOfflineSyncQueue, {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'action_type': actionType,
      'payload_json': payload != null ? jsonEncode(payload) : null,
      'status': AppConstants.queueStatusPending,
      'retry_count': 0,
      'city': AppConstants.city,
      'created_at': now,
      'updated_at': now,
    });
    return id;
  }

  Future<List<OfflineSyncQueueItem>> listPending() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      AppConstants.tableOfflineSyncQueue,
      where: 'status IN (?, ?, ?)',
      whereArgs: [
        AppConstants.queueStatusPending,
        AppConstants.queueStatusFailed,
        AppConstants.queueStatusSyncing,
      ],
      orderBy: 'created_at ASC',
    );
    return rows.map(OfflineSyncQueueItem.fromRow).toList();
  }

  Future<int> countByStatus(String status) async {
    final db = await DatabaseHelper.instance.database;
    final r = await db.rawQuery(
      'SELECT COUNT(*) as c FROM ${AppConstants.tableOfflineSyncQueue} WHERE status = ?',
      [status],
    );
    return r.first['c'] as int? ?? 0;
  }

  Future<void> markSyncing(String id) async {
    await _updateStatus(id, AppConstants.queueStatusSyncing);
  }

  Future<void> markSynced(String id) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      AppConstants.tableOfflineSyncQueue,
      {
        'status': AppConstants.queueStatusSynced,
        'synced_at': now,
        'updated_at': now,
        'last_error': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markPendingRetry(String id, String error) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      AppConstants.tableOfflineSyncQueue,
      {
        'status': AppConstants.queueStatusPending,
        'last_error': error,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markFailed(String id, String error) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      AppConstants.tableOfflineSyncQueue,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final retry = (rows.first['retry_count'] as int? ?? 0) + 1;
    await db.update(
      AppConstants.tableOfflineSyncQueue,
      {
        'status': AppConstants.queueStatusFailed,
        'retry_count': retry,
        'last_error': error,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> _updateStatus(String id, String status) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      AppConstants.tableOfflineSyncQueue,
      {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> completeForEntity({
    required String entityType,
    required String entityId,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      AppConstants.tableOfflineSyncQueue,
      where: 'entity_type = ? AND entity_id = ? AND status IN (?, ?)',
      whereArgs: [
        entityType,
        entityId,
        AppConstants.queueStatusPending,
        AppConstants.queueStatusFailed,
      ],
    );
    final now = DateTime.now().toIso8601String();
    for (final row in rows) {
      await db.update(
        AppConstants.tableOfflineSyncQueue,
        {
          'status': AppConstants.queueStatusSynced,
          'synced_at': now,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
  }

  Future<List<OfflineSyncQueueItem>> listFailedAboveMax() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      AppConstants.tableOfflineSyncQueue,
      where: 'status = ? AND retry_count >= ?',
      whereArgs: [AppConstants.queueStatusFailed, AppConstants.syncMaxRetries],
      orderBy: 'updated_at DESC',
    );
    return rows.map(OfflineSyncQueueItem.fromRow).toList();
  }
}
