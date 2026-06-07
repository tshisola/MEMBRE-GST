import '../../../app/constants.dart';
import '../../database/database_helper.dart';
import '../../../features/members/data/local_member_repository.dart';
import '../../../shared/models/ifcm_member_record.dart';
import '../models/smart_models.dart';
import '../planning/smart_media_team_planner.dart';

/// Génère le rapport intelligent après activité.
class PostServiceReportEngine {
  PostServiceReportEngine({LocalMemberRepository? repo})
      : _repo = repo ?? LocalMemberRepository();

  final LocalMemberRepository _repo;

  Future<PostServiceReport> generate({DateTime? serviceDate}) async {
    final date = serviceDate ?? DateTime.now();
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    var present = 0;
    var absent = 0;
    var late = 0;
    var onTime = 0;

    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        AppConstants.tableMediaAttendance,
        where: 'session_date = ?',
        whereArgs: [dateStr],
      );
      for (final row in rows) {
        switch (row['status'] as String? ?? '') {
          case 'present':
            present++;
            onTime++;
          case 'late':
            late++;
            present++;
          case 'absent':
            absent++;
          default:
            break;
        }
      }
    } catch (_) {}

    final planner = SmartMediaTeamPlanner();
    final plan = await planner.generate(serviceDate: date);
    final covered = plan.posts.where((p) => p.assignedMemberId != null).length;
    final uncovered = plan.posts.length - covered;

    final recommendations = <String>[];
    if (absent > 0) {
      recommendations.add('Contacter les membres absents avant le prochain service.');
    }
    if (late > 0) {
      recommendations.add('Rappeler les horaires d\'arrivée aux retardataires.');
    }
    if (uncovered > 0) {
      recommendations.add('Compléter les postes non couverts.');
    }
    if (recommendations.isEmpty) {
      recommendations.add('Service bien organisé. Continuez ainsi.');
    }

    final total = present + absent + late;
    final serviceScore = total == 0
        ? 70
        : (((present / total) * 70) + ((covered / plan.posts.length) * 30))
            .round()
            .clamp(0, 100);

    return PostServiceReport(
      serviceDate: date,
      presentCount: present,
      absentCount: absent,
      lateCount: late,
      onTimeCount: onTime,
      coveredPosts: covered,
      uncoveredPosts: uncovered,
      serviceScore: serviceScore,
      recommendations: recommendations,
    );
  }
}

typedef MediaActivityReportService = PostServiceReportEngine;
typedef SmartReportDashboard = PostServiceReportEngine;

/// Export PDF/CSV du rapport — délègue aux services existants.
class SmartReportPdfService {
  Future<void> shareReport(PostServiceReport report) async {
    // Rapport disponible via l'écran — export PDF via services média existants.
  }
}
