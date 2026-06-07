import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sync/auto_sync_manager.dart';
import '../sync/background_sync_trigger.dart';
import '../sync/member_auto_sync_service.dart';
import '../sync/member_sync_manager.dart';
import 'member_sync_providers.dart';
import '../sync/offline_sync_queue.dart';
import '../sync/sync_worker.dart';
import '../firebase/firebase_realtime_listener_service.dart';

/// Global background sync state for discrete UI badges.
final backgroundSyncStateProvider =
    StateProvider<BackgroundSyncState>((ref) => const BackgroundSyncState());

final autoSyncManagerProvider = Provider<AutoSyncManager>((ref) {
  final manager = AutoSyncManager(
    memberSync: ref.read(memberSyncManagerProvider),
  );
  manager.onStateChanged = (state) {
    ref.read(backgroundSyncStateProvider.notifier).state = state;
  };
  ref.onDispose(manager.dispose);
  return manager;
});

final offlineSyncQueueProvider = Provider<OfflineSyncQueue>((ref) {
  return OfflineSyncQueue();
});

final syncWorkerProvider = Provider<SyncWorker>((ref) => SyncWorker());

final firebaseRealtimeListenerProvider =
    Provider<FirebaseRealtimeListenerService>((ref) {
  final service = FirebaseRealtimeListenerService();
  ref.onDispose(service.stop);
  return service;
});

final memberAutoSyncServiceProvider = Provider<MemberAutoSyncService>((ref) {
  return MemberAutoSyncService(
    autoSync: ref.read(autoSyncManagerProvider),
    realtime: ref.read(firebaseRealtimeListenerProvider),
  );
});

final backgroundSyncTriggerProvider = Provider<BackgroundSyncTrigger>((ref) {
  return BackgroundSyncTrigger(
    autoSync: ref.read(autoSyncManagerProvider),
  );
});

final pendingSyncActionsProvider = FutureProvider((ref) async {
  ref.watch(backgroundSyncStateProvider);
  return ref.read(offlineSyncQueueProvider).listPending();
});
