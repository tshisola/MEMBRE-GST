import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../logging/app_logger.dart';
import '../sync/offline_action_queue.dart';
import 'firebase_web_sync_service.dart';

/// File d'attente offline Web + retry automatique.
class WebOfflineQueue {
  WebOfflineQueue._();
  static final WebOfflineQueue instance = WebOfflineQueue._();

  final _mobileQueue = OfflineActionQueue();

  Future<void> enqueue({
    required String actionType,
    required Map<String, dynamic> payload,
  }) async {
    await _mobileQueue.enqueue(actionType: actionType, payload: payload);
  }
}

class WebSyncRetryWorker {
  WebSyncRetryWorker._();
  static final WebSyncRetryWorker instance = WebSyncRetryWorker._();

  Future<void> run() async {
    if (!kIsWeb) return;
    await FirebaseWebSyncService.instance.syncNow(trigger: 'retry_worker');
  }
}

class WebConnectionMonitor {
  WebConnectionMonitor._();
  static final WebConnectionMonitor instance = WebConnectionMonitor._();

  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      Connectivity().onConnectivityChanged;

  Future<bool> get isOnline async {
    final r = await Connectivity().checkConnectivity();
    return !r.contains(ConnectivityResult.none);
  }
}

class WebBackgroundSyncService {
  WebBackgroundSyncService._();
  static final WebBackgroundSyncService instance = WebBackgroundSyncService._();

  void start() {
    if (!kIsWeb) return;
    WebConnectionMonitor.instance.onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) {
        AppLogger.sync('Connexion rétablie — sync Web');
        unawaited(FirebaseWebSyncService.instance.syncNow(trigger: 'reconnect'));
        unawaited(WebSyncRetryWorker.instance.run());
      }
    });
  }
}

class WebCacheHydrator {
  WebCacheHydrator._();
  static final WebCacheHydrator instance = WebCacheHydrator._();

  Future<void> hydrateFromFirestore() async {
    if (!kIsWeb) return;
    await FirebaseWebSyncService.instance.syncNow(trigger: 'hydrate');
  }
}
