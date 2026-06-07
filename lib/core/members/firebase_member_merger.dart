import '../firebase/firebase_initializer.dart';
import '../logging/technical_error_repository.dart';
import '../sync/firebase_to_local_sync.dart';

/// Fusionne les membres Firebase → SQLite sans bloquer le pointage.
class FirebaseMemberMerger {
  FirebaseMemberMerger({FirebaseToLocalSync? sync})
      : _sync = sync ?? FirebaseToLocalSync();

  final FirebaseToLocalSync _sync;

  /// Tente un pull Firebase ; en cas d'échec (permission, réseau), retourne 0.
  Future<int> mergeIfAvailable() async {
    if (!FirebaseInitializer.isInitialized) return 0;
    try {
      return await _sync.pullAll();
    } catch (e, st) {
      TechnicalErrorRepository.record(
        source: 'firebase_member_merger',
        error: e,
        stack: st,
      );
      return 0;
    }
  }
}

/// Alias demandé par la spec.
typedef FirebaseMemberMergerService = FirebaseMemberMerger;
