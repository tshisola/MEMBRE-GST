/// Media roles and user permissions for IFCM Lubumbashi.
library;

enum MediaRole {
  chefMedia,
  operateurPointage,
  camera,
  son,
  projection,
  montage,
  streaming,
  photographe,
  assistant;

  String get label {
    switch (this) {
      case MediaRole.chefMedia:
        return 'Chef Média';
      case MediaRole.operateurPointage:
        return 'Opérateur pointage';
      case MediaRole.camera:
        return 'Caméra';
      case MediaRole.son:
        return 'Son';
      case MediaRole.projection:
        return 'Projection';
      case MediaRole.montage:
        return 'Montage';
      case MediaRole.streaming:
        return 'Streaming';
      case MediaRole.photographe:
        return 'Photographe';
      case MediaRole.assistant:
        return 'Assistant';
    }
  }

  static MediaRole fromString(String value) {
    final normalized = value.trim().toLowerCase();
    for (final role in MediaRole.values) {
      if (role.name.toLowerCase() == normalized) return role;
    }
    switch (normalized) {
      case 'chef_media':
      case 'chefmedia':
        return MediaRole.chefMedia;
      case 'operateur_pointage':
      case 'pointage':
        return MediaRole.operateurPointage;
      default:
        return MediaRole.assistant;
    }
  }
}

/// App-wide permission keys aligned with [firestore.rules].
class AppPermissions {
  static const canTakeAttendance = 'can_take_attendance';
  static const canManageMediaRoles = 'can_manage_media_roles';
  static const canDeleteMemberAccount = 'can_delete_member_account';
  static const canDeleteMember = 'can_delete_member';
  static const canExportMediaReports = 'can_export_media_reports';
  static const canManageMediaLists = 'can_manage_media_lists';
}

class UserRole {
  const UserRole({
    required this.uid,
    required this.roles,
    this.permissions = const [],
    this.departmentId,
    this.memberId,
    this.city = 'Lubumbashi',
    this.mediaRole,
  });

  final String uid;
  final List<String> roles;
  final List<String> permissions;
  final String? departmentId;
  final String? memberId;
  final String city;
  final MediaRole? mediaRole;

  bool hasRole(String role) => roles.contains(role);

  bool hasPermission(String permission) => permissions.contains(permission);

  bool get isAdminGeneral =>
      hasRole('admin_general') || hasRole('admin_general_owner');

  bool get isDepartmentChief =>
      hasRole('department_chief') && departmentId == 'media';

  bool get canTakeAttendance =>
      hasPermission(AppPermissions.canTakeAttendance) ||
      hasRole('attendance_operator') ||
      mediaRole == MediaRole.operateurPointage ||
      mediaRole == MediaRole.chefMedia;

  bool get canManageMediaRoles =>
      hasPermission(AppPermissions.canManageMediaRoles) ||
      isAdminGeneral ||
      mediaRole == MediaRole.chefMedia;

  bool get canManageMediaLists =>
      hasPermission(AppPermissions.canManageMediaLists) ||
      canManageMediaRoles;

  String? get primaryRole => roles.isNotEmpty ? roles.first : null;

  factory UserRole.fromMap(Map<String, dynamic> map, {required String uid}) {
    final rolesRaw = map['roles'] ?? map['role'];
    final List<String> roles;
    if (rolesRaw is List) {
      roles = rolesRaw.map((e) => e.toString()).toList();
    } else if (rolesRaw is String) {
      roles = [rolesRaw];
    } else {
      roles = [];
    }

    final permsRaw = map['permissions'];
    final List<String> permissions;
    if (permsRaw is List) {
      permissions = permsRaw.map((e) => e.toString()).toList();
    } else {
      permissions = [];
    }

    final mediaRoleRaw = map['mediaRole'] as String?;
    return UserRole(
      uid: uid,
      roles: roles,
      permissions: permissions,
      departmentId: map['departmentId'] as String?,
      memberId: map['memberId'] as String?,
      city: map['city'] as String? ?? 'Lubumbashi',
      mediaRole:
          mediaRoleRaw != null ? MediaRole.fromString(mediaRoleRaw) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roles': roles,
      'permissions': permissions,
      if (departmentId != null) 'departmentId': departmentId,
      if (memberId != null) 'memberId': memberId,
      'city': city,
      if (mediaRole != null) 'mediaRole': mediaRole!.name,
    };
  }
}

class MediaRoleAssignment {
  const MediaRoleAssignment({
    required this.memberId,
    required this.mediaRole,
    this.assignedAt,
    this.assignedBy,
    this.city = 'Lubumbashi',
  });

  final String memberId;
  final MediaRole mediaRole;
  final DateTime? assignedAt;
  final String? assignedBy;
  final String city;

  factory MediaRoleAssignment.fromMap(Map<String, dynamic> map) {
    return MediaRoleAssignment(
      memberId: map['memberId'] as String? ?? '',
      mediaRole: MediaRole.fromString(map['mediaRole'] as String? ?? ''),
      assignedAt: map['assignedAt'] != null
          ? DateTime.tryParse(map['assignedAt'].toString())
          : null,
      assignedBy: map['assignedBy'] as String?,
      city: map['city'] as String? ?? 'Lubumbashi',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'mediaRole': mediaRole.name,
      'city': city,
      if (assignedAt != null) 'assignedAt': assignedAt!.toIso8601String(),
      if (assignedBy != null) 'assignedBy': assignedBy,
    };
  }
}
