import 'package:flutter_test/flutter_test.dart';

import 'package:ifcm_membership/app/constants.dart';
import 'package:ifcm_membership/core/auth/staff_seed_credentials.dart';
import 'package:ifcm_membership/core/security/role_permission_matrix.dart';

void main() {
  group('Staff accounts', () {
    test('Mechack uses gmail email', () {
      expect(
        StaffSeedCredentials.resolvedEmail(AppConstants.staffLoginMechack),
        'mechack@gmail.com',
      );
    });

    test('Alex uses gmail and admin_simple role exists', () {
      expect(
        StaffSeedCredentials.resolvedEmail(AppConstants.staffLoginAlex),
        AppConstants.staffEmailAlex,
      );
      expect(AppConstants.roleAdminSimple, 'admin_simple');
    });
  });

  group('RolePermissionMatrix admin_simple', () {
    test('Alex cannot delete member or assign roles', () {
      final perms = RolePermissionMatrix.permissionsForRole(
        AppConstants.roleAdminSimple,
      );
      expect(perms, contains(RolePermissionMatrix.canCreateMember));
      expect(perms, isNot(contains(RolePermissionMatrix.canDeleteMember)));
      expect(perms, isNot(contains(RolePermissionMatrix.canAssignRoles)));
    });

    test('Operator can point and scan only', () {
      final perms = RolePermissionMatrix.permissionsForRole(
        AppConstants.roleAttendanceOperator,
      );
      expect(perms, contains(RolePermissionMatrix.canTakeAttendance));
      expect(perms, contains(RolePermissionMatrix.canScanQr));
      expect(perms, isNot(contains(RolePermissionMatrix.canDeleteMember)));
    });
  });
}
