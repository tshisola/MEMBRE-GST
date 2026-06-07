import '../../../app/constants.dart';
import '../../../features/members/data/local_member_repository.dart';
import '../../database/database_helper.dart';
import '../../services/media_lists_local_repository.dart';
import '../../smart/models/smart_models.dart';
import '../../smart/checklist/media_service_checklist.dart';
import '../../smart/data_quality_engine.dart';
import '../../smart/pointage_visibility_checker.dart';
import '../../smart/smart_issue_detector.dart';
import '../../smart/sync_intelligence_engine.dart';
import '../models/advanced_models.dart';

/// Centre de commande Admin — vue globale application.
class IntelligentAdminCommandCenter {
  IntelligentAdminCommandCenter({
    AppHealthScoreEngine? health,
    CriticalAlertEngine? alerts,
    RecommendedActionsEngine? actions,
    LocalMemberRepository? members,
    PointageVisibilityChecker? pointage,
    DataQualityEngine? quality,
    SyncIntelligenceEngine? sync,
    MediaServiceChecklist? checklist,
    SmartIssueDetector? issues,
    MediaListsLocalRepository? lists,
  })  : _health = health ?? AppHealthScoreEngine(),
        _alerts = alerts ?? CriticalAlertEngine(),
        _actions = actions ?? RecommendedActionsEngine(),
        _members = members ?? LocalMemberRepository(),
        _pointage = pointage ?? PointageVisibilityChecker(),
        _quality = quality ?? DataQualityEngine(),
        _sync = sync ?? SyncIntelligenceEngine(),
        _checklist = checklist ?? MediaServiceChecklist(),
        _issues = issues ?? SmartIssueDetector(),
        _lists = lists ?? MediaListsLocalRepository();

  final AppHealthScoreEngine _health;
  final CriticalAlertEngine _alerts;
  final RecommendedActionsEngine _actions;
  final LocalMemberRepository _members;
  final PointageVisibilityChecker _pointage;
  final DataQualityEngine _quality;
  final SyncIntelligenceEngine _sync;
  final MediaServiceChecklist _checklist;
  final SmartIssueDetector _issues;
  final MediaListsLocalRepository _lists;

  Future<AppHealthSnapshot> load() async {
    final active = await _members.listActive();
    final deleted = await _members.listDeleted();
    final pointage = await _pointage.check();
    final quality = await _quality.analyze();
    final sync = await _sync.analyze();
    final checklist = await _checklist.load();
    final issueList = await _issues.detectAll();
    final criticalCount = issueList
        .where((i) => i.severity == SmartIssueSeverity.critical)
        .length;
    final prepDone = checklist.where((c) => c.done).length;
    final prepPercent = checklist.isEmpty
        ? 100
        : ((prepDone / checklist.length) * 100).round();

    final mediaLists = await _lists.loadLists();
    final incompleteLists = mediaLists.where((list) {
      if (list.entries.isEmpty) return true;
      return list.entries.any(
        (e) => e.memberId.trim().isEmpty || e.memberName.trim().isEmpty,
      );
    }).length;

    final attendance = await _loadTodayAttendance();
    final inactiveAccounts = await _countInactiveAccounts();
    final qrMissing = quality.missingQrCount;

    final listScore = incompleteLists == 0
        ? 100
        : (100 - incompleteLists * 8).clamp(50, 100);

    final health = _health.compute(
      syncScore: sync.score,
      dataQualityScore: quality.score,
      pointageScore: pointage.invisibleMembers.isEmpty
          ? 100
          : (100 - pointage.invisibleMembers.length * 5).clamp(40, 100),
      listScore: listScore,
      prepScore: prepPercent,
      qrScore: qrMissing == 0 ? 100 : (100 - qrMissing * 4).clamp(50, 100),
    );

    final recommendations = _actions.recommend(
      invisibleCount: pointage.invisibleMembers.length,
      pendingSync: sync.pendingCount + sync.localOnlyCount,
      qualityScore: quality.score,
      criticalCount: criticalCount,
      incompleteLists: incompleteLists,
      qrMissing: qrMissing,
      inactiveAccounts: inactiveAccounts,
    );

    return AppHealthSnapshot(
      healthScore: health,
      syncScore: sync.score,
      dataQualityScore: quality.score,
      pointageScore: pointage.invisibleMembers.isEmpty ? 100 : 85,
      listScore: listScore,
      activeMembers: active.length,
      visibleAtPointage: pointage.visibleCount,
      invisibleAtPointage: pointage.invisibleMembers.length,
      incompleteLists: incompleteLists,
      pendingSync: sync.pendingCount + sync.localOnlyCount,
      criticalAlerts: criticalCount,
      recommendations: recommendations,
      generatedAt: DateTime.now(),
      deletedMembers: deleted.length,
      totalListsGenerated: mediaLists.length,
      todayPresent: attendance.present,
      todayLate: attendance.late,
      todayAbsent: attendance.absent,
      qrMissingCount: qrMissing,
      inactiveAccounts: inactiveAccounts,
    );
  }

