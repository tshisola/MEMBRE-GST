import 'dart:async';

import '../../features/admin_realtime/data/admin_members_realtime_listener.dart';
import '../../features/members/data/local_member_repository.dart';
import '../firebase/firebase_initializer.dart';
import '../firebase/firebase_member_service.dart';
import '../sync/sync_logger.dart';

/// Consolidated Firestore realtime listeners (members + future collections).
class FirebaseRealtimeListenerService {
  FirebaseRealtimeListenerService({
    AdminMembersRealtimeListener? membersListener,
    FirebaseMemberRepository? membersRepo,
  })  : _membersListener = membersListener ?? AdminMembersRealtimeListener(),
        _membersRepo = membersRepo ?? FirebaseMemberRepository();

  final AdminMembersRealtimeListener _membersListener;
  final FirebaseMemberRepository _membersRepo;

  StreamSubscription? _membersSub;
  void Function(int updated)? onMembersUpdated;

  void startAdminListeners() {
    if (!FirebaseInitializer.isInitialized) return;
    _membersListener.onUpdated = (count) => onMembersUpdated?.call(count);
    _membersListener.start();
  }

  void startMemberListeners({required String memberId}) {
    if (!FirebaseInitializer.isInitialized) return;
    _membersSub?.cancel();
    _membersSub = _membersRepo.watchAll().listen((remote) async {
      final mine = remote.where((m) => m.localId == memberId || m.id == memberId);
      if (mine.isEmpty) return;
      final repo = LocalMemberRepository();
      for (final m in mine) {
        await repo.upsert(m);
      }
      onMembersUpdated?.call(mine.length);
      SyncLogger.info('Member realtime: profil mis à jour');
    });
  }

  void stop() {
    _membersListener.stop();
    _membersSub?.cancel();
    _membersSub = null;
  }
}
