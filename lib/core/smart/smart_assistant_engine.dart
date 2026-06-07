import 'smart_issue_detector.dart';
import 'smart_recommendation_service.dart';
import 'smart_action_service.dart';
import 'data_quality_engine.dart';
import 'sync_intelligence_engine.dart';
import 'checklist/media_service_checklist.dart';
import 'models/smart_models.dart';

/// Moteur principal de l'Assistant Intelligent Média.
class SmartAssistantEngine {
  SmartAssistantEngine({
    SmartIssueDetector? detector,
    SmartRecommendationService? recommendations,
    DataQualityEngine? dataQuality,
    SyncIntelligenceEngine? syncEngine,
    MediaServiceChecklist? checklist,
  })  : _detector = detector ?? SmartIssueDetector(),
        _recommendations = recommendations ?? SmartRecommendationService(),
        _dataQuality = dataQuality ?? DataQualityEngine(),
        _sync = syncEngine ?? SyncIntelligenceEngine(),
        _checklist = checklist ?? MediaServiceChecklist();

  final SmartIssueDetector _detector;
  final SmartRecommendationService _recommendations;
  final DataQualityEngine _dataQuality;
  final SyncIntelligenceEngine _sync;
  final MediaServiceChecklist _checklist;

  Future<SmartAssistantReport> analyze() async {
    final issues = await _detector.detectAll();
    final quality = await _dataQuality.analyze();
    final sync = await _sync.analyze();
    final prep = await _checklist.progressPercent();
    final recs = _recommendations.buildFrom(issues, quality, sync);

    final critical = issues
        .where((i) => i.severity == SmartIssueSeverity.critical)
        .length;

    return SmartAssistantReport(
      issues: issues,
      recommendations: recs,
      dataQualityScore: quality.score,
      syncHealthScore: sync.score,
      servicePrepScore: prep,
      criticalCount: critical,
      generatedAt: DateTime.now(),
    );
  }
}
