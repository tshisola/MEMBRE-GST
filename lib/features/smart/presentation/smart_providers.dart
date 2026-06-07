import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/smart/automation/smart_automation_center.dart';
import '../../../core/smart/models/smart_models.dart';
import '../../../core/smart/smart_assistant_engine.dart';
import '../../../core/smart/smart_admin_dashboard.dart';
import '../../../core/smart/pointage_visibility_checker.dart';
import '../../../core/smart/data_quality_engine.dart';
import '../../../core/smart/planning/smart_media_team_planner.dart';
import '../../../core/smart/prediction/attendance_risk_predictor.dart';
import '../../../core/smart/checklist/media_service_checklist.dart';
import '../../../core/smart/report/post_service_report_engine.dart';
import '../../../core/smart/score/member_media_score_engine.dart';
import '../../../core/smart/deletion/smart_deletion_impact_analyzer.dart';

final smartAssistantReportProvider =
    FutureProvider<SmartAssistantReport>((ref) async {
  return SmartAutomationCenter.instance.analyzeNow();
});

final smartDashboardSnapshotProvider =
    FutureProvider<SmartDashboardSnapshot>((ref) async {
  return SmartAdminDashboard().load();
});

final pointageVisibilityProvider =
    FutureProvider<PointageVisibilityReport>((ref) async {
  return PointageVisibilityChecker().check();
});

final dataQualityReportProvider =
    FutureProvider<DataQualityReport>((ref) async {
  return DataQualityEngine().analyze();
});

final sundayTeamPlanProvider =
    FutureProvider<SundayTeamPlan>((ref) async {
  return SmartMediaTeamPlanner().generate();
});

final attendanceRisksProvider =
    FutureProvider<List<AttendanceRiskMember>>((ref) async {
  return AttendanceRiskPredictor().analyze();
});

final serviceChecklistProvider =
    FutureProvider<List<ServiceChecklistItem>>((ref) async {
  return MediaServiceChecklist().load();
});

final postServiceReportProvider =
    FutureProvider<PostServiceReport>((ref) async {
  return PostServiceReportEngine().generate();
});

final memberScoreProvider =
    FutureProvider.family<MemberMediaScore, String>((ref, memberId) async {
  return MemberMediaScoreEngine().scoreFor(memberId);
});

final deletionImpactProvider =
    FutureProvider.family<DeletionImpactReport, String>((ref, memberId) async {
  return SmartDeletionImpactAnalyzer().analyze(memberId);
});
