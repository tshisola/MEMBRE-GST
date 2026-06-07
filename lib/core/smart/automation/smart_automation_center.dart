import '../models/smart_models.dart';
import '../smart_assistant_engine.dart';
import '../../logging/app_logger.dart';
import '../../production/smart_automation_engine.dart';
import '../../advanced/notifications/push_notification_service.dart';
import 'automation_trigger_service.dart';

/// Centre d'automatisation intelligente — orchestrateur global.
class SmartAutomationCenter {
  SmartAutomationCenter._();
  static final SmartAutomationCenter instance = SmartAutomationCenter._();

  final SmartAssistantEngine _assistant = SmartAssistantEngine();
  final AutomationTriggerService _triggers = AutomationTriggerService();
  SmartAssistantReport? _lastReport;
  DateTime? _lastRun;

  SmartAssistantReport? get lastReport => _lastReport;

  Future<void> onAppStart() => _run('app_start');
  Future<void> onAfterSync() => _run('after_sync');
  Future<void> onMemberCreated() => _run('member_created');
  Future<void> onMemberDeleted() => _run('member_deleted');
  Future<void> onAttendanceSaved() => _run('attendance_saved');
  Future<void> onListCreated() => _run('list_created');
  Future<void> onDashboardOpen() => _run('dashboard_open');
  Future<void> onConnectivityRestored() => _run('connectivity_restored');

  Future<SmartAssistantReport?> _run(String trigger) async {
    if (!_triggers.shouldRun(trigger, _lastRun)) return _lastReport;
    try {
      await SmartAutomationEngine.instance.runPostSyncAutomations();
      _lastReport = await _assistant.analyze();
      _lastRun = DateTime.now();
      AppLogger.sync('SmartAutomation [$trigger] — ${_lastReport!.issues.length} alerte(s)');
      return _lastReport;
    } catch (e) {
      AppLogger.error('Smart', 'AutomationCenter', e);
      return _lastReport;
    }
  }

  Future<SmartAssistantReport> analyzeNow() async {
    _lastReport = await _assistant.analyze();
    _lastRun = DateTime.now();
    return _lastReport!;
  }
}

typedef BackgroundSmartWorker = SmartAutomationCenter;
typedef AutoRepairScheduler = SmartAutomationCenter;

/// Notifications intelligentes — déclenchement discret vers le centre local.
class SmartNotificationService {
  SmartNotificationService._();

  static void notifyIfCritical(SmartAssistantReport report) {
    if (report.criticalCount > 0) {
      AppLogger.sync('${report.criticalCount} alerte(s) critique(s) détectée(s).');
    }
  }

  static Future<void> dispatchReport(SmartAssistantReport report) async {
    notifyIfCritical(report);
    final rules = PushNotificationService.instance.rules;
    for (final issue in report.issues) {
      await _dispatchIssue(rules, issue);
    }
  }

  static Future<void> _dispatchIssue(
    SmartNotificationRulesEngine rules,
    SmartIssue issue,
  ) async {
    final countMatch = RegExp(r'(\d+)').firstMatch(issue.title);
    final count = int.tryParse(countMatch?.group(1) ?? '') ?? 1;

    switch (issue.category) {
      case SmartIssueCategory.pointage:
        if (issue.id == 'pointage_invisible_summary') {
          await rules.onInvisiblePointage(count);
        }
      case SmartIssueCategory.qrCode:
        await rules.onMissingQr(count);
      case SmartIssueCategory.sync:
        if (issue.id == 'sync_pending' || issue.id == 'local_only') {
          await rules.onSyncError();
        }
      case SmartIssueCategory.list:
        await rules.onIncompleteList(issue.title);
      case SmartIssueCategory.attendance:
      case SmartIssueCategory.department:
      case SmartIssueCategory.dataQuality:
      case SmartIssueCategory.duplicate:
      case SmartIssueCategory.general:
        break;
    }
  }
}
