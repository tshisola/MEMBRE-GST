import '../../smart/automation/smart_automation_center.dart';
import '../notifications/push_notification_service.dart';
import '../performance/performance_monitor.dart';

/// Automatisation avancée — orchestrateur des nouvelles intelligences.
class AdvancedAutomationCenter {
  AdvancedAutomationCenter._();
  static final AdvancedAutomationCenter instance = AdvancedAutomationCenter._();

  final AutoNotificationDispatcher _notifications = AutoNotificationDispatcher();
  final AutoQualityChecker _quality = AutoQualityChecker();
  final AutoReportGenerator _reports = AutoReportGenerator();

  Future<void> onAppStart() async {
    AppStartupTimer.start();
    await PushNotificationService.instance.initialize();
    AppStartupTimer.complete();
    await SmartAutomationCenter.instance.onAppStart();
    await _quality.runSilent();
  }

  Future<void> onAfterSync() async {
    await SmartAutomationCenter.instance.onAfterSync();
    await _quality.runSilent();
    await _notifications.dispatchFromAnalysis();
  }

  Future<void> onMemberCreated(String name, {String? memberId}) async {
    await SmartAutomationCenter.instance.onMemberCreated();
    await PushNotificationService.instance.rules.onMemberCreated(
      name,
      memberId: memberId,
    );
  }

  Future<void> onMemberDeleted(String name) async {
    await SmartAutomationCenter.instance.onMemberDeleted();
    await PushNotificationService.instance.rules.onMemberDeleted(name);
  }

  Future<void> onAttendanceSaved() async {
    await SmartAutomationCenter.instance.onAttendanceSaved();
  }

  Future<void> onDashboardOpen() async {
    await SmartAutomationCenter.instance.onDashboardOpen();
    await _quality.runSilent();
  }

  Future<void> onActivityEnd() async {
    await _reports.generateIfNeeded();
    await PushNotificationService.instance.rules.onReportAvailable();
  }

  Future<void> onConnectivityRestored() async {
    await SmartAutomationCenter.instance.onConnectivityRestored();
    await _notifications.dispatchFromAnalysis();
  }
}

typedef BackgroundSmartWorkerAdvanced = AdvancedAutomationCenter;

class AutoNotificationDispatcher {
  Future<void> dispatchFromAnalysis() async {
    final report = await SmartAutomationCenter.instance.analyzeNow();
    await SmartNotificationService.dispatchReport(report);
  }
}

class AutoQualityChecker {
  Future<void> runSilent() async {
    PerformanceMonitor.recordQuery(
      await SlowQueryDetector.measureSample(),
    );
  }
}

class AutoReportGenerator {
  Future<void> generateIfNeeded() async {}
}
