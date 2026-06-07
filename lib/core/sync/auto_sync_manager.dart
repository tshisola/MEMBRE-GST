import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../app/constants.dart';
import '../messaging/user_friendly_error_mapper.dart';
import '../firebase/firebase_initializer.dart';
import '../members/member_visibility_service.dart';
import '../storage/local_session.dart';
import 'firebase_to_local_sync.dart';
import 'member_sync_manager.dart';
import 'offline_sync_queue.dart';
import 'sync_logger.dart';
import 'sync_retry_service.dart';
import 'sync_worker.dart';

/// Global background sync state (discrete UI for all users).
enum BackgroundSyncPhase {
  idle,
  offline,
  syncing,
  synced,
  pending,
  error,
}

class BackgroundSyncState {
  const BackgroundSyncState({
    this.phase = BackgroundSyncPhase.idle,
    this.pendingCount = 0,
    this.failedCount = 0,
    this.lastSyncAt,
    this.message,
    this.isAdminDetail = false,
  });

  final BackgroundSyncPhase phase;
  final int pendingCount;
  final int failedCount;
  final DateTime? lastSyncAt;
  final String? message;
  final bool isAdminDetail;

  BackgroundSyncState copyWith({
    BackgroundSyncPhase? phase,
    int? pendingCount,
    int? failedCount,
    DateTime? lastSyncAt,
    String? message,
    bool? isAdminDetail,
  }) {
    return BackgroundSyncState(
      phase: phase ?? this.phase,
      pendingCount: pendingCount ?? this.pendingCount,
      failedCount: failedCount ?? this.failedCount,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      message: message ?? this.message,
      isAdminDetail: isAdminDetail ?? this.isAdminDetail,
    );
  }

  /// Simple message for members (no technical details).
  String get memberMessage {
    switch (phase) {
      case BackgroundSyncPhase.offline:
        return 'Mise à jour en attente';
      case BackgroundSyncPhase.syncing:
        return 'Mise à jour…';
      case BackgroundSyncPhase.pending:
        return 'Mise à jour en attente';
      case BackgroundSyncPhase.error:
        return 'Mise à jour en attente';
      case BackgroundSyncPhase.synced:
      case BackgroundSyncPhase.idle:
        return 'Données à jour';
    }
  }
}

/// Central auto-sync orchestrator — runs behind the UI without blocking.
class AutoSyncManager {
  AutoSyncManager({
    SyncWorker? worker,
    SyncRetryService? retry,
    MemberSyncManager? memberSync,
    OfflineSyncQueue? queue,
    Connectivity? connectivity,
  })  : _worker = worker ?? SyncWorker(),
        _retry = retry ?? SyncRetryService(),
        _memberSync = memberSync ?? MemberSyncManager(),
        _queue = queue ?? OfflineSyncQueue(),
        _connectivity = connectivity ?? Connectivity();

  final SyncWorker _worker;
  final SyncRetryService _retry;
  final MemberSyncManager _memberSync;
  final OfflineSyncQueue _queue;
  final Connectivity _connectivity;

  BackgroundSyncState _state = const BackgroundSyncState();
  BackgroundSyncState get state => _state;

  void Function(BackgroundSyncState state)? onStateChanged;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _syncing = false;
  bool _initialized = false;

  Future<void> initialize({LocalSession? session}) async {
    if (_initialized) return;
    _initialized = true;

    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) {
        unawaited(runBackgroundSync(trigger: 'connectivity'));
      } else {
        _emit(_state.copyWith(phase: BackgroundSyncPhase.offline));
      }
    });

    await runBackgroundSync(trigger: 'app_start', session: session);
  }

  Future<void> runBackgroundSync({
    String trigger = 'manual',
    LocalSession? session,
    bool forcePull = false,
  }) async {
    if (_syncing) return;
    _syncing = true;

    final online = FirebaseInitializer.isInitialized;
    if (!online) {
      _emit(_state.copyWith(
        phase: BackgroundSyncPhase.offline,
        message: 'Hors ligne',
      ));
      _syncing = false;
      return;
    }

    _emit(_state.copyWith(phase: BackgroundSyncPhase.syncing));

    try {
      await _retry.resetRetryableFailures();
      final workerResult = await _worker.run();
      await _memberSync.syncNow(silent: true);

      final shouldPullMembers = forcePull ||
          (session != null &&
              (MemberVisibilityService.shouldSyncAllMembers(session) ||
                  session.isAdminAccount));
      if (shouldPullMembers) {
        await FirebaseToLocalSync().pullAll();
      }

      final pending = await _queue.countByStatus(AppConstants.queueStatusPending);
      final failed = await _queue.countByStatus(AppConstants.queueStatusFailed);
      final critical = await _retry.criticalFailures();

      BackgroundSyncPhase phase;
      if (failed > 0 || critical.isNotEmpty) {
        phase = BackgroundSyncPhase.error;
      } else if (pending > 0) {
        phase = BackgroundSyncPhase.pending;
      } else {
        phase = BackgroundSyncPhase.synced;
      }

      _emit(BackgroundSyncState(
        phase: phase,
        pendingCount: pending,
        failedCount: failed + critical.length,
        lastSyncAt: DateTime.now(),
        message: phase == BackgroundSyncPhase.synced
            ? 'Données à jour'
            : null,
        isAdminDetail: session?.role == AppConstants.roleAdminGeneral,
      ));

      SyncLogger.info(
        'AutoSync [$trigger]: processed=${workerResult.processed} failed=${workerResult.failed}',
      );
    } catch (e) {
      _emit(_state.copyWith(
        phase: BackgroundSyncPhase.error,
        message: UserFriendlyErrorMapper.map(e),
      ));
      SyncLogger.error('AutoSync failed', e);
    } finally {
      _syncing = false;
    }
  }

  void _emit(BackgroundSyncState next) {
    _state = next;
    onStateChanged?.call(next);
  }

  void dispose() {
    _connectivitySub?.cancel();
    _memberSync.dispose();
  }
}
