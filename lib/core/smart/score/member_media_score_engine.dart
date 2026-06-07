import '../../../app/constants.dart';
import '../../database/database_helper.dart';
import '../../../features/members/data/local_member_repository.dart';
import '../../../shared/models/ifcm_member_record.dart';
import '../models/smart_models.dart';

/// Calcule le Score Média pour chaque membre.
class MemberMediaScoreEngine {
  MemberMediaScoreEngine({LocalMemberRepository? repo})
      : _repo = repo ?? LocalMemberRepository();

  final LocalMemberRepository _repo;

  Future<MemberMediaScore> scoreFor(String memberId) async {
    final member = await _repo.getById(memberId);
    if (member == null) {
      return MemberMediaScore(
        memberId: memberId,
        score: 0,
        badge: MemberScoreBadge.inactive,
        factors: const {},
      );
    }
    return scoreMember(member);
  }

  Future<List<MemberMediaScore>> scoreAll() async {
    final active = await _repo.listActive();
    return active.map(scoreMember).toList();
  }

  MemberMediaScore scoreMember(IfcmMemberRecord m) {
    final factors = <String, int>{};
    var total = 50;

    if (m.isActive && !m.isDeleted) {
      factors['Actif'] = 15;
      total += 15;
    } else {
      factors['Inactif'] = -30;
      total -= 30;
    }

    if (m.qrData.isNotEmpty) {
      factors['QR Code'] = 10;
      total += 10;
    } else {
      factors['Sans QR'] = -10;
      total -= 10;
    }

    if (m.phone != null && m.phone!.trim().isNotEmpty) {
      factors['Téléphone'] = 5;
      total += 5;
    }

    if (m.departmentId == AppConstants.mediaDepartmentId ||
        (m.departmentName?.toLowerCase().contains('media') ?? false) ||
        (m.departmentName?.toLowerCase().contains('média') ?? false)) {
      factors['Département Média'] = 10;
      total += 10;
    }

    if (m.syncStatus == AppConstants.syncStatusSynced) {
      factors['Synchronisé'] = 10;
      total += 10;
    } else if (m.syncStatus == AppConstants.syncStatusPending ||
        m.syncStatus == AppConstants.syncStatusLocal) {
      factors['Sync en attente'] = 0;
    }

    final created = m.createdAt;
    if (created != null &&
        DateTime.now().difference(created).inDays < 30) {
      factors['Nouveau membre'] = 5;
      total += 5;
    }

    if (m.role != 'member' && m.role.isNotEmpty) {
      factors['Rôle attribué'] = 10;
      total += 10;
    }

    final score = total.clamp(0, 100);
    return MemberMediaScore(
      memberId: m.id,
      score: score,
      badge: _badgeFor(score, m),
      factors: factors,
    );
  }

  MemberScoreBadge _badgeFor(int score, IfcmMemberRecord m) {
    if (!m.isActive || m.isDeleted) return MemberScoreBadge.inactive;
    final created = m.createdAt;
    if (created != null && DateTime.now().difference(created).inDays < 14) {
      return MemberScoreBadge.newMember;
    }
    if (score >= 85) return MemberScoreBadge.excellent;
    if (score >= 65) return MemberScoreBadge.regular;
    return MemberScoreBadge.watch;
  }
}

typedef MemberScoreHistory = MemberMediaScoreEngine;
typedef MemberScoreBadgeWidget = MemberMediaScore;

/// Historique présence pour enrichir le score (async).
extension MemberMediaScoreAttendance on MemberMediaScoreEngine {
  Future<int> attendanceBonus(String memberId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.rawQuery(
        'SELECT COUNT(*) as c FROM ${AppConstants.tableMediaAttendance} '
        'WHERE member_id = ? AND status = ?',
        [memberId, 'present'],
      );
      final presents = rows.first['c'] as int? ?? 0;
      return (presents * 2).clamp(0, 20);
    } catch (_) {
      return 0;
    }
  }
}
