import '../logging/app_logger.dart';
import '../members/member_duplicate_detector.dart';
import 'alphabetic_sort_service.dart';
import 'app_health_checker.dart';
import 'performance_monitor.dart';

/// Orchestrateur d'automatisations (QR, doublons, qualité, santé).
class SmartAutomationEngine {
  SmartAutomationEngine._();
  static final SmartAutomationEngine instance = SmartAutomationEngine._();

  DateTime? _lastRun;

  Future<void> runPostSyncAutomations() async {
    if (_lastRun != null &&
        DateTime.now().difference(_lastRun!) < const Duration(minutes: 2)) {
      return;
    }
    _lastRun = DateTime.now();

    await PerformanceMonitor.track('SmartAutomation', () async {
      try {
        final health = await AppHealthChecker.check();
        AppLogger.sync(
          'Santé: SQLite=${health.sqliteOpen} Firebase=${health.firebaseReady} '
          'membres=${health.memberCount} pending=${health.pendingSyncQueue}',
        );

        final detector = MemberDuplicateDetector();
        final dupeGroups = await detector.scanDuplicatePhoneGroups();
        if (dupeGroups > 0) {
          AppLogger.sync('Doublons téléphone potentiels: $dupeGroups groupe(s)');
        }
      } catch (e) {
        AppLogger.error('Sync', 'SmartAutomation', e);
      }
    });
  }

  /// Tri alphabétique utilitaire pour exports / listes.
  List<T> sortList<T>(List<T> items, String Function(T) nameOf) {
    return AlphabeticSortService.sortBy(items, nameOf);
  }
}
