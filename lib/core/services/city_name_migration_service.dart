import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';

import 'lubumbashi_branding_service.dart';
import 'media_firestore_constants.dart';

/// Migrates legacy Kinshasa city references to Lubumbashi in local DB and Firestore.
class CityNameMigrationService {
  CityNameMigrationService({
    FirebaseFirestore? firestore,
    Future<Database> Function()? databaseProvider,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _databaseProvider = databaseProvider;

  final FirebaseFirestore _firestore;
  final Future<Database> Function()? _databaseProvider;

  static const List<String> _cityFields = ['city', 'commune', 'location', 'address'];

  /// Returns true if [value] contains a Kinshasa reference.
  bool needsMigration(String? value) {
    if (value == null || value.isEmpty) return false;
    return RegExp('kinshasa', caseSensitive: false).hasMatch(value);
  }

  /// Migrates all configured Firestore media collections.
  Future<CityMigrationReport> migrateFirestore({
    int batchSize = 100,
  }) async {
    final report = CityMigrationReport();
    final collections = [
      MediaFirestoreCollections.attendance,
      MediaFirestoreCollections.lists,
      MediaFirestoreCollections.roles,
      MediaFirestoreCollections.members,
      'members',
      'users',
    ];

    for (final collection in collections) {
      final updated = await _migrateCollection(
        collection: collection,
        batchSize: batchSize,
      );
      report.collectionCounts[collection] = updated;
      report.totalDocumentsUpdated += updated;
    }
    return report;
  }

  Future<int> _migrateCollection({
    required String collection,
    required int batchSize,
  }) async {
    var updated = 0;
    Query<Map<String, dynamic>> query =
        _firestore.collection(collection).limit(batchSize);
    DocumentSnapshot<Map<String, dynamic>>? lastDoc;

    while (true) {
      if (lastDoc != null) {
        query = _firestore
            .collection(collection)
            .limit(batchSize)
            .startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) break;

      final batch = _firestore.batch();
      var batchCount = 0;

      for (final doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        final patched = _patchDocument(data);
        if (patched != null) {
          batch.set(doc.reference, patched, SetOptions(merge: true));
          batchCount++;
        }
        lastDoc = doc;
      }

      if (batchCount > 0) {
        await batch.commit();
        updated += batchCount;
      }

      if (snapshot.docs.length < batchSize) break;
    }

    return updated;
  }

  Map<String, dynamic>? _patchDocument(Map<String, dynamic> data) {
    var changed = false;
    final result = Map<String, dynamic>.from(data);

    for (final field in _cityFields) {
      final value = result[field];
      if (value is String && needsMigration(value)) {
        result[field] = LubumbashiBrandingService.applyBranding(value);
        changed = true;
      }
    }

    _walkNestedMaps(result, (map, key, value) {
      if (value is String && needsMigration(value)) {
        map[key] = LubumbashiBrandingService.applyBranding(value);
        return true;
      }
      return false;
    });

    if (!changed) return null;
    result['migratedToLubumbashi'] = true;
    result['migratedAt'] = FieldValue.serverTimestamp();
    return result;
  }

  void _walkNestedMaps(
    Map<String, dynamic> root,
    bool Function(Map<String, dynamic> map, String key, dynamic value) visitor,
  ) {
    for (final entry in root.entries.toList()) {
      if (entry.value is Map) {
        final nested = Map<String, dynamic>.from(entry.value as Map);
        _walkNestedMaps(nested, visitor);
        root[entry.key] = nested;
      } else if (entry.value is List) {
        final list = entry.value as List;
        for (var i = 0; i < list.length; i++) {
          if (list[i] is Map) {
            final nested = Map<String, dynamic>.from(list[i] as Map);
            _walkNestedMaps(nested, visitor);
            list[i] = nested;
          } else if (visitor(root, entry.key, list[i])) {
            // handled inline for list strings if needed
          }
        }
      } else {
        visitor(root, entry.key, entry.value);
      }
    }
  }

  /// Migrates SQLite tables used by media sync.
  Future<int> migrateLocalDatabase(Database db) async {
    var total = 0;
    final tables = [
      MediaLocalTables.attendance,
      MediaLocalTables.lists,
      MediaLocalTables.members,
      MediaLocalTables.roles,
    ];

    for (final table in tables) {
      final exists = await _tableExists(db, table);
      if (!exists) continue;

      final rows = await db.query(table);
      for (final row in rows) {
        final id = row['id'];
        if (id == null) continue;

        final payload = Map<String, dynamic>.from(row);
        var changed = false;

        for (final field in _cityFields) {
          final value = payload[field];
          if (value is String && needsMigration(value)) {
            payload[field] = LubumbashiBrandingService.applyBranding(value);
            changed = true;
          }
        }

        final jsonField = payload['payload_json'] as String?;
        if (jsonField != null && needsMigration(jsonField)) {
          payload['payload_json'] =
              LubumbashiBrandingService.applyBranding(jsonField);
          changed = true;
        }

        if (changed) {
          await db.update(table, payload, where: 'id = ?', whereArgs: [id]);
          total++;
        }
      }
    }
    return total;
  }

  Future<int> runFullMigration({Database? localDb}) async {
    final firestoreReport = await migrateFirestore();
    var localCount = 0;
    if (localDb != null) {
      localCount = await migrateLocalDatabase(localDb);
    } else if (_databaseProvider != null) {
      final db = await _databaseProvider!();
      localCount = await migrateLocalDatabase(db);
    }
    return firestoreReport.totalDocumentsUpdated + localCount;
  }

  Future<bool> _tableExists(Database db, String table) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [table],
    );
    return result.isNotEmpty;
  }
}

class CityMigrationReport {
  final Map<String, int> collectionCounts = {};
  int totalDocumentsUpdated = 0;
}
