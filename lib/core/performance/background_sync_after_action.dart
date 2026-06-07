import '../advanced/automation/advanced_automation_center.dart';
import '../sync/member_sync_manager.dart';

/// Synchronisation automatique après action utilisateur.
class BackgroundSyncAfterAction {
  BackgroundSyncAfterAction._();

  static Future<void> run({String trigger = 'user_action'}) async {
    await MemberSyncManager().syncNow(silent: true);
    await AdvancedAutomationCenter.instance.onAfterSync();
  }
}

class FastDuplicateLoader {
  FastDuplicateLoader({int pageSize = 50}) : _pageSize = pageSize;
  final int _pageSize;

  int get pageSize => _pageSize;
}

class NotificationCacheService {
  NotificationCacheService._();
  static final NotificationCacheService instance = NotificationCacheService._();
  int _unreadHint = 0;

  int get unreadHint => _unreadHint;
  void setUnreadHint(int value) => _unreadHint = value;
}
