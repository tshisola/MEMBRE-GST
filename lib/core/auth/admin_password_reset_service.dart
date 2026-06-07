import '../../app/constants.dart';
import 'local_admin_auth_service.dart';
import 'member_auth_service.dart';
import 'password_change_service.dart';

/// Réinitialisation mots de passe — staff + membres, traçable.
class AdminPasswordResetService {
  AdminPasswordResetService({
    LocalAdminAuthService? staffAuth,
    MemberAuthService? memberAuth,
  })  : _staff = staffAuth ?? LocalAdminAuthService(),
        _member = memberAuth ?? MemberAuthService();

  final LocalAdminAuthService _staff;
  final MemberAuthService _member;

  Future<PasswordResetOutcome> resetStaff({
    required String accountId,
    required String actorId,
  }) async {
    final result = await _staff.resetPassword(
      accountId: accountId,
      actorId: actorId,
    );
    return PasswordResetOutcome(
      accountLabel: result.account.displayName,
      temporaryPassword: result.temporaryPassword,
      accountType: AppConstants.accountTypeAdmin,
    );
  }

  Future<PasswordResetOutcome> resetMember({
    required String accountId,
    required String actorId,
  }) async {
    final result = await _member.resetPassword(
      accountId: accountId,
      actorId: actorId,
    );
    return PasswordResetOutcome(
      accountLabel: result.account.loginIdentifier,
      temporaryPassword: result.temporaryPassword,
      accountType: AppConstants.accountTypeMember,
    );
  }
}

class PasswordResetOutcome {
  const PasswordResetOutcome({
    required this.accountLabel,
    required this.temporaryPassword,
    required this.accountType,
  });

  final String accountLabel;
  final String temporaryPassword;
  final String accountType;
}

/// Changement mot de passe staff admin.
class AdminPasswordChangeService {
  AdminPasswordChangeService({
    PasswordChangeService? passwordChange,
  }) : _passwordChange = passwordChange ?? PasswordChangeService();

  final PasswordChangeService _passwordChange;

  String? validate({
    required String newPassword,
    required String confirmPassword,
  }) {
    return _passwordChange.validate(
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
  }

  Future<String?> changePassword({
    required String accountId,
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return _passwordChange.changeStaffPassword(
      accountId: accountId,
      oldPassword: oldPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
  }
}
