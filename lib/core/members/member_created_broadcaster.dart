import '../firebase/firebase_initializer.dart';
import '../sync/firebase_to_local_sync.dart';
import '../sync/member_sync_manager.dart';
import 'member_visibility_service.dart';
import 'staff_firestore_profile_ensurer.dart';
import '../storage/local_session.dart';
import '../../shared/models/admin_staff_account_model.dart';

/// Notifie tous les Admins qu'un membre a été créé — push Firebase + pull local.
class MemberCreatedBroadcaster {
  MemberCreatedBroadcaster({
    MemberSyncManager? syncManager,
    FirebaseToLocalSync? pullSync,
  })  : _sync = syncManager ?? MemberSyncManager(),
        _pull = pullSync ?? FirebaseToLocalSync();

  final MemberSyncManager _sync;
  final FirebaseToLocalSync _pull;

  static final MemberCreatedBroadcaster instance = MemberCreatedBroadcaster();

  /// Après création locale — pousse Firebase puis rafraîchit le cache local.
  Future<void> notifyCreated(String memberId) async {
    if (!FirebaseInitializer.isInitialized) return;
    await _sync.pushMember(memberId);
    await _sync.syncNow(silent: true);
    await _pull.pullAll();
  }

  /// Après connexion staff — profil Firestore + pull complet des membres.
  Future<void> afterStaffLogin(
    LocalSession session, {
    AdminStaffAccount? account,
  }) async {
    if (!MemberVisibilityService.shouldSyncAllMembers(session)) return;
    if (!FirebaseInitializer.isInitialized) return;
    if (account != null) {
      await StaffFirestoreProfileEnsurer().ensureForAccount(account);
    }
    await _pull.pullAll();
    await _sync.syncNow(silent: true);
  }
}

/// Alias demandés.
typedef MembersRealtimeListener = MemberCreatedBroadcaster;
typedef MemberCreatedBroadcasterService = MemberCreatedBroadcaster;
typedef FirebaseToLocalMemberSync = FirebaseToLocalSync;
typedef LocalMemberCacheUpdater = MemberCreatedBroadcaster;
typedef AdminDashboardRealtimeUpdater = MemberCreatedBroadcaster;
typedef PointageCacheUpdater = MemberCreatedBroadcaster;
