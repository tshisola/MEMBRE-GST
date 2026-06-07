import 'package:flutter_test/flutter_test.dart';
import 'package:ifcm_membership/core/auth/auth_form_controller.dart';
import 'package:ifcm_membership/core/auth/member_password_change_service.dart';
import 'package:ifcm_membership/core/security/delete_member_guard.dart';
import 'package:ifcm_membership/core/security/role_permission_matrix.dart';
import 'package:ifcm_membership/app/constants.dart';
import 'package:ifcm_membership/shared/models/role_models.dart';

void main() {
  group('AuthFormController', () {
    test('fields start empty after reset', () {
      final form = AuthFormController();
      expect(form.identifierController.text, isEmpty);
      expect(form.passwordController.text, isEmpty);
      expect(form.rememberMe, isFalse);
      form.dispose();
    });

    test('clearFields empties controllers', () {
      final form = AuthFormController();
      form.identifierController.text = 'test@ifcm.local';
      form.passwordController.text = 'secret';
      form.clearFields();
      expect(form.identifierController.text, isEmpty);
      expect(form.passwordController.text, isEmpty);
      form.dispose();
    });
  });

  group('PasswordStrength', () {
    test('rejects short passwords', () {
      final result = PasswordStrength.evaluate('Ab1');
      expect(result.isValid, isFalse);
    });

    test('accepts strong passwords', () {
      final result = PasswordStrength.evaluate('Abcd1234!');
      expect(result.isValid, isTrue);
    });
  });

  group('RolePermissionMatrix', () {
    test('owner has delete permission', () {
      final perms = RolePermissionMatrix.permissionsForRole(
        AppConstants.roleAdminGeneralOwner,
      );
      expect(perms, contains(RolePermissionMatrix.canDeleteMember));
    });

    test('jeno admin_general cannot delete by default', () {
      final perms = RolePermissionMatrix.permissionsForRole(
        AppConstants.roleAdminGeneral,
      );
      expect(perms, isNot(contains(RolePermissionMatrix.canDeleteMember)));
    });
  });

  group('DeleteMemberGuard', () {
    const guard = DeleteMemberGuard();

    test('owner can delete', () {
      final owner = UserRole(
        uid: '1',
        roles: [AppConstants.roleAdminGeneralOwner],
        permissions: RolePermissionMatrix.permissionsForRole(
          AppConstants.roleAdminGeneralOwner,
        ),
      );
      expect(guard.canDelete(owner), isTrue);
    });

    test('jeno without permission cannot delete', () {
      final jeno = UserRole(
        uid: '2',
        roles: [AppConstants.roleAdminGeneral],
        permissions: RolePermissionMatrix.permissionsForRole(
          AppConstants.roleAdminGeneral,
        ),
      );
      expect(guard.canDelete(jeno), isFalse);
    });

    test('jeno with can_delete_member can delete', () {
      final jeno = UserRole(
        uid: '2',
        roles: [AppConstants.roleAdminGeneral],
        permissions: [
          ...RolePermissionMatrix.permissionsForRole(
            AppConstants.roleAdminGeneral,
          ),
          AppPermissions.canDeleteMember,
        ],
      );
      expect(guard.canDelete(jeno), isTrue);
    });

    test('attendance operator cannot delete', () {
      final op = UserRole(
        uid: '3',
        roles: [AppConstants.roleAttendanceOperator],
        permissions: RolePermissionMatrix.permissionsForRole(
          AppConstants.roleAttendanceOperator,
        ),
      );
      expect(guard.canDelete(op), isFalse);
    });

    test('member cannot delete', () {
      final member = UserRole(
        uid: '4',
        roles: [AppConstants.roleMember],
      );
      expect(guard.canDelete(member), isFalse);
    });

    test('only owner can permanent delete', () {
      final owner = UserRole(
        uid: '1',
        roles: [AppConstants.roleAdminGeneralOwner],
      );
      final jeno = UserRole(
        uid: '2',
        roles: [AppConstants.roleAdminGeneral],
        permissions: [AppPermissions.canDeleteMember],
      );
      expect(guard.canPermanentDelete(owner), isTrue);
      expect(guard.canPermanentDelete(jeno), isFalse);
    });
  });
}
