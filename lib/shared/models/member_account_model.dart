/// Member account models for IFCM Lubumbashi auth system.
library;

class MemberAccount {
  const MemberAccount({
    required this.id,
    required this.memberId,
    required this.loginIdentifier,
    this.email,
    this.phone,
    this.departmentId,
    this.isActive = true,
    this.mustChangePassword = true,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.city = 'Lubumbashi',
    this.passwordHash,
    this.passwordSalt,
  });

  final String id;
  final String memberId;
  final String loginIdentifier;
  final String? email;
  final String? phone;
  final String? departmentId;
  final bool isActive;
  final bool mustChangePassword;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String city;
  final String? passwordHash;
  final String? passwordSalt;

  factory MemberAccount.fromMap(Map<String, dynamic> map, {String? id}) {
    return MemberAccount(
      id: id ?? map['id'] as String? ?? '',
      memberId: map['member_id'] as String? ?? map['memberId'] as String? ?? '',
      loginIdentifier: map['login_identifier'] as String? ??
          map['loginIdentifier'] as String? ??
          '',
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      departmentId: map['department_id'] as String? ?? map['departmentId'] as String?,
      isActive: (map['is_active'] ?? map['isActive'] ?? 1) == 1 ||
          map['isActive'] == true,
      mustChangePassword: (map['must_change_password'] ??
              map['mustChangePassword'] ??
              1) ==
          1 ||
          map['mustChangePassword'] == true,
      createdBy: map['created_by'] as String? ?? map['createdBy'] as String?,
      createdAt: _dt(map['created_at'] ?? map['createdAt']),
      updatedAt: _dt(map['updated_at'] ?? map['updatedAt']),
      city: map['city'] as String? ?? 'Lubumbashi',
      passwordHash: map['password_hash'] as String? ?? map['passwordHash'] as String?,
      passwordSalt: map['password_salt'] as String? ?? map['passwordSalt'] as String?,
    );
  }

  Map<String, dynamic> toMap({bool includeSecrets = false}) {
    return {
      'id': id,
      'member_id': memberId,
      'login_identifier': loginIdentifier,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (departmentId != null) 'department_id': departmentId,
      'is_active': isActive ? 1 : 0,
      'must_change_password': mustChangePassword ? 1 : 0,
      if (createdBy != null) 'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      'city': city,
      if (includeSecrets && passwordHash != null) 'password_hash': passwordHash,
      if (includeSecrets && passwordSalt != null) 'password_salt': passwordSalt,
    };
  }

  static DateTime? _dt(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());
}

class DepartmentManualList {
  const DepartmentManualList({
    required this.id,
    required this.departmentId,
    required this.departmentName,
    required this.listTitle,
    required this.entries,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.city = 'Lubumbashi',
  });

  final String id;
  final String departmentId;
  final String departmentName;
  final String listTitle;
  final List<DepartmentManualListEntry> entries;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String city;

  factory DepartmentManualList.fromMap(Map<String, dynamic> map, {String? id}) {
    final raw = map['entries'] as List<dynamic>? ?? [];
    return DepartmentManualList(
      id: id ?? map['id'] as String? ?? '',
      departmentId: map['department_id'] as String? ?? map['departmentId'] as String? ?? '',
      departmentName: map['department_name'] as String? ?? map['departmentName'] as String? ?? '',
      listTitle: map['list_title'] as String? ?? map['listTitle'] as String? ?? '',
      entries: raw
          .map((e) => DepartmentManualListEntry.fromMap(
              Map<String, dynamic>.from(e as Map)))
          .toList(),
      createdBy: map['created_by'] as String? ?? map['createdBy'] as String?,
      createdAt: MemberAccount._dt(map['created_at'] ?? map['createdAt']),
      updatedAt: MemberAccount._dt(map['updated_at'] ?? map['updatedAt']),
      city: map['city'] as String? ?? 'Lubumbashi',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'department_id': departmentId,
        'department_name': departmentName,
        'list_title': listTitle,
        'entries': entries.map((e) => e.toMap()).toList(),
        if (createdBy != null) 'created_by': createdBy,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
        'city': city,
      };
}

class DepartmentManualListEntry {
  const DepartmentManualListEntry({
    required this.memberId,
    required this.memberName,
    this.notes,
    this.sortOrder = 0,
  });

  final String memberId;
  final String memberName;
  final String? notes;
  final int sortOrder;

  factory DepartmentManualListEntry.fromMap(Map<String, dynamic> map) {
    return DepartmentManualListEntry(
      memberId: map['member_id'] as String? ?? map['memberId'] as String? ?? '',
      memberName: map['member_name'] as String? ?? map['memberName'] as String? ?? '',
      notes: map['notes'] as String?,
      sortOrder: map['sort_order'] as int? ?? map['sortOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'member_id': memberId,
        'member_name': memberName,
        if (notes != null) 'notes': notes,
        'sort_order': sortOrder,
      };
}
