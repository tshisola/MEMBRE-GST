import '../../../app/constants.dart';
import '../../database/database_helper.dart';
import '../../../features/members/data/local_member_repository.dart';
import '../../../shared/models/ifcm_member_record.dart';
import '../models/smart_models.dart';

/// Prédit les membres à risque de retard ou d'absence.
class AttendanceRiskPredictor {
  AttendanceRiskPredictor({LocalMemberRepository? repo})
      : _repo = repo ?? LocalMemberRepository();

  final LocalMemberRepository _repo;

  Future<List<AttendanceRiskMember>> analyze() async {
    final active = await _repo.listActive();
    final risks = <AttendanceRiskMember>[];

    for (final m in active) {
      final stats = await _loadStats(m.id);
      if (stats.lateCount >= 2) {
        risks.add(AttendanceRiskMember(
          memberId: m.id,
          name: m.displayName,
          riskLevel: (stats.lateCount * 20).clamp(20, 90),
          reason: '${stats.lateCount} retard(s) récent(s)',
          riskType: 'retard',
        ));
      }
      if (stats.absentCount >= 2) {
        risks.add(AttendanceRiskMember(
          memberId: m.id,
          name: m.displayName,
          riskLevel: (stats.absentCount * 25).clamp(25, 95),
          reason: '${stats.absentCount} absence(s) récente(s)',
          riskType: 'absence',
        ));
      }
    }

    risks.sort((a, b) => b.riskLevel.compareTo(a.riskLevel));
    return risks;
  }

  Future<({int lateCount, int absentCount})> _loadStats(String memberId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final late = await db.rawQuery(
        'SELECT COUNT(*) as c FROM ${AppConstants.tableMediaAttendance} '
        'WHERE member_id = ? AND status = ?',
        [memberId, 'late'],
      );
      final absent = await db.rawQuery(
        'SELECT COUNT(*) as c FROM ${AppConstants.tableMediaAttendance} '
        'WHERE member_id = ? AND status = ?',
        [memberId, 'absent'],
      );
      return (
        lateCount: late.first['c'] as int? ?? 0,
        absentCount: absent.first['c'] as int? ?? 0,
      );
    } catch (_) {
      return (lateCount: 0, absentCount: 0);
    }
  }
}

typedef LateRiskDetector = AttendanceRiskPredictor;
typedef AbsenceRiskDetector = AttendanceRiskPredictor;

/// Suggestions de remplacement.
class ReplacementSuggestionService {
  ReplacementSuggestionService({LocalMemberRepository? repo})
      : _repo = repo ?? LocalMemberRepository();

  final LocalMemberRepository _repo;

  Future<List<IfcmMemberRecord>> suggestFor(String memberId) async {
    final target = await _repo.getById(memberId);
    if (target == null) return [];
    final active = await _repo.listActive();
    return active
        .where((m) =>
            m.id != memberId &&
            m.departmentId == target.departmentId &&
            !m.isDeleted)
        .take(5)
        .toList();
  }
}
