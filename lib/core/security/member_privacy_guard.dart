import '../../shared/models/ifcm_member_record.dart';

/// Profil membre sans données sensibles (créateur, admins internes).
class MemberSafeProfileDTO {
  const MemberSafeProfileDTO({
    required this.memberId,
    required this.firstName,
    required this.lastName,
    this.departmentId,
    this.memberCode,
    this.email,
    this.phone,
    this.pastorName,
    this.discipleName,
    this.leaderName,
  });

  final String memberId;
  final String firstName;
  final String lastName;
  final String? departmentId;
  final String? memberCode;
  final String? email;
  final String? phone;
  final String? pastorName;
  final String? discipleName;
  final String? leaderName;

  factory MemberSafeProfileDTO.fromRecord(IfcmMemberRecord record) {
    return MemberSafeProfileDTO(
      memberId: record.id,
      firstName: record.firstName,
      lastName: record.lastName,
      departmentId: record.departmentId,
      memberCode: record.memberCode,
      email: record.email,
      phone: record.phone,
      pastorName: record.pastorName,
      discipleName: record.discipleName,
      leaderName: record.leaderName,
    );
  }

  Map<String, dynamic> toMap() => {
        'memberId': memberId,
        'firstName': firstName,
        'lastName': lastName,
        if (departmentId != null) 'departmentId': departmentId,
        if (memberCode != null) 'memberCode': memberCode,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (pastorName != null) 'pastorName': pastorName,
        if (discipleName != null) 'discipleName': discipleName,
        if (leaderName != null) 'leaderName': leaderName,
      };
}

/// Masque créateur, admins internes et métadonnées sensibles.
class MemberPrivacyGuard {
  MemberPrivacyGuard._();

  static const _hiddenStaffNames = {
    'verdick',
    'verdick yav',
    'jeno',
    'mechack',
    'bisibo',
    'verdicky9@gmail.com',
  };

  static Map<String, dynamic> sanitizeMemberMap(Map<String, dynamic> source) {
    final copy = Map<String, dynamic>.from(source);
    for (final key in [
      'createdBy',
      'created_by',
      'activatedBy',
      'activated_by',
      'reviewedBy',
      'reviewed_by',
      'permissions',
      'roles',
      'role',
      'audit',
      'stackTrace',
      'error',
    ]) {
      copy.remove(key);
    }
    for (final entry in copy.entries.toList()) {
      if (entry.value is String &&
          _hiddenStaffNames.contains(entry.value.toString().toLowerCase())) {
        copy.remove(entry.key);
      }
    }
    return copy;
  }
}

class CreatorHiddenGuard {
  CreatorHiddenGuard._();

  static Map<String, dynamic> stripCreator(Map<String, dynamic> data) {
    return MemberPrivacyGuard.sanitizeMemberMap(data);
  }
}

class AdminHiddenFromMemberGuard {
  AdminHiddenFromMemberGuard._();

  static bool isAdminSession({required String? accountType, required String? role}) {
    if (accountType == 'admin') return true;
    if (role == null) return false;
    return role.contains('admin') ||
        role.contains('operator') ||
        role.contains('chief') ||
        role.contains('pasteur') ||
        role.contains('disciple') ||
        role.contains('leader');
  }
}