  Future<({int present, int late, int absent})> _loadTodayAttendance() async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        AppConstants.tableMediaAttendance,
        where: 'session_date = ?',
        whereArgs: [today],
      );
      var present = 0;
      var late = 0;
      var absent = 0;
      for (final r in rows) {
        final status = (r['status'] as String? ?? '').toLowerCase();
        if (status.contains('late') || status.contains('retard')) {
          late++;
          present++;
        } else if (status.contains('present') || status.contains('présent')) {
          present++;
        } else if (status.contains('absent')) {
          absent++;
        }
      }
      return (present: present, late: late, absent: absent);
    } catch (_) {
      return (present: 0, late: 0, absent: 0);
    }
  }

  Future<int> _countInactiveAccounts() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.rawQuery(
        'SELECT COUNT(*) as c FROM ${AppConstants.tableMemberAccounts} '
        'WHERE is_active = 0',
      );
      return rows.first['c'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }
}

/// Score santé globale MEDIA LUBUMBASHI.
class AppHealthScoreEngine {
  int compute({
    required int syncScore,
    required int dataQualityScore,
    required int pointageScore,
    required int listScore,
    required int prepScore,
    int qrScore = 100,
  }) {
    final raw = (syncScore * 0.22 +
            dataQualityScore * 0.22 +
            pointageScore * 0.18 +
            listScore * 0.13 +
            prepScore * 0.13 +
            qrScore * 0.12)
        .round();
    return raw.clamp(0, 100);
  }
}

class CriticalAlertEngine {
  Future<int> count() async {
    final issues = await SmartIssueDetector().detectAll();
    return issues
        .where((i) => i.severity == SmartIssueSeverity.critical)
        .length;
  }
}

class RecommendedActionsEngine {
  List<String> recommend({
    required int invisibleCount,
    required int pendingSync,
    required int qualityScore,
    required int criticalCount,
    int incompleteLists = 0,
    int qrMissing = 0,
    int inactiveAccounts = 0,
  }) {
    final list = <String>[];
    if (invisibleCount > 0) {
      list.add('Corriger $invisibleCount membre(s) invisible(s) au pointage.');
    }
    if (pendingSync > 0) {
      list.add(
        'Relancer la synchronisation ($pendingSync élément(s) en attente).',
      );
    }
    if (qualityScore < 80) {
      list.add('Améliorer la qualité des données (score $qualityScore %).');
    }
    if (criticalCount > 0) {
      list.add('Traiter $criticalCount alerte(s) critique(s).');
    }
    if (incompleteLists > 0) {
      list.add('Compléter $incompleteLists liste(s) incomplète(s).');
    }
    if (qrMissing > 0) {
      list.add('Vérifier $qrMissing QR Code manquant(s).');
    }
    if (inactiveAccounts > 0) {
      list.add('Activer $inactiveAccounts compte(s) membre en attente.');
    }
    if (list.isEmpty) {
      list.add('Application en bon état — aucune action urgente.');
    }
    return list;
  }
}

/// Alias compatibles avec la spécification produit.
typedef IntelligentAdminCenter = IntelligentAdminCommandCenter;
typedef SmartAlertEngine = CriticalAlertEngine;
typedef AdminRecommendationEngine = RecommendedActionsEngine;
