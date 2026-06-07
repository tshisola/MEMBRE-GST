import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../services/lubumbashi_branding_service.dart';
import '../services/media_firestore_constants.dart';

enum SyncOperation { upsert, delete }

enum SyncQueueStatus { pending, processing, failed, completed }

class SyncQueueItem {
  const SyncQueueItem({
    required this.id,
    required this.collection,
    required this.documentId,
    required this.operation,
    required this.status,
    this.payload,
    this.retryCount = 0,
    this.lastError,
    this.createdAt,
  });

  final String id;
  final String collection;
  final String documentId;
  final SyncOperation operation;
  final SyncQueueStatus status;
  final Map<String, dynamic>? payload;
  final int retryCount;
  final String? lastError;
  final DateTime? createdAt;

  factory SyncQueueItem.fromRow(Map<String, Object?> row) {
    return SyncQueueItem(
      id: row['id'] as String,
      collection: row['collection'] as String,
      documentId: row['document_id'] as String,
      operation: SyncOperation.values.byName(row['operation'] as String),
      status: SyncQueueStatus.values.byName(row['status'] as String),
      payload: row['payload_json'] != null
          ? jsonDecode(row['payload_json'] as String) as Map<String, dynamic>
          : null,
      retryCount: row['retry_count'] as int? ?? 0,
      lastError: row['last_error'] as String?,
      createdAt: row['created_at'] != null
          ? DateTime.tryParse(row['created_at'] as String)
          : null,
    );
  }
}

class SyncRunResult {
  const SyncRunResult({
    required this.processed,
    required this.failed,
    required this.pending,
  });

  final int processed;
  final int failed;
  final int pending;
}

/// Offline queue and sync status for media Firestore collections (Lubumbashi).
class SyncManager {
  SyncManager({
    required Future<Database> Function() databaseProvider,
    FirebaseFirestore? firestore,
    Uuid? uuid,
    this.maxRetries = 5,
  })  : _databaseProvider = databaseProvider,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = uuid ?? const Uuid();

  final Future<Database> Function() _databaseProvider;
  final FirebaseFirestore _firestore;
  final Uuid _uuid;
  final int maxRetries;

  Future<void> ensureQueueTable() async {
    final db = await _databaseProvider();
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${MediaLocalTables.syncQueue} (
        id TEXT PRIMARY KEY,
        collection TEXT NOT NULL,
        document_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload_json TEXT,
        status TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        created_at TEXT NOT NULL,
        city TEXT NOT NULL DEFAULT 'Lubumbashi'
      )
    ''');
  }

  Future<void> enqueue({
    required String collection,
    required String documentId,
    required SyncOperation operation,
    Map<String, dynamic>? payload,
  }) async {
    await ensureQueueTable();
    final db = await _databaseProvider();
    final id = _uuid.v4();
    final data = payload != null
        ? Map<String, dynamic>.from(payload)
        : <String, dynamic>{};
    data['city'] = LubumbashiBrandingService.city;

    await db.insert(
      MediaLocalTables.syncQueue,
      {
        'id': id,
        'collection': collection,
        'document_id': documentId,
        'operation': operation.name,
        'payload_json': payload != null ? jsonEncode(data) : null,
        'status': SyncQueueStatus.pending.name,
        'retry_count': 0,
        'created_at': DateTime.now().toIso8601String(),
        'city': LubumbashiBrandingService.city,
      },
    );
  }

  Future<SyncRunResult> flushQueue() async {
    await ensureQueueTable();
    final db = await _databaseProvider();
    final pending = await db.query(
      MediaLocalTables.syncQueue,
      where: 'status IN (?, ?)',
      whereArgs: [
        SyncQueueStatus.pending.name,
        SyncQueueStatus.failed.name,
      ],
      orderBy: 'created_at ASC',
    );

    var processed = 0;
    var failed = 0;

    for (final row in pending) {
      final item = SyncQueueItem.fromRow(row);
      if (item.retryCount >= maxRetries) {
        failed++;
        continue;
      }

      await db.update(
        MediaLocalTables.syncQueue,
        {'status': SyncQueueStatus.processing.name},
        where: 'id = ?',
        whereArgs: [item.id],
      );

      try {
        final ref = _firestore.collection(item.collection).doc(item.documentId);
        switch (item.operation) {
          case SyncOperation.upsert:
            await ref.set(
              {
                ...?item.payload,
                'city': LubumbashiBrandingService.city,
                'syncedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );
          case SyncOperation.delete:
            await ref.delete();
        }

        await db.update(
          MediaLocalTables.syncQueue,
          {'status': SyncQueueStatus.completed.name},
          where: 'id = ?',
          whereArgs: [item.id],
        );
        processed++;
      } catch (e) {
        await db.update(
          MediaLocalTables.syncQueue,
          {
            'status': SyncQueueStatus.failed.name,
            'retry_count': item.retryCount + 1,
            'last_error': e.toString(),
          },
          where: 'id = ?',
          whereArgs: [item.id],
        );
        failed++;
      }
    }

    final remaining = await db.query(
      MediaLocalTables.syncQueue,
      where: 'status IN (?, ?)',
      whereArgs: [
        SyncQueueStatus.pending.name,
        SyncQueueStatus.failed.name,
      ],
    );

    return SyncRunResult(
      processed: processed,
      failed: failed,
      pending: remaining.length,
    );
  }

  Future<SyncStatusSnapshot> getStatus() async {
    await ensureQueueTable();
    final db = await _databaseProvider();
    final rows = await db.query(MediaLocalTables.syncQueue);
    var pending = 0;
    var failed = 0;
    var completed = 0;

    for (final row in rows) {
      final status = row['status'] as String;
      switch (status) {
        case 'pending':
        case 'processing':
          pending++;
        case 'failed':
          failed++;
        case 'completed':
          completed++;
      }
    }

    return SyncStatusSnapshot(
      pendingCount: pending,
      failedCount: failed,
      completedCount: completed,
      isSyncing: pending > 0,
      lastUpdated: DateTime.now(),
      city: LubumbashiBrandingService.city,
    );
  }

  Stream<SyncStatusSnapshot> watchStatus() async* {
    yield await getStatus();
  }
}

class SyncStatusSnapshot {
  const SyncStatusSnapshot({
    required this.pendingCount,
    required this.failedCount,
    required this.completedCount,
    required this.isSyncing,
    required this.lastUpdated,
    required this.city,
  });

  final int pendingCount;
  final int failedCount;
  final int completedCount;
  final bool isSyncing;
  final DateTime lastUpdated;
  final String city;

  bool get hasErrors => failedCount > 0;
  bool get isIdle => pendingCount == 0 && !isSyncing;
}
