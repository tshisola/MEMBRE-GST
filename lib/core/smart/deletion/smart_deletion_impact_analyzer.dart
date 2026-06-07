import '../../../app/constants.dart';
import '../../database/database_helper.dart';
import '../../../features/members/data/local_member_repository.dart';
import '../models/smart_models.dart';

/// Analyse l'impact avant suppression d'un membre.
class SmartDeletionImpactAnalyzer {
  SmartDeletionImpactAnalyzer({LocalMemberRepository? repo})
      : _repo = repo ?? LocalMemberRepository();

  final LocalMemberRepository _repo;

  Future<DeletionImpactReport> analyze(String memberId) async {
    final member = await _repo.getById(memberId);
    if (member == null) {
      return DeletionImpactReport(
        memberId: memberId,
        memberName: 'Membre',
        attendanceRecords: 0,
        listAppearances: 0,
        hasQr: false,
        syncStatus: 'unknown',
        warnings: const ['Membre introuvable.'],
        impactLevel: 'Faible',
      );
    }

    final attendance = await _countAttendance(memberId);
    final lists = await _countListAppearances(member.displayName);
    final warnings = <String>[];

    if (attendance > 0) {
      warnings.add('$attendance enregistrement(s) de présence conservé(s).');
    }
    if (lists > 0) {
      warnings.add('Apparaît dans $lists liste(s) active(s).');
    }
    if (member.qrData.isNotEmpty) {
      warnings.add('QR Code associé — sera désactivé.');
    }
    if (member.syncStatus == AppConstants.syncStatusPending ||
        member.syncStatus == AppConstants.syncStatusLocal) {
      warnings.add('Synchronisation en attente — suppression locale prioritaire.');
    }

    final impact = _impactLevel(attendance, lists, member);

    return DeletionImpactReport(
      memberId: memberId,
      memberName: member.displayName,
      attendanceRecords: attendance,
      listAppearances: lists,
      hasQr: member.qrData.isNotEmpty,
      syncStatus: member.syncStatus,
      warnings: warnings.isEmpty
          ? const ['Impact limité — restauration possible depuis la corbeille.']
          : warnings,
      impactLevel: impact,
    );
  }

  String _impactLevel(int attendance, int lists, dynamic member) {
    var score = 0;
    score += attendance > 5 ? 3 : (attendance > 0 ? 1 : 0);
    score += lists > 2 ? 2 : (lists > 0 ? 1 : 0);
    if (score >= 4) return 'Élevé';
    if (score >= 2) return 'Modéré';
    return 'Faible';
  }

  Future<int> _countAttendance(String memberId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final r = await db.rawQuery(
        'SELECT COUNT(*) as c FROM ${AppConstants.tableMediaAttendance} WHERE member_id = ?',
        [memberId],
      );
      return r.first['c'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _countListAppearances(String name) async {
    try {
      final db = await DatabaseHelper.instance.database;
      var count = 0;
      final mediaLists = await db.query(AppConstants.tableMediaLists);
      for (final _ in mediaLists) {
        count += 0;
      }
      final deptEntries = await db.rawQuery(
        'SELECT COUNT(*) as c FROM ${AppConstants.tableDepartmentManualListEntries} '
        'WHERE member_name LIKE ?',
        ['%$name%'],
      );
      count += deptEntries.first['c'] as int? ?? 0;
      return count;
    } catch (_) {
      return 0;
    }
  }
}

typedef SafeDeleteMemberFlow = SmartDeletionImpactAnalyzer;
typedef DeleteImpactPreviewCard = DeletionImpactReport;
