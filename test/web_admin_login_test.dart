import 'package:flutter_test/flutter_test.dart';

import 'package:ifcm_membership/app/constants.dart';
import 'package:ifcm_membership/shared/models/admin_staff_account_model.dart';

void main() {
  test('AdminStaffAccount.fromFirestoreMap maps owner profile', () {
    final account = AdminStaffAccount.fromFirestoreMap(
      {
        'email': AppConstants.staffOwnerPrimaryEmail,
        'fullName': AppConstants.staffOwnerDisplayName,
        'role': AppConstants.roleAdminGeneralOwner,
        'permissions': ['can_manage_everything'],
        'isActive': true,
        'mustChangePassword': true,
        'isOwner': true,
      },
      uid: 'uid_test',
    );

    expect(account.email, AppConstants.staffOwnerPrimaryEmail);
    expect(account.role, AppConstants.roleAdminGeneralOwner);
    expect(account.isOwner, isTrue);
    expect(account.mustChangePassword, isTrue);
  });
}
