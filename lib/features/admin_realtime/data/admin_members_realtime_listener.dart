import 'dart:async';

import '../../../core/firebase/firebase_member_service.dart';
import '../../../core/sync/firebase_to_local_sync.dart';
import '../../../core/sync/sync_logger.dart';
import '../../../shared/models/ifcm_member_record.dart';

/// Firestore realtime listener — pushes remote members into SQLite.
class AdminMembersRealtimeListener {
  AdminMembersRealtimeListener({
    FirebaseMemberRepository? firebase,
    MemberLocalCacheUpdater? cacheUpdater,
  })  : _firebase = firebase ?? FirebaseMemberRepository(),
        _cache = cacheUpdater ?? MemberLocalCacheUpdater();

  final FirebaseMemberRepository _firebase;
  final MemberLocalCacheUpdater _cache;

  StreamSubscription<List<IfcmMemberRecord>>? _subscription;
  void Function(int updated)? onUpdated;

  void start() {
    if (!_firebase.isAvailable) return;
    _subscription?.cancel();
    _subscription = _firebase.watchAll().listen(
      (remote) async {
        try {
          final count = await _cache.updateFromRemote(remote);
          if (count >= 0) {
            SyncLogger.info('Realtime: $count membre(s) mis à jour');
            onUpdated?.call(count > 0 ? count : remote.length);
          }
        } catch (e) {
          SyncLogger.error('Realtime listener error', e);
        }
      },
      onError: (Object e) => SyncLogger.error('Firestore snapshots error', e),
    );
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }
}

/// Controller for admin member realtime updates.
class MembersRealtimeController {
  MembersRealtimeController({
    AdminMembersRealtimeListener? listener,
  }) : _listener = listener ?? AdminMembersRealtimeListener();

  final AdminMembersRealtimeListener _listener;
  void Function(int updated)? onUpdated;

  void start() {
    _listener.onUpdated = (count) => onUpdated?.call(count);
    _listener.start();
  }

  void stop() => _listener.stop();
}
