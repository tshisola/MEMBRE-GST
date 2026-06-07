import '../../app/constants.dart';
import '../../features/members/data/local_member_repository.dart';
import '../firebase/firebase_initializer.dart';
import '../firebase/firebase_realtime_listener_service.dart';
import '../members/member_visibility_service.dart';
import '../members/weekly_percentage_updater.dart';
import '../storage/local_session.dart';
import 'auto_sync_manager.dart';
import 'sync_logger.dart';

/// Background sync + realtime updates for member accounts.
class MemberAutoSyncService {
  MemberAutoSyncService({
    AutoSyncManager? autoSync,
    FirebaseRealtimeListenerService? realtime,
    LocalMemberRepository? members,
  })  : _autoSync = autoSync ?? AutoSyncManager(),
        _realtime = realtime ?? FirebaseRealtimeListenerService(),
        _members = members ?? LocalMemberRepository();

  final AutoSyncManager _autoSync;
  final FirebaseRealtimeListenerService _realtime;
  final LocalMemberRepository _members;

  void Function()? onDataUpdated;

  Future<void> startForSession(LocalSession session) async {
    _realtime.onMembersUpdated = (_) => onDataUpdated?.call();
    if (MemberVisibilityService.canReceiveMemberRealtime(session)) {
      _realtime.startAdminListeners();
    } else if (session.memberId != null) {
      _realtime.startMemberListeners(memberId: session.memberId!);
    }
    await _autoSync.runBackgroundSync(trigger: 'member_session', session: session);
  }

  Future<double?> refreshMemberPercentage(String memberId) async {
    if (!FirebaseInitializer.isInitialized) return null;
    return WeeklyPercentageUpdater().updateForMember(memberId);
  }

  void stop() => _realtime.stop();

  AutoSyncManager get autoSync => _autoSync;
}

/// Simple cache read for member dashboard (local first).
class MemberOfflineCacheService {
  MemberOfflineCacheService({LocalMemberRepository? members})
      : _members = members ?? LocalMemberRepository();

  final LocalMemberRepository _members;

  Future<Map<String, dynamic>?> loadMemberProfile(String memberId) async {
    final m = await _members.getById(memberId);
    if (m == null) return null;
    return m.toMemberView();
  }
}
