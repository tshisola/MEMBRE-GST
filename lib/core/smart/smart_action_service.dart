import 'models/smart_models.dart';
import 'pointage_visibility_checker.dart';
import 'data_quality_engine.dart';
import 'sync_intelligence_engine.dart';
import 'smart_auto_fix_service.dart';

/// Actions rapides de l'assistant.
class SmartActionService {
  SmartActionService({
    SmartAutoFixService? autoFix,
    PointageCacheRefresher? cacheRefresher,
  })  : _autoFix = autoFix ?? SmartAutoFixService(),
        _cache = cacheRefresher ?? PointageCacheRefresher();

  final SmartAutoFixService _autoFix;
  final PointageCacheRefresher _cache;

  Future<SmartActionResult> execute(SmartIssueAction action) async {
    switch (action) {
      case SmartIssueAction.autoFix:
        return _autoFix.fixAll();
      case SmartIssueAction.refreshSync:
        await _cache.refresh();
        return (
          success: true,
          message: 'Synchronisation relancée.',
          fixedCount: 0,
        );
      default:
        return (
          success: true,
          message: 'Action enregistrée.',
          fixedCount: 0,
        );
    }
  }

  Future<SmartActionResult> autoFixIssue(SmartIssue issue) async {
    if (issue.category == SmartIssueCategory.pointage) {
      return PointageAutoRepairService().repairAll();
    }
    if (issue.category == SmartIssueCategory.department) {
      return DataRepairService().repairMissingDepartments();
    }
    return _autoFix.fixAll();
  }
}
