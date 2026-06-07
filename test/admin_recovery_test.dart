import 'package:flutter_test/flutter_test.dart';

import 'package:ifcm_membership/app/constants.dart';
import 'package:ifcm_membership/core/auth/member_password_change_service.dart';
import 'package:ifcm_membership/core/auth/staff_seed_credentials.dart';
import 'package:ifcm_membership/core/security/member_privacy_guard.dart';
import 'package:ifcm_membership/core/security/role_permission_matrix.dart';
import 'package:ifcm_membership/core/security/secure_password_hash_service.dart';

void main() {
  group('StaffSeedCredentials', () {
    test('Verdick uses primary gmail email', () {
      expect(
        StaffSeedCredentials.resolvedEmail(AppConstants.staffLoginVerdick),
        AppConstants.staffOwnerPrimaryEmail,
      );
    });

    test('Verdick provisional password is configured', () {
      expect(
        StaffSeedCredentials.seedPassword(AppConstants.staffLoginVerdick),
        'Verd@2026',
      );
    });

    test('Jeno keeps app domain email by default', () {
      expect(
        StaffSeedCredentials.resolvedEmail(AppConstants.staffLoginJeno),
        AppConstants.staffEmailJeno,
      );
    });
  });

  group('SecurePasswordService', () {
    test('hashes password without storing plain text', () {
      const service = SecurePasswordService();
      const plain = 'Verd@2026';
      final salt = service.generateSalt();
      final hash = service.hashPassword(plain, salt);
      expect(hash, isNot(plain));
      expect(service.verifyPassword(
        password: plain,
        salt: salt,
        expectedHash: hash,
      ), isTrue);
    });

    test('rejects wrong password', () {
      const service = SecurePasswordService();
      final salt = service.generateSalt();
      final hash = service.hashPassword('Verd@2026', salt);
      expect(service.verifyPassword(
        password: 'wrong',
        salt: salt,
        expectedHash: hash,
      ), isFalse);
    });
  });

  group('PasswordStrength', () {
    test('accepts strong password', () {
      expect(
        PasswordStrength.evaluate('MonMot@2026').isValid,
        isTrue,
      );
    });

    test('rejects password without special char', () {
      expect(
        PasswordStrength.evaluate('MonMot2026').isValid,
        isFalse,
      );
    });

    test('rejects password without lowercase', () {
      expect(
        PasswordStrength.evaluate('MONMOT@2026').isValid,
        isFalse,
      );
    });
  });

  group('RolePermissionMatrix Jeno', () {
    test('Jeno has no delete member by default', () {
      final perms = RolePermissionMatrix.permissionsForRole(
        AppConstants.roleAdminGeneral,
      );
      expect(perms, isNot(contains(RolePermissionMatrix.canDeleteMember)));
      expect(perms, contains('can_reset_member_passwords'));
    });

    test('Owner has full permissions', () {
      final perms = RolePermissionMatrix.permissionsForRole(
        AppConstants.roleAdminGeneralOwner,
      );
      expect(perms, contains(RolePermissionMatrix.canManageEverything));
      expect(perms, contains(RolePermissionMatrix.canDeleteMember));
      expect(perms, contains(RolePermissionMatrix.canRestoreMember));
    });
  });

  group('MemberPrivacyGuard', () {
    test('hides creator and admin names from member map', () {
      final sanitized = MemberPrivacyGuard.sanitizeMemberMap({
        'firstName': 'Jean',
        'createdBy': 'Verdick Yav',
        'email': 'verdicky9@gmail.com',
      });
      expect(sanitized['createdBy'], isNull);
      expect(sanitized['email'], isNull);
      expect(sanitized['firstName'], 'Jean');
    });
  });
}
