import '../sync/firebase_to_local_sync.dart';
import '../sync/local_to_firebase_sync.dart';
import '../sync/sync_logger.dart';
import 'firebase_error_handler.dart';
import 'firebase_initializer.dart';
import 'firebase_member_service.dart';

/// High-level Firebase sync facade for IFCM members.
class FirebaseSyncService {
  FirebaseSyncService({
    LocalToFirebaseSync? push,
    FirebaseToLocalSync? pull,
    FirebaseMemberRepository? members,
  })  : _push = push ?? LocalToFirebaseSync(),
        _pull = pull ?? FirebaseToLocalSync(),
        _members = members ?? FirebaseMemberRepository();

  final LocalToFirebaseSync _push;
  final FirebaseToLocalSync _pull;
  final FirebaseMemberRepository _members;

  bool get isAvailable => FirebaseInitializer.isInitialized;

  Future<int> pushPending() async {
    if (!isAvailable) return 0;
    try {
      return await _push.pushAllPending();
    } catch (e) {
      FirebaseErrorHandler.log(e);
      return 0;
    }
  }

  Future<int> pullAll() async {
    if (!isAvailable) return 0;
    try {
      return await _pull.pullAll();
    } catch (e) {
      FirebaseErrorHandler.log(e);
      return 0;
    }
  }

  Future<void> fullSync() async {
    if (!isAvailable) return;
    await pushPending();
    await pullAll();
    SyncLogger.info('Full sync membres terminée');
  }

  Stream<List<dynamic>> watchRemoteMembers() => _members.watchAll();
}
