import '../../../app/constants.dart';
import '../database/database_helper.dart';
import '../members/attendance_member_query_service.dart';
import '../../../features/members/data/local_member_repository.dart';
import '../../../shared/models/ifcm_member_record.dart';
import 'models/smart_models.dart';

/// Compare SQLite vs liste pointage pour détecter les membres invisibles.
class PointageVisibilityChecker {
  PointageVisibilityChecker({
    LocalMemberRepository? repo,
    AttendanceMemberQueryService? query,
  })  : _repo = repo ?? LocalMemberRepository(),
        _query = query ?? AttendanceMemberQueryService();

  final LocalMemberRepository _repo;
  final AttendanceMemberQueryService _query;

  Future<PointageVisibilityReport> check() async {
    final active = await _repo.listActive();
    final visible = await _query.loadForMediaPointage(mergeFirebase: false);
    final visibleIds = visible.map((m) => m.id).toSet();

    final invisible = <InvisiblePointageMember>[];
    for (final m in active) {
      if (visibleIds.contains(m.id)) continue;
      invisible.add(InvisiblePointageMember(
        memberId: m.id,
        name: m.displayName,
        reason: _reasonFor(m),
        repairable: _isRepairable(m),
      ));
    }

    return PointageVisibilityReport(
      invisibleMembers: invisible,
      visibleCount: visible.length,
      activeCount: active.length,
    );
  }

  String _reasonFor(IfcmMemberRecord m) {
    if (!m.isActive) return 'Membre inactif';
    if (m.isDeleted) return 'Membre supprimé';
    final dept = m.departmentId?.toLowerCase() ?? '';
    final deptName = m.departmentName?.toLowerCase() ?? '';
    if (dept.isNotEmpty &&
        dept != AppConstants.mediaDepartmentId &&
        !deptName.contains('media') &&
        !deptName.contains('média') &&
        m.syncStatus == AppConstants.syncStatusSynced) {
      return 'Département non Média';
    }
    if (m.qrData.isEmpty) return 'QR Code manquant';
    return 'Non éligible au pointage Média';
  }

  bool _isRepairable(IfcmMemberRecord m) {
    if (m.isDeleted || !m.isActive) return false;
    return true;
  }
}

/// Répare automatiquement les membres invisibles au pointage.
class PointageAutoRepairService {
  PointageAutoRepairService({LocalMemberRepository? repo})
      : _repo = repo ?? LocalMemberRepository();

  final LocalMemberRepository _repo;

  Future<SmartActionResult> repairAll() async {
    final checker = PointageVisibilityChecker(repo: _repo);
    final report = await checker.check();
    var fixed = 0;

    for (final inv in report.invisibleMembers) {
      if (!inv.repairable) continue;
      final member = await _repo.getById(inv.memberId);
      if (member == null) continue;
      final ok = await _repairMember(member);
      if (ok) fixed++;
    }

    return (
      success: fixed > 0 || report.invisibleMembers.isEmpty,
      message: fixed > 0
          ? '$fixed membre(s) corrigé(s) pour le pointage.'
          : 'Aucune correction nécessaire.',
      fixedCount: fixed,
    );
  }

  Future<bool> repairMember(String memberId) async {
    final member = await _repo.getById(memberId);
    if (member == null) return false;
    return _repairMember(member);
  }

  Future<bool> _repairMember(IfcmMemberRecord m) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        AppConstants.tableMembers,
        {
          'is_active': 1,
          'is_deleted': 0,
          'department_id': AppConstants.mediaDepartmentId,
          'department_name': 'Département Média',
          'sync_status': AppConstants.syncStatusPending,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [m.id],
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Rafraîchit le cache pointage (invalidation logique).
class PointageCacheRefresher {
  Future<void> refresh() async {
    await AttendanceMemberQueryService().loadForMediaPointage(
      mergeFirebase: true,
    );
  }
}

typedef PointageCacheManager = PointageCacheRefresher;
