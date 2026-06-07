import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/constants.dart';
import '../providers/app_providers.dart';
import '../services/permission_service.dart';
import '../storage/local_session.dart';
import '../../shared/models/role_models.dart';

final permissionServiceProvider = Provider<PermissionService>(
  (ref) => PermissionService(),
);

final currentUserRoleProvider = FutureProvider<UserRole?>((ref) async {
  final session = await ref.watch(localSessionProvider.future);
  if (!session.isLoggedIn) return null;
  return UserRole(
    uid: session.userId!,
    roles: session.role != null ? [session.role!] : const [],
    permissions: session.permissions,
    departmentId: session.department,
    memberId: session.memberId,
  );
});

final isAdminOwnerProvider = FutureProvider<bool>((ref) async {
  final session = await ref.watch(localSessionProvider.future);
  return session.isAdminGeneralOwner;
});

final isAdminGeneralProvider = FutureProvider<bool>((ref) async {
  final session = await ref.watch(localSessionProvider.future);
  return session.role == AppConstants.roleAdminGeneral ||
      session.isAdminGeneralOwner;
});

extension LocalSessionUserRole on LocalSession {
  UserRole toUserRole() {
    return UserRole(
      uid: userId ?? '',
      roles: role != null ? [role!] : const [],
      permissions: permissions,
      departmentId: department,
      memberId: memberId,
    );
  }
}
