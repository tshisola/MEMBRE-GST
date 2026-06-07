import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/member_sync_status_service.dart';
import '../../../features/media_attendance/presentation/media_attendance_members_provider.dart';
import '../../../features/members/data/local_member_repository.dart';
import '../../../shared/models/ifcm_member_record.dart';
import '../data/admin_members_realtime_listener.dart';

/// Bumps when local/remote member data changes.
final membersRevisionProvider = StateProvider<int>((ref) => 0);

final memberSyncBannerProvider = StateProvider<String?>((ref) => null);

final membersLiveProvider = FutureProvider<List<IfcmMemberRecord>>((ref) async {
  ref.watch(membersRevisionProvider);
  return LocalMemberRepository().listActive();
});

final memberSyncSummaryProvider = FutureProvider<MemberSyncSummary>((ref) async {
  ref.watch(membersRevisionProvider);
  return MemberSyncStatusService().loadSummary();
});

final membersRealtimeControllerProvider =
    Provider<MembersRealtimeController>((ref) {
  final controller = MembersRealtimeController();
  controller.onUpdated = (count) {
    ref.read(membersRevisionProvider.notifier).state++;
    ref.read(mediaPointageMembersRevisionProvider.notifier).state++;
    if (count > 0) {
      ref.read(memberSyncBannerProvider.notifier).state =
          'Données mises à jour.';
    }
  };
  ref.onDispose(controller.stop);
  return controller;
});

void bumpMembersRevision(WidgetRef ref, {String? banner}) {
  ref.read(membersRevisionProvider.notifier).state++;
  ref.read(mediaPointageMembersRevisionProvider.notifier).state++;
  if (banner != null) {
    ref.read(memberSyncBannerProvider.notifier).state = banner;
  }
}
