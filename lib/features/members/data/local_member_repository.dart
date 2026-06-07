import 'package:sqflite/sqflite.dart';

import '../../../app/constants.dart';
import '../../../shared/models/ifcm_member_record.dart';
import '../../../core/database/database_helper.dart';

/// SQLite repository for IFCM members (offline-first).
class LocalMemberRepository {
  Future<IfcmMemberRecord> insert(IfcmMemberRecord member) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      AppConstants.tableMembers,
      member.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return member;
  }

  Future<void> upsert(IfcmMemberRecord member) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      AppConstants.tableMembers,
      member.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<IfcmMemberRecord?> getById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      AppConstants.tableMembers,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return IfcmMemberRecord.fromSqlite(rows.first);
  }

  Future<IfcmMemberRecord?> findByQrData(String qrData) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      AppConstants.tableMembers,
      where: 'qr_data = ? OR member_code = ?',
      whereArgs: [qrData, qrData],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return IfcmMemberRecord.fromSqlite(rows.first);
  }

  Future<List<IfcmMemberRecord>> listActive({
    String? departmentId,
    String? syncStatus,
  }) async {
    final db = await DatabaseHelper.instance.database;
    var where = 'is_deleted = 0 AND is_active = 1 AND (is_merged = 0 OR is_merged IS NULL)';
    final args = <Object?>[];
    if (departmentId != null) {
      where += ' AND department_id = ?';
      args.add(departmentId);
    }
    if (syncStatus != null) {
      where += ' AND sync_status = ?';
      args.add(syncStatus);
    }
    final rows = await db.query(
      AppConstants.tableMembers,
      where: where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'updated_at DESC',
    );
    return rows.map(IfcmMemberRecord.fromSqlite).toList();
  }

  Future<int> countBySyncStatus(String status) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as c FROM ${AppConstants.tableMembers} '
      'WHERE sync_status = ? AND is_deleted = 0',
      [status],
    );
    return result.first['c'] as int? ?? 0;
  }

  Future<List<IfcmMemberRecord>> listDeleted() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      AppConstants.tableMembers,
      where: 'is_deleted = 1',
      orderBy: 'deleted_at DESC',
    );
    return rows.map(IfcmMemberRecord.fromSqlite).toList();
  }

  Future<void> updateSyncStatus(
    String id, {
    required String syncStatus,
    String? cloudId,
    String? qrData,
    DateTime? syncedAt,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      AppConstants.tableMembers,
      {
        'sync_status': syncStatus,
        if (cloudId != null) 'cloud_id': cloudId,
        if (qrData != null) 'qr_data': qrData,
        'synced_at': (syncedAt ?? DateTime.now()).toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
