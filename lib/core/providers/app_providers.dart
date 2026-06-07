import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/constants.dart';
import '../database/database_helper.dart';
import '../firebase/firebase_auth_service.dart';
import '../services/media_realtime_service.dart';
import '../services/media_sync_service.dart';
import '../auth/member_dashboard_service.dart';
import '../storage/local_session.dart';
import '../sync/sync_manager.dart';
import '../sync/manual_sync_refresh_service.dart';
import '../../features/members/domain/create_member_use_case.dart';
import 'member_sync_providers.dart';
export 'member_sync_providers.dart';
import '../sync/member_sync_status_service.dart';
import '../providers/background_sync_providers.dart';
import '../sync/offline_sync_queue.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance().timeout(
    const Duration(seconds: 3),
    onTimeout: () => throw TimeoutException('shared_preferences'),
  );
});

final localSessionProvider = FutureProvider<LocalSession>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return LocalSession(prefs);
});

final userRoleProvider = FutureProvider<String?>((ref) async {
  final session = await ref.watch(localSessionProvider.future);
  return session.role;
});

final userNameProvider = FutureProvider<String>((ref) async {
  final session = await ref.watch(localSessionProvider.future);
  final email = session.email;
  if (email != null && email.isNotEmpty) {
    final local = email.split('@').first;
    return local.isNotEmpty ? local : 'Membre';
  }
  return 'Membre';
});

final isMediaAttendanceOperatorProvider = FutureProvider<bool>((ref) async {
  final session = await ref.watch(localSessionProvider.future);
  if (session.isMediaAttendanceOperator) return true;
  final role = session.role;
  return role == AppConstants.roleAdmin ||
      role == AppConstants.roleMediaLead ||
      role == AppConstants.roleMediaOperator;
});

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

final mediaRealtimeServiceProvider = Provider<MediaRealtimeService>((ref) {
  return MediaRealtimeService();
});

final mediaSyncServiceProvider = Provider<MediaSyncService>((ref) {
  return MediaSyncService(
    databaseProvider: () => DatabaseHelper.instance.database,
  );
});

final syncManagerProvider = Provider<SyncManager>((ref) {
  return SyncManager(
    databaseProvider: () => DatabaseHelper.instance.database,
  );
});

final memberDashboardServiceProvider = Provider<MemberDashboardService>((ref) {
  return MemberDashboardService();
});

final memberDashboardDataProvider =
    FutureProvider.family<MemberDashboardData, LocalSession>((ref, session) {
  return ref.read(memberDashboardServiceProvider).loadForSession(
        accountId: session.userId ?? '',
        memberId: session.memberId,
        departmentId: session.department,
      );
});

final memberSyncStatusServiceProvider = Provider<MemberSyncStatusService>((ref) {
  return MemberSyncStatusService();
});

final manualSyncRefreshServiceProvider = Provider<ManualSyncRefreshService>((ref) {
  return ManualSyncRefreshService(
    manager: ref.read(memberSyncManagerProvider),
  );
});

final createMemberUseCaseProvider = Provider<CreateMemberUseCase>((ref) {
  return CreateMemberUseCase(
    syncManager: ref.read(memberSyncManagerProvider),
    syncQueue: ref.read(offlineSyncQueueProvider),
  );
});
