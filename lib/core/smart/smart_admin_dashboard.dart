import '../../../app/constants.dart';
import '../database/database_helper.dart';
import '../../../features/members/data/local_member_repository.dart';
import 'models/smart_models.dart';
import 'pointage_visibility_checker.dart';
import 'data_quality_engine.dart';
import 'sync_intelligence_engine.dart';
import 'checklist/media_service_checklist.dart';
import 'prediction/attendance_risk_predictor.dart';
import 'smart_issue_detector.dart';

/// Snapshot pour le dashboard Admin intelligent.
class SmartAdminDashboard {
  SmartAdminDashboard({
    LocalMemberRepository? members,
    PointageVisibilityChecker? pointage,
    DataQualityEngine? quality,
    SyncIntelligenceEngine? sync,
    MediaServiceChecklist? checklist,
    SmartIssueDetector? issues,
    AttendanceRiskPredictor? risks,
  })  : _members = members ?? LocalMemberRepository(),
        _pointage = pointage ?? PointageVisibilityChecker(),
        _quality = quality ?? DataQualityEngine(),
        _sync = sync ?? SyncIntelligenceEngine(),
        _checklist = checklist ?? MediaServiceChecklist(),
        _issues = issues ?? SmartIssueDetector(),
        _risks = risks ?? AttendanceRiskPredictor();

  final LocalMemberRepository _members;
  final PointageVisibilityChecker _pointage;
  final DataQualityEngine _quality;
  final SyncIntelligenceEngine _sync;
  final MediaServiceChecklist _checklist;
  final SmartIssueDetector _issues;
  final AttendanceRiskPredictor _risks;

  Future<SmartDashboardSnapshot> load() async {
    final active = await _members.listActive();
    final pointage = await _pointage.check();
    final quality = await _quality.analyze();
    final sync = await _sync.analyze();
    final prep = await _checklist.progressPercent();
    final allIssues = await _issues.detectAll();
    final risks = await _risks.analyze();

    final missingQr = active.where((m) => m.qrData.isEmpty).length;
    final critical = allIssues
        .where((i) => i.severity == SmartIssueSeverity.critical)
        .length;

    return SmartDashboardSnapshot(
      activeMembers: active.length,
      pointageVisible: pointage.visibleCount,
      pointageInvisible: pointage.invisibleMembers.length,
      incompleteLists: 0,
      pendingSync: sync.pendingCount,
      missingQr: missingQr,
      criticalAlerts: critical,
      dataQualityScore: quality.score,
      syncScore: sync.score,
      prepScore: prep,
      frequentLate: risks.where((r) => r.riskType == 'retard').length,
      frequentAbsent: risks.where((r) => r.riskType == 'absence').length,
    );
  }
}

typedef SmartDashboardCard = SmartDashboardSnapshot;
typedef CriticalAlertCard = SmartIssue;
typedef SmartActionButton = SmartIssueAction;
