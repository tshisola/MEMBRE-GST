import '../../app/constants.dart';
import '../../shared/models/member_account_model.dart';

/// Hides creator and admin metadata from member-facing UI.
class CreatorVisibilityGuard {
  CreatorVisibilityGuard._();

  static Map<String, dynamic> sanitizeForMember(Map<String, dynamic> data) {
    final copy = Map<String, dynamic>.from(data);
    copy.remove('created_by');
    copy.remove('createdBy');
    copy.remove('created_by_name');
    copy.remove('admin_notes');
    return copy;
  }

  static MemberAccount sanitizeAccount(MemberAccount account) {
    return MemberAccount(
      id: account.id,
      memberId: account.memberId,
      loginIdentifier: account.loginIdentifier,
      email: account.email,
      phone: account.phone,
      departmentId: account.departmentId,
      isActive: account.isActive,
      mustChangePassword: account.mustChangePassword,
      createdAt: account.createdAt,
      updatedAt: account.updatedAt,
      city: account.city,
    );
  }

  static bool canViewCreator(String? role) =>
      role == AppConstants.roleAdminGeneral;
}

class PrivacyGuard {
  PrivacyGuard._();

  static bool memberCanSelfCheckIn({
    required String? accountType,
    required String? sessionMemberId,
    required String targetMemberId,
  }) {
    if (accountType != AppConstants.accountTypeMember) return true;
    return sessionMemberId != targetMemberId;
  }
}

class MemberScopeGuard {
  MemberScopeGuard._();

  static bool canAccessMemberSpace(String? accountType) =>
      accountType == AppConstants.accountTypeMember;

  static bool canAccessAdminSpace(String? accountType, String? role) {
    if (accountType == AppConstants.accountTypeMember) return false;
    return role != null && AppConstants.adminRoles.contains(role);
  }
}
