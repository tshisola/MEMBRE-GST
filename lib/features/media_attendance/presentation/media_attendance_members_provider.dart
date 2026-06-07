import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/members/pointage_member_view.dart';
import '../../../core/members/attendance_member_query_service.dart';
import '../../../features/admin_realtime/presentation/members_live_provider.dart';

final mediaPointageMembersProvider =
    FutureProvider<List<PointageMemberView>>((ref) async {
  ref.watch(membersRevisionProvider);
  return AttendanceMemberQueryService().loadForMediaPointage();
});

final mediaPointageMembersRevisionProvider = StateProvider<int>((ref) => 0);

void bumpMediaPointageMembers(WidgetRef ref) {
  ref.read(mediaPointageMembersRevisionProvider.notifier).state++;
  ref.invalidate(mediaPointageMembersProvider);
}
