import '../../../app/constants.dart';
import '../../database/database_helper.dart';
import '../../../features/members/data/local_member_repository.dart';
import '../../smart/checklist/media_service_checklist.dart';
import '../../smart/planning/smart_media_team_planner.dart';
import '../models/advanced_models.dart';

/// Tableau de bord live pendant une activité Média.
class LiveMediaActivityDashboard {
  LiveMediaActivityDashboard({
    LocalMemberRepository? members,
    MediaServiceChecklist? checklist,
    SmartMediaTeamPlanner? planner,
  })  : _members = members ?? LocalMemberRepository(),
        _checklist = checklist ?? MediaServiceChecklist(),
        _planner = planner ?? SmartMediaTeamPlanner();

  final LocalMemberRepository _members;
  final MediaServiceChecklist _checklist;
  final SmartMediaTeamPlanner _planner;

  Future<LiveActivitySnapshot> load() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final db = await DatabaseHelper.instance.database;
    final active = await _members.listActive();
    final rows = await db.query(
      AppConstants.tableMediaAttendance,
      where: 'session_date = ?',
      whereArgs: [today],
    );

    var arrived = 0;
    var late = 0;
    var absent = 0;
    for (final r in rows) {
      final status = (r['status'] as String? ?? '').toLowerCase();
      if (status.contains('present') || status.contains('présent')) {
        arrived++;
      } else if (status.contains('late') || status.contains('retard')) {
        late++;
        arrived++;
      } else if (status.contains('absent')) {
        absent++;
      }
    }

    final plan = await _planner.generate();
    final covered = plan.posts.where((p) => p.assignedMemberId != null).length;
    final uncovered = plan.posts.length - covered;

    final checklist = await _checklist.load();
    final prep = checklist.isEmpty
        ? 100
        : ((checklist.where((c) => c.done).length / checklist.length) * 100)
            .round();

    final alerts = <String>[];
    if (late > 0) alerts.add('$late retardataire(s) aujourd\'hui.');
    if (absent > 0) alerts.add('$absent absent(s) enregistré(s).');
    if (uncovered > 0) alerts.add('$uncovered poste(s) non couvert(s).');
    if (prep < 80) alerts.add('Préparation service : $prep %.');

    return LiveActivitySnapshot(
      expectedCount: active.length,
      arrivedCount: arrived,
      lateCount: late,
      absentCount: absent,
      coveredPosts: covered,
      uncoveredPosts: uncovered,
      prepPercent: prep,
      alerts: alerts,
    );
  }
}

class LiveAttendanceCounter {
  static String label(LiveActivitySnapshot s) =>
      '${s.arrivedCount} / ${s.expectedCount} arrivés';
}

class LiveRoleCoverageCard {
  static String coverageLabel(LiveActivitySnapshot s) =>
      '${s.coveredPosts} postes couverts · ${s.uncoveredPosts} à pourvoir';
}

class LiveAlertPanel {
  static bool hasAlerts(LiveActivitySnapshot s) => s.alerts.isNotEmpty;
}
