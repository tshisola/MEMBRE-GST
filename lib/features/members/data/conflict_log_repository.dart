import 'dart:convert';

import '../../../app/constants.dart';
import '../../../shared/models/ifcm_member_record.dart';
import '../../../shared/models/sync_conflict_record.dart';
import '../../../core/database/database_helper.dart';

/// Reads and updates sync conflict logs in SQLite.
class ConflictLogRepository {
  Future<List<SyncConflictRecord>> listAll({bool? unresolvedOnly}) async {
    final db = await DatabaseHelper.instance.database;
    var where = '1=1';
    final args = <Object?>[];
    if (unresolvedOnly == true) {
      where = 'resolved = 0';
    } else if (unresolvedOnly == false) {
      where = 'resolved = 1';
    }

    final rows = await db.query(
      AppConstants.tableSyncConflicts,
      where: where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'created_at DESC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<int> countUnresolved() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as c FROM ${AppConstants.tableSyncConflicts} WHERE resolved = 0',
    );
    return result.first['c'] as int? ?? 0;
  }

  Future<SyncConflictRecord?> getById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      AppConstants.tableSyncConflicts,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  Future<void> markResolved(String conflictId) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      AppConstants.tableSyncConflicts,
      {'resolved': 1},
      where: 'id = ?',
      whereArgs: [conflictId],
    );
  }

  SyncConflictRecord _fromRow(Map<String, Object?> row) {
    IfcmMemberRecord? parseJson(String? raw, String docId) {
      if (raw == null || raw.isEmpty) return null;
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        return IfcmMemberRecord.fromFirestore(
          map['localId'] as String? ?? docId,
          map,
        );
      } catch (_) {
        return null;
      }
    }

    final memberId = row['member_id'] as String;
    return SyncConflictRecord(
      id: row['id'] as String,
      memberId: memberId,
      local: parseJson(row['local_json'] as String?, memberId),
      remote: parseJson(row['remote_json'] as String?, memberId),
      resolved: (row['resolved'] as int? ?? 0) == 1,
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
