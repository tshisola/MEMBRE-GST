import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../app/constants.dart';
import '../../features/members/data/local_member_repository.dart';
import '../firebase/firebase_initializer.dart';
import '../firebase/firebase_sync_service.dart';
import 'firebase_to_local_sync.dart';
import 'local_to_firebase_sync.dart';
import 'offline_action_queue.dart';
import 'sync_logger.dart';

typedef MemberSyncCallback = void Function({required int updated, String? message});

/// Orchestrates offline-first member sync: push, pull, connectivity, queue.
class MemberSyncManager {
  MemberSyncManager({
    LocalMemberRepository? localRepo,
    LocalToFirebaseSync? pushSync,
    FirebaseToLocalSync? pullSync,
    FirebaseSyncService? firebaseSync,
    OfflineActionQueue? queue,
    Connectivity? connectivity,
  })  : _local = localRepo ?? LocalMemberRepository(),
        _push = pushSync ?? LocalToFirebaseSync(),
        _pull = pullSync ?? FirebaseToLocalSync(),
        _firebase = firebaseSync ?? FirebaseSyncService(),
        _queue = queue ?? OfflineActionQueue(),
        _connectivity = connectivity ?? Connectivity();

  final LocalMemberRepository _local;
  final LocalToFirebaseSync _push;
  final FirebaseToLocalSync _pull;
  final FirebaseSyncService _firebase;
  final OfflineActionQueue _queue;
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  MemberSyncCallback? onMembersUpdated;
  DateTime? lastSyncAt;

  Future<void> initialize() async {
    if (!FirebaseInitializer.isInitialized) {
      SyncLogger.info('MemberSyncManager: Firebase offline, queue only');
      return;
    }
    await syncNow(silent: true);
    _connectivitySub ??= _connectivity.onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) {
        unawaited(syncNow(silent: true));
      }
    });
  }

  Future<void> syncNow({bool silent = false}) async {
    if (!FirebaseInitializer.isInitialized) return;

    await _queue.flushPending();
    final pushed = await _push.pushAllPending();
    final pulled = await _pull.pullAll();
    lastSyncAt = DateTime.now();

    final total = pushed + pulled;
    if (total > 0 || !silent) {
      onMembersUpdated?.call(
        updated: total,
        message: total > 0 ? 'Nouveau membre synchronisé.' : null,
      );
    }
    SyncLogger.info('SyncNow: push=$pushed pull=$pulled');
  }

  Future<bool> pushMember(String localId) => _push.pushMember(localId);

  Future<int> countPending() async {
    final pending = await _local.countBySyncStatus(AppConstants.syncStatusPending);
    final errors = await _local.countBySyncStatus(AppConstants.syncStatusError);
    return pending + errors;
  }

  void dispose() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }
}
