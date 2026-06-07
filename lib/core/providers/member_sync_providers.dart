import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sync/member_sync_manager.dart';

final memberSyncManagerProvider = Provider<MemberSyncManager>((ref) {
  return MemberSyncManager();
});
