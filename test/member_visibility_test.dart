import 'package:flutter_test/flutter_test.dart';

import 'package:ifcm_membership/app/constants.dart';
import 'package:ifcm_membership/core/members/member_visibility_service.dart';
import 'package:ifcm_membership/core/security/role_permission_matrix.dart';

void main() {
  group('MemberVisibilityService', () {
    test('attendance operator can read for attendance', () {
      expect(
        MemberVisibilityService.canReadForAttendance(
          AppConstants.roleAttendanceOperator,
          RolePermissionMatrix.permissionsForRole(
            AppConstants.roleAttendanceOperator,
          ),
        ),
        isTrue,
      );
    });

    test('admin simple can read all members', () {
      expect(
        MemberVisibilityService.canReadAllMembersForRole(
          AppConstants.roleAdminSimple,
          RolePermissionMatrix.permissionsForRole(
            AppConstants.roleAdminSimple,
          ),
        ),
        isTrue,
      );
    });

    test('operator permissions include can_read_members_for_attendance', () {
      final perms = RolePermissionMatrix.permissionsForRole(
        AppConstants.roleAttendanceOperator,
      );
      expect(perms, contains('can_read_members_for_attendance'));
      expect(perms, contains('can_search_members'));
    });

    test('Mechack should hide sensitive fields', () {
      expect(
        MemberVisibilityService.shouldHideSensitiveFields(
          AppConstants.roleAttendanceOperator,
        ),
        isTrue,
      );
    });
  });
}
