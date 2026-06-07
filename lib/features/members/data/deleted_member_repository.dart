import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../app/constants.dart';
import '../../../shared/models/deleted_member_record.dart';
import '../../../shared/models/member_delete_request.dart';
import '../../../core/database/database_helper.dart';

/// Repository SQLite pour la corbeille et les demandes de suppression.
class DeletedMemberRepository {
  DeletedMemberRepository({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  Future<void> insertDeleted(DeletedMemberRecord record) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      AppConstants.tableDeletedMembers,
      record.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DeletedMemberRecord>> listDeleted({String? departmentId}) async {
    final db = await DatabaseHelper.instance.database;
    var where = '1=1';
    final args = <Object?>[];
    if (departmentId != null) {
      where += ' AND department_id = ?';
      args.add(departmentId);
    }
    final rows = await db.query(
      AppConstants.tableDeletedMembers,
      where: where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'deleted_at DESC',
    );
    return rows.map(DeletedMemberRecord.fromSqlite).toList();
  }

  Future<DeletedMemberRecord?> getByMemberId(String memberId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      AppConstants.tableDeletedMembers,
      where: 'member_id = ?',
      whereArgs: [memberId],
      orderBy: 'deleted_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DeletedMemberRecord.fromSqlite(rows.first);
  }

  Future<void> markSynced(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      AppConstants.tableDeletedMembers,
      {'synced_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> removeByMemberId(String memberId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      AppConstants.tableDeletedMembers,
      where: 'member_id = ?',
      whereArgs: [memberId],
    );
  }

  Future<String> insertDeleteRequest(MemberDeleteRequest request) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      AppConstants.tableMemberDeleteRequests,
      request.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return request.id;
  }

  Future<List<MemberDeleteRequest>> listPendingRequests() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      AppConstants.tableMemberDeleteRequests,
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at DESC',
    );
    return rows.map(MemberDeleteRequest.fromSqlite).toList();
  }

  Future<List<MemberDeleteRequest>> listAllRequests() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      AppConstants.tableMemberDeleteRequests,
      orderBy: 'created_at DESC',
    );
    return rows.map(MemberDeleteRequest.fromSqlite).toList();
  }

  Future<void> updateRequestStatus({
    required String id,
    required String status,
    String? approvedBy,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      AppConstants.tableMemberDeleteRequests,
      {
        'status': status,
        'approved_by': approvedBy,
        'approved_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> insertRestoreLog({
    required String memberId,
    required String restoredBy,
    String? reason,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().toIso8601String();
    await db.insert(AppConstants.tableMemberRestoreLogs, {
      'id': _uuid.v4(),
      'member_id': memberId,
      'restored_by': restoredBy,
      'restored_at': now,
      'reason': reason,
      'city': AppConstants.city,
    });
  }

  Future<List<Map<String, Object?>>> listRestoreLogs() async {
    final db = await DatabaseHelper.instance.database;
    return db.query(
      AppConstants.tableMemberRestoreLogs,
      orderBy: 'restored_at DESC',
    );
  }
}
