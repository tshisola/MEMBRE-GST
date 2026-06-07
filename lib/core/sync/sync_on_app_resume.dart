import 'package:flutter/widgets.dart';

import 'auto_sync_manager.dart';

/// Triggers sync when app returns to foreground.
class SyncOnAppResumeService with WidgetsBindingObserver {
  SyncOnAppResumeService({required this.autoSync});

  final AutoSyncManager autoSync;
  bool _observing = false;

  void start() {
    if (_observing) return;
    WidgetsBinding.instance.addObserver(this);
    _observing = true;
  }

  void stop() {
    if (!_observing) return;
    WidgetsBinding.instance.removeObserver(this);
    _observing = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      autoSync.runBackgroundSync(trigger: 'app_resume');
    }
  }
}
