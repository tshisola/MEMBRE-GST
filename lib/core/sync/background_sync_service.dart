import 'auto_sync_manager.dart';

/// Facade for background sync subsystem.
class BackgroundSyncService {
  BackgroundSyncService({required this.autoSync});

  final AutoSyncManager autoSync;
}
