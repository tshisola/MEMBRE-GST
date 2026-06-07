import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';

import '../../app/constants.dart';
import '../database/database_helper.dart';
import '../firebase/firebase_initializer.dart';

/// Recalcule et synchronise le pourcentage hebdomadaire après pointage.
class WeeklyPercentageUpdater {
  WeeklyPercentageUpdater({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<double> updateForMember(String memberId) async {
    final stats = await _computeLocal(memberId);
    if (FirebaseInitializer.isInitialized) {
      await _syncWeeklyResult(
        memberId: memberId,
        percent: stats.percent,
        sessions: stats.sessions,
        present: stats.present,
      );
    }
    return stats.percent;
  }

  Future<({double percent, int sessions, int present})> _computeLocal(
    String memberId,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final weekStartStr = weekStart.toIso8601String().substring(0, 10);

    final rows = await db.query(
      AppConstants.tableMediaAttendance,
      where: 'member_id = ? AND session_date >= ?',
      whereArgs: [memberId, weekStartStr],
    );

    if (rows.isEmpty) {
      return (percent: 0.0, sessions: 0, present: 0);
    }

    final present = rows.where((r) {
      final status = (r['status'] as String? ?? '').toLowerCase();
      return status.contains('present') || status.contains('late');
    }).length;

    final percent = (present / rows.length * 100).clamp(0, 100).toDouble();
    return (percent: percent, sessions: rows.length, present: present);
  }

  Future<void> _syncWeeklyResult({
    required String memberId,
    required double percent,
    required int sessions,
    required int present,
  }) async {
    try {
      final weekKey = _weekKey(DateTime.now());
      await _firestore
          .collection(AppConstants.collectionWeeklyResults)
          .doc('${memberId}_$weekKey')
          .set(
        {
          'memberId': memberId,
          'weekKey': weekKey,
          'percentage': percent,
          'sessions': sessions,
          'presentCount': present,
          'isEligible': percent >= 50,
          'city': AppConstants.city,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  String _weekKey(DateTime d) {
    final start = d.subtract(Duration(days: d.weekday - 1));
    return '${start.year}${start.month.toString().padLeft(2, '0')}${start.day.toString().padLeft(2, '0')}';
  }
}

/// Alias demandés.
typedef WeeklyPercentageCalculator = WeeklyPercentageUpdater;
typedef MemberPercentageUpdater = WeeklyPercentageUpdater;
typedef WeeklyResultSyncService = WeeklyPercentageUpdater;
typedef MemberRealtimePercentageListener = WeeklyPercentageUpdater;
typedef MemberDashboardUpdater = WeeklyPercentageUpdater;
