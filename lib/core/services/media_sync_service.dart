import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';

import '../sync/sync_manager.dart';
import 'lubumbashi_branding_service.dart';
import 'media_firestore_constants.dart';

/// Syncs local SQLite media data with Firestore (bidirectional, Lubumbashi).
class MediaSyncService {
  MediaSyncService({
    required Future<Database> Function() databaseProvider,
    FirebaseFirestore? firestore,
    SyncManager? syncManager,
  })  : _databaseProvider = databaseProvider,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _syncManager = syncManager;

  final Future<Database> Function() _databaseProvider;
  final FirebaseFirestore _firestore;
  SyncManager? _syncManager;

  SyncManager get syncManager => _syncManager ??= SyncManager(
        databaseProvider: _databaseProvider,
        firestore: _firestore,
      );

  Future<void> ensureSchema() async {
    final db = await _databaseProvider();
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${MediaLocalTables.attendance} (
        id TEXT PRIMARY KEY,
        payload_json TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        city TEXT NOT NULL DEFAULT 'Lubumbashi'
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${MediaLocalTables.lists} (
        id TEXT PRIMARY KEY,
        payload_json TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        city TEXT NOT NULL DEFAULT 'Lubumbashi'
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${MediaLocalTables.members} (
        id TEXT PRIMARY KEY,
        payload_json TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        city TEXT NOT NULL DEFAULT 'Lubumbashi'
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${MediaLocalTables.roles} (
        id TEXT PRIMARY KEY,
        payload_json TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        city TEXT NOT NULL DEFAULT 'Lubumbashi'
      )
    ''');
    await syncManager.ensureQueueTable();
  }

  Future<void> pushLocalToFirestore() async {
    await ensureSchema();
    final db = await _databaseProvider();
    await _pushTable(
      db: db,
      table: MediaLocalTables.attendance,
      collection: MediaFirestoreCollections.attendance,
    );
    await _pushTable(
      db: db,
      table: MediaLocalTables.lists,
      collection: MediaFirestoreCollections.lists,
    );
    await _pushTable(
      db: db,
      table: MediaLocalTables.members,
      collection: MediaFirestoreCollections.members,
    );
    await _pushTable(
      db: db,
      table: MediaLocalTables.roles,
      collection: MediaFirestoreCollections.roles,
    );
    await syncManager.flushQueue();
  }

  Future<void> pullFirestoreToLocal() async {
    await ensureSchema();
    final db = await _databaseProvider();
    await _pullCollection(
      db: db,
      table: MediaLocalTables.attendance,
      collection: MediaFirestoreCollections.attendance,
    );
    await _pullCollection(
      db: db,
      table: MediaLocalTables.lists,
      collection: MediaFirestoreCollections.lists,
    );
    await _pullCollection(
      db: db,
      table: MediaLocalTables.members,
      collection: MediaFirestoreCollections.members,
    );
    await _pullCollection(
      db: db,
      table: MediaLocalTables.roles,
      collection: MediaFirestoreCollections.roles,
    );
  }

  Future<SyncRunResult> fullSync() async {
    await pullFirestoreToLocal();
    await pushLocalToFirestore();
    return syncManager.flushQueue();
  }

  Future<void> saveLocalRecord({
    required String table,
    required String id,
    required Map<String, dynamic> payload,
  }) async {
    await ensureSchema();
    final db = await _databaseProvider();
    final branded = Map<String, dynamic>.from(payload);
    branded['city'] = LubumbashiBrandingService.city;

    await db.insert(
      table,
      {
        'id': id,
        'payload_json': jsonEncode(branded),
        'updated_at': DateTime.now().toIso8601String(),
        'synced': 0,
        'city': LubumbashiBrandingService.city,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await syncManager.enqueue(
      collection: _collectionForTable(table),
      documentId: id,
      operation: SyncOperation.upsert,
      payload: branded,
    );
  }

  String _collectionForTable(String table) {
    switch (table) {
      case MediaLocalTables.attendance:
        return MediaFirestoreCollections.attendance;
      case MediaLocalTables.lists:
        return MediaFirestoreCollections.lists;
      case MediaLocalTables.members:
        return MediaFirestoreCollections.members;
      case MediaLocalTables.roles:
        return MediaFirestoreCollections.roles;
      default:
        throw ArgumentError('Table inconnue: $table');
    }
  }

  Future<void> _pushTable({
    required Database db,
    required String table,
    required String collection,
  }) async {
    final rows = await db.query(table, where: 'synced = ?', whereArgs: [0]);
    for (final row in rows) {
      final id = row['id'] as String;
      final payload = jsonDecode(row['payload_json'] as String) as Map<String, dynamic>;
      await _firestore.collection(collection).doc(id).set(payload, SetOptions(merge: true));
      await db.update(table, {'synced': 1}, where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<void> _pullCollection({
    required Database db,
    required String table,
    required String collection,
  }) async {
    final snap = await _firestore
        .collection(collection)
        .where('city', isEqualTo: LubumbashiBrandingService.city)
        .get();

    for (final doc in snap.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      await db.insert(
        table,
        {
          'id': doc.id,
          'payload_json': jsonEncode(data),
          'updated_at': DateTime.now().toIso8601String(),
          'synced': 1,
          'city': LubumbashiBrandingService.city,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
}
