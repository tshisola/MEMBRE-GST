import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firebase/firebase_initializer.dart';
import '../../core/members/member_visibility_service.dart';
import '../../core/providers/app_providers.dart';
import '../../features/admin_realtime/presentation/members_live_provider.dart';
import '../../features/media_attendance/presentation/media_attendance_members_provider.dart';

/// Starts member sync + realtime listeners for admin sessions.
class MemberSyncHost extends ConsumerStatefulWidget {
  const MemberSyncHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<MemberSyncHost> createState() => _MemberSyncHostState();
}

class _MemberSyncHostState extends ConsumerState<MemberSyncHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (!FirebaseInitializer.isInitialized) return;

    final manager = ref.read(memberSyncManagerProvider);
    manager.onMembersUpdated = ({required updated, message}) {
      if (!mounted) return;
      ref.read(membersRevisionProvider.notifier).state++;
      ref.read(mediaPointageMembersRevisionProvider.notifier).state++;
      if (message != null) {
        ref.read(memberSyncBannerProvider.notifier).state = message;
      }
    };
    await manager.initialize();

    final session = await ref.read(localSessionProvider.future);
    if (MemberVisibilityService.canReceiveMemberRealtime(session) && mounted) {
      ref.read(membersRealtimeControllerProvider).start();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
