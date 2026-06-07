import '../../../shared/models/ifcm_member_record.dart';
import '../../../features/members/data/local_member_repository.dart';
import '../../smart/planning/smart_media_team_planner.dart';
import '../../smart/prediction/attendance_risk_predictor.dart';
import '../../smart/score/member_media_score_engine.dart';
import '../models/advanced_models.dart';

/// Propose un remplaçant pour un membre absent ou à risque.
class SmartReplacementEngine {
  SmartReplacementEngine({
    LocalMemberRepository? repo,
    AttendanceRiskPredictor? risks,
    MemberMediaScoreEngine? scorer,
    SmartMediaTeamPlanner? planner,
  })  : _repo = repo ?? LocalMemberRepository(),
        _risks = risks ?? AttendanceRiskPredictor(),
        _scorer = scorer ?? MemberMediaScoreEngine(),
        _planner = planner ?? SmartMediaTeamPlanner();

  final LocalMemberRepository _repo;
  final AttendanceRiskPredictor _risks;
  final MemberMediaScoreEngine _scorer;
  final SmartMediaTeamPlanner _planner;

  Future<List<ReplacementSuggestion>> suggestForSunday() async {
    final plan = await _planner.generate();
    final riskMembers = await _risks.analyze();
    final active = await _repo.listActive();
    final suggestions = <ReplacementSuggestion>[];

    for (final post in plan.posts) {
      if (post.assignedMemberId == null) continue;
      final assigned = post.assignedMemberName ?? 'Membre';
      final atRisk = riskMembers.any(
        (r) => r.memberId == post.assignedMemberId && r.riskLevel >= 60,
      );
      if (!atRisk) continue;

      final replacement = _pickReplacement(
        active,
        excludeId: post.assignedMemberId!,
        usedIds: plan.posts
            .map((p) => p.assignedMemberId)
            .whereType<String>()
            .toSet(),
      );
      if (replacement != null) {
        suggestions.add(ReplacementSuggestion(
          postLabel: post.label,
          absentMemberName: assigned,
          suggestedMemberId: replacement.id,
          suggestedMemberName: replacement.displayName,
          confidence: _scorer.scoreMember(replacement).score,
        ));
      }
    }
    return suggestions;
  }

  IfcmMemberRecord? _pickReplacement(
    List<IfcmMemberRecord> candidates, {
    required String excludeId,
    required Set<String> usedIds,
  }) {
    IfcmMemberRecord? best;
    var bestScore = 0;
    for (final m in candidates) {
      if (m.id == excludeId || usedIds.contains(m.id)) continue;
      final sc = _scorer.scoreMember(m).score;
      if (sc > bestScore) {
        bestScore = sc;
        best = m;
      }
    }
    return best;
  }
}
