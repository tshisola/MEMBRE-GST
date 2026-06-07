import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../app/constants.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/members/weekly_percentage_updater.dart';
import '../../../core/sync/attendance_sync_service.dart';
import '../../../shared/models/attendance_model.dart';

/// Persistance locale du pointage Média (offline-first).
class MediaAttendanceLocalRepository {
  MediaAttendanceLocalRepository({
    Uuid? uuid,
    AttendanceSyncService? syncService,
  })  : _uuid = uuid ?? const Uuid(),
        _sync = syncService ?? AttendanceSyncService();

  final Uuid _uuid;
  final AttendanceSyncService _sync;

  Future<Map<String, MediaAttendanceStatus>> loadForSession({
    required DateTime date,
    required MediaSessionType sessionType,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final dateStr = _dateKey(date);
    final rows = await db.query(
      AppConstants.tableMediaAttendance,
      where: 'session_date = ? AND session_type = ?',
      whereArgs: [dateStr, sessionType.name],
    );
    final map = <String, MediaAttendanceStatus>{};
    for (final row in rows) {
      final memberId = row['member_id'] as String;
      map[memberId] = MediaAttendanceStatus.fromString(
        row['status'] as String? ?? 'absent',
      );
    }
    return map;
  }

  Future<Map<String, String>> loadArrivalTimes({
    required DateTime date,
    required MediaSessionType sessionType,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final dateStr = _dateKey(date);
    final rows = await db.query(
      AppConstants.tableMediaAttendance,
      where: 'session_date = ? AND session_type = ?',
      whereArgs: [dateStr, sessionType.name],
    );
    final map = <String, String>{};
    for (final row in rows) {
      final memberId = row['member_id'] as String;
      final updated = row['updated_at'] as String?;
      if (updated != null) map[memberId] = updated;
    }
    return map;
  }

  Future<void> saveSession({
    required DateTime date,
    required MediaSessionType sessionType,
    required Map<String, MediaAttendanceStatus> attendance,
    String? operatorId,
    bool enqueueSync = true,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final dateStr = _dateKey(date);
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final syncPayloads = <Map<String, dynamic>>[];

    await db.transaction((txn) async {
      for (final entry in attendance.entries) {
        final existing = await txn.query(
          AppConstants.tableMediaAttendance,
          where: 'member_id = ? AND session_date = ? AND session_type = ?',
          whereArgs: [entry.key, dateStr, sessionType.name],
          limit: 1,
        );

        final recordId = existing.isEmpty
            ? _uuid.v4()
            : existing.first['id'] as String;

        if (existing.isEmpty) {
          await txn.insert(
            AppConstants.tableMediaAttendance,
            {
              'id': recordId,
              'member_id': entry.key,
              'session_date': dateStr,
              'session_type': sessionType.name,
              'status': entry.value.name,
              'operator_id': operatorId,
              'department_id': AppConstants.mediaDepartmentId,
              'city': AppConstants.city,
              'created_at': nowIso,
              'updated_at': nowIso,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } else {
          await txn.update(
            AppConstants.tableMediaAttendance,
            {
              'status': entry.value.name,
              'operator_id': operatorId,
              'updated_at': nowIso,
            },
            where: 'id = ?',
            whereArgs: [recordId],
          );
        }

        syncPayloads.add({
          'id': recordId,
          'memberId': entry.key,
          'date': date.toIso8601String(),
          'sessionDate': dateStr,
          'sessionType': sessionType.name,
          'status': entry.value.name,
          'recordedBy': operatorId,
          'departmentId': AppConstants.mediaDepartmentId,
          'city': AppConstants.city,
          'updatedAt': nowIso,
          'syncStatus': AppConstants.syncStatusPending,
        });
      }
    });

    if (enqueueSync && syncPayloads.isNotEmpty) {
      await _sync.enqueueRecords(syncPayloads);
    }

    for (final entry in attendance.entries) {
      unawaited(WeeklyPercentageUpdater().updateForMember(entry.key));
    }
  }

  Future<void> saveSingle({
    required DateTime date,
    required MediaSessionType sessionType,
    required String memberId,
    required MediaAttendanceStatus status,
    String? operatorId,
  }) async {
    await saveSession(
      date: date,
      sessionType: sessionType,
      attendance: {memberId: status},
      operatorId: operatorId,
    );
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Alias pour la couche domaine pointage.
typedef MediaAttendanceMemberRepository = MediaAttendanceLocalRepository;
