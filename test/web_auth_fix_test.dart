import 'package:flutter_test/flutter_test.dart';

import 'package:ifcm_membership/app/constants.dart';
import 'package:ifcm_membership/core/auth/staff_seed_credentials.dart';
import 'package:ifcm_membership/core/web/web_firebase_config_checker.dart';
import 'package:ifcm_membership/core/web/web_role_compatibility_service.dart';

void main() {
  group('WebFirebaseConfigChecker', () {
    test('expected project is membremedia', () {
      expect(WebFirebaseConfigChecker.expectedProjectId, 'membremedia');
    });
  });

  group('WebRoleCompatibilityService', () {
    test('Verdick owner has web access by default', () {
      expect(
        WebRoleCompatibilityService.canAccessWebApp(
          role: AppConstants.roleAdminGeneralOwner,
          permissions: const [],
        ),
        isTrue,
      );
    });

    test('Mechack operator has web access without explicit permission', () {
      expect(
        WebRoleCompatibilityService.canAccessWebApp(
          role: AppConstants.roleAttendanceOperator,
          permissions: const [],
        ),
        isTrue,
      );
    });

    test('ensureWebPermissions adds can_access_web', () {
      final perms = WebRoleCompatibilityService.ensureWebPermissions(
        role: AppConstants.roleAdminSimple,
        permissions: const [],
      );
      expect(perms, contains('can_access_web'));
    });
  });

  group('Staff email resolution for Web login', () {
    test('Mechack resolves to gmail', () {
      expect(
        StaffSeedCredentials.resolvedEmail('mechack'),
        'mechack@gmail.com',
      );
    });

    test('Jeno resolves to medialubumbashi domain', () {
      expect(
        StaffSeedCredentials.resolvedEmail('jeno'),
        'jeno@medialubumbashi.app',
      );
    });
  });
}
