import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database_helper.dart';
import '../providers/app_providers.dart';
import '../sync/member_sync_manager.dart';
import '../sync/offline_action_queue.dart';
import '../sync/sync_manager.dart';

/// Sync status for auth, accounts, and department lists.
class SyncStatusState {
  const SyncStatusState({
    this.isSyncing = false,
    this.pendingCount = 0,
    this.failedCount = 0,
    this.lastMessage,
  });

  final bool isSyncing;
  final int pendingCount;
  final int failedCount;
  final String? lastMessage;

  SyncStatusState copyWith({
    bool? isSyncing,
    int? pendingCount,
    int? failedCount,
    String? lastMessage,
  }) {
    return SyncStatusState(
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      failedCount: failedCount ?? this.failedCount,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }
}

class SyncStatusNotifier extends StateNotifier<SyncStatusState> {
  SyncStatusNotifier({
    required this.authSync,
    required this.memberAccountSync,
    required this.departmentListSync,
    required this.memberSync,
  }) : super(const SyncStatusState());

  final AuthSyncService authSync;
  final MemberAccountSyncService memberAccountSync;
  final DepartmentListSyncService departmentListSync;
  final MemberSyncManager memberSync;

  Future<void> syncAll() async {
    state = state.copyWith(isSyncing: true, lastMessage: 'Synchronisation…');
    try {
      await authSync.sync();
      final accounts = await memberAccountSync.sync();
      final lists = await departmentListSync.sync();
      await memberSync.syncNow(silent: true);
      final pending = await memberSync.countPending();
      state = SyncStatusState(
        isSyncing: false,
        pendingCount: accounts + lists + pending,
        lastMessage: 'Synchronisation terminée',
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        failedCount: state.failedCount + 1,
        lastMessage: e.toString(),
      );
    }
  }
}

final syncStatusProvider =
    StateNotifierProvider<SyncStatusNotifier, SyncStatusState>((ref) {
  return SyncStatusNotifier(
    authSync: AuthSyncService(),
    memberAccountSync: MemberAccountSyncService(),
    departmentListSync: DepartmentListSyncService(),
    memberSync: ref.read(memberSyncManagerProvider),
  );
});

/// Syncs auth-related offline queue items.
class AuthSyncService {
  AuthSyncService({OfflineActionQueue? queue})
      : _queue = queue ?? OfflineActionQueue();

  final OfflineActionQueue _queue;

  Future<int> sync() => _queue.flushPending();
}

/// Syncs member accounts to cloud when online.
class MemberAccountSyncService {
  MemberAccountSyncService({
    OfflineActionQueue? queue,
    SyncManager? syncManager,
  })  : _queue = queue ?? OfflineActionQueue(),
        _syncManager = syncManager ??
            SyncManager(
              databaseProvider: () => DatabaseHelper.instance.database,
            );

  final OfflineActionQueue _queue;
  final SyncManager _syncManager;

  Future<int> sync() async {
    final queueCount = await _queue.flushPending();
    final result = await _syncManager.flushQueue();
    return queueCount + result.processed;
  }
}

/// Syncs department manual lists to cloud.
class DepartmentListSyncService {
  DepartmentListSyncService({OfflineActionQueue? queue})
      : _queue = queue ?? OfflineActionQueue();

  final OfflineActionQueue _queue;

  Future<int> sync() => _queue.flushPending();
}
