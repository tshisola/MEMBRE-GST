import '../../app/constants.dart';
import '../../shared/models/ifcm_member_record.dart';

/// Client-side permission guards for member data (mirrors Firestore rules).
class FirestoreMemberGuards {
  FirestoreMemberGuards._();

  static bool canCreateMember({required String? role, String? accountType}) {
    if (accountType == AppConstants.accountTypeMember) return false;
    if (role == null) return false;
    return AppConstants.adminRoles.contains(role);
  }

  static bool canReadMembers({required String? role, String? accountType}) {
    if (accountType == AppConstants.accountTypeMember) return false;
    return role != null && AppConstants.adminRoles.contains(role);
  }

  static bool canReadOwnMember({
    required String? role,
    required String? sessionMemberId,
    required String targetMemberId,
  }) {
    return role == AppConstants.roleMember && sessionMemberId == targetMemberId;
  }

  static bool canManageDepartmentMembers({
    required String? role,
    required String? userDepartmentId,
    required String? targetDepartmentId,
  }) {
    if (role == AppConstants.roleAdminGeneral) return true;
    if (role == AppConstants.roleDepartmentChief &&
        userDepartmentId != null &&
        userDepartmentId == targetDepartmentId) {
      return true;
    }
    return false;
  }

  /// Strips audit fields — member must never see creator.
  static Map<String, dynamic> hideCreatedByForMember(
    Map<String, dynamic> data,
  ) {
    final copy = Map<String, dynamic>.from(data);
    copy.remove('createdBy');
    copy.remove('createdByRole');
    copy.remove('created_by');
    copy.remove('created_by_role');
    return copy;
  }

  static Map<String, dynamic> toMemberFacingView(IfcmMemberRecord member) {
    return hideCreatedByForMember(member.toMemberView());
  }
}
