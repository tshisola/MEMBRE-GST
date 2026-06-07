import '../logging/technical_error_repository.dart';
import '../messaging/user_friendly_error_mapper.dart';
import '../firebase/firebase_initializer.dart';
import 'member_sync_manager.dart';
import 'sync_logger.dart';

/// Manual refresh fallback — forces Firebase → SQLite pull + push pending.
class ManualSyncRefreshService {
  ManualSyncRefreshService({MemberSyncManager? manager})
      : _manager = manager ?? MemberSyncManager();

  final MemberSyncManager _manager;

  Future<ManualRefreshResult> refresh() async {
    if (!FirebaseInitializer.isInitialized) {
      return const ManualRefreshResult(
        success: false,
        message: 'Firebase indisponible — données locales conservées.',
      );
    }

    try {
      await _manager.syncNow();
      return ManualRefreshResult(
        success: true,
        message: 'Données à jour',
        syncedAt: _manager.lastSyncAt ?? DateTime.now(),
      );
    } catch (e, st) {
      TechnicalErrorRepository.record(
        source: 'manual_sync_refresh',
        error: e,
        stack: st,
      );
      return ManualRefreshResult(
        success: false,
        message: UserFriendlyErrorMapper.map(
          e,
          fallback:
              'Synchronisation en attente. Les données seront mises à jour automatiquement.',
        ),
      );
    }
  }
}

class ManualRefreshResult {
  const ManualRefreshResult({
    required this.success,
    required this.message,
    this.syncedAt,
  });

  final bool success;
  final String message;
  final DateTime? syncedAt;
}
