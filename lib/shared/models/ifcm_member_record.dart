/// IFCM member record — local SQLite + Firestore sync.
library;

class IfcmMemberRecord {
  const IfcmMemberRecord({
    required this.id,
    required this.localId,
    required this.memberCode,
    required this.qrCodeId,
    required this.qrData,
    required this.firstName,
    required this.lastName,
    this.fullName,
    this.phone,
    this.email,
    this.address,
    this.commune = 'Lubumbashi',
    this.departmentId,
    this.departmentName,
    this.pastorId,
    this.pastorName,
    this.discipleId,
    this.discipleName,
    this.leaderId,
    this.leaderName,
    this.createdBy,
    this.createdByRole,
    this.cloudId,
    this.role = 'member',
    this.city = 'Lubumbashi',
    this.isActive = true,
    this.isDeleted = false,
    this.deletedAt,
    this.deletedBy,
    this.deletedReason,
    this.syncStatus = 'local',
    this.createdAt,
    this.updatedAt,
    this.syncedAt,
    this.isMerged = false,
    this.mergedInto,
    this.mergedAt,
  });

  final String id;
  final String localId;
  final String memberCode;
  final String qrCodeId;
  final String qrData;
  final String firstName;
  final String lastName;
  final String? fullName;
  final String? phone;
  final String? email;
  final String? address;
  final String commune;
  final String? departmentId;
  final String? departmentName;
  final String? pastorId;
  final String? pastorName;
  final String? discipleId;
  final String? discipleName;
  final String? leaderId;
  final String? leaderName;
  final String? createdBy;
  final String? createdByRole;
  final String? cloudId;
  final String role;
  final String city;
  final bool isActive;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? deletedBy;
  final String? deletedReason;
  final String syncStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? syncedAt;
  final bool isMerged;
  final String? mergedInto;
  final DateTime? mergedAt;

  String get displayName =>
      fullName?.trim().isNotEmpty == true
          ? fullName!
          : '$firstName $lastName'.trim();

  IfcmMemberRecord copyWith({
    String? cloudId,
    String? qrData,
    String? syncStatus,
    DateTime? syncedAt,
    DateTime? updatedAt,
    bool? isDeleted,
    bool? isActive,
    DateTime? deletedAt,
    String? deletedBy,
    String? deletedReason,
    String? phone,
    String? email,
    String? address,
    String? departmentId,
    String? departmentName,
    String? pastorName,
    String? discipleName,
    bool? isMerged,
    String? mergedInto,
    DateTime? mergedAt,
    bool clearDeletionMeta = false,
  }) {
    return IfcmMemberRecord(
      id: id,
      localId: localId,
      memberCode: memberCode,
      qrCodeId: qrCodeId,
      qrData: qrData ?? this.qrData,
      firstName: firstName,
      lastName: lastName,
      fullName: fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      commune: commune,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      pastorId: pastorId,
      pastorName: pastorName ?? this.pastorName,
      discipleId: discipleId,
      discipleName: discipleName ?? this.discipleName,
      leaderId: leaderId,
      leaderName: leaderName,
      createdBy: createdBy,
      createdByRole: createdByRole,
      cloudId: cloudId ?? this.cloudId,
      role: role,
      city: city,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: clearDeletionMeta ? null : (deletedAt ?? this.deletedAt),
      deletedBy: clearDeletionMeta ? null : (deletedBy ?? this.deletedBy),
      deletedReason:
          clearDeletionMeta ? null : (deletedReason ?? this.deletedReason),
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      isMerged: isMerged ?? this.isMerged,
      mergedInto: mergedInto ?? this.mergedInto,
      mergedAt: mergedAt ?? this.mergedAt,
    );
  }

  factory IfcmMemberRecord.fromSqlite(Map<String, Object?> row) {
    return IfcmMemberRecord(
      id: row['id'] as String,
      localId: row['local_id'] as String? ?? row['id'] as String,
      memberCode: row['member_code'] as String? ?? '',
      qrCodeId: row['qr_code_id'] as String? ?? '',
      qrData: row['qr_data'] as String? ?? '',
      firstName: row['first_name'] as String? ?? '',
      lastName: row['last_name'] as String? ?? '',
      fullName: row['full_name'] as String?,
      phone: row['phone'] as String?,
      email: row['email'] as String?,
      address: row['address'] as String?,
      commune: row['commune'] as String? ?? 'Lubumbashi',
      departmentId: row['department_id'] as String?,
      departmentName: row['department_name'] as String?,
      pastorId: row['pastor_id'] as String?,
      pastorName: row['pastor_name'] as String?,
      discipleId: row['disciple_id'] as String?,
      discipleName: row['disciple_name'] as String?,
      leaderId: row['leader_id'] as String?,
      leaderName: row['leader_name'] as String?,
      createdBy: row['created_by'] as String?,
      createdByRole: row['created_by_role'] as String?,
      cloudId: row['cloud_id'] as String?,
      role: row['role'] as String? ?? 'member',
      city: row['city'] as String? ?? 'Lubumbashi',
      isActive: (row['is_active'] as int? ?? 1) == 1,
      isDeleted: (row['is_deleted'] as int? ?? 0) == 1,
      deletedAt: _dt(row['deleted_at']),
      deletedBy: row['deleted_by'] as String?,
      deletedReason: row['deleted_reason'] as String?,
      syncStatus: row['sync_status'] as String? ?? 'local',
      createdAt: _dt(row['created_at']),
      updatedAt: _dt(row['updated_at']),
      syncedAt: _dt(row['synced_at']),
      isMerged: (row['is_merged'] as int? ?? 0) == 1,
      mergedInto: row['merged_into'] as String?,
      mergedAt: _dt(row['merged_at']),
    );
  }

  Map<String, dynamic> toSqlite() {
    final now = DateTime.now().toIso8601String();
    return {
      'id': id,
      'local_id': localId,
      'member_code': memberCode,
      'qr_code_id': qrCodeId,
      'qr_data': qrData,
      'first_name': firstName,
      'last_name': lastName,
      'full_name': displayName,
      'phone': phone,
      'email': email,
      'address': address,
      'commune': commune,
      'department_id': departmentId,
      'department_name': departmentName,
      'pastor_id': pastorId,
      'pastor_name': pastorName,
      'disciple_id': discipleId,
      'disciple_name': discipleName,
      'leader_id': leaderId,
      'leader_name': leaderName,
      'created_by': createdBy,
      'created_by_role': createdByRole,
      'cloud_id': cloudId,
      'role': role,
      'city': city,
      'is_active': isActive ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'deleted_at': deletedAt?.toIso8601String(),
      'deleted_by': deletedBy,
      'deleted_reason': deletedReason,
      'sync_status': syncStatus,
      'created_at': createdAt?.toIso8601String() ?? now,
      'updated_at': updatedAt?.toIso8601String() ?? now,
      'synced_at': syncedAt?.toIso8601String(),
      'is_merged': isMerged ? 1 : 0,
      'merged_into': mergedInto,
      'merged_at': mergedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore({bool includeCreatedBy = true}) {
    return {
      'localId': localId,
      'memberCode': memberCode,
      'qrCodeId': qrCodeId,
      'qrData': qrData,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': displayName,
      'phone': phone,
      'email': email,
      'address': address,
      'commune': commune,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'pastorId': pastorId,
      'pastorName': pastorName,
      'discipleId': discipleId,
      'discipleName': discipleName,
      'leaderId': leaderId,
      'leaderName': leaderName,
      if (includeCreatedBy) 'createdBy': createdBy,
      if (includeCreatedBy) 'createdByRole': createdByRole,
      'isActive': isActive,
      'isDeleted': isDeleted,
      if (includeCreatedBy) ...{
        'deletedAt': deletedAt?.toIso8601String(),
        'deletedBy': deletedBy,
        'deletedReason': deletedReason,
      },
      'syncStatus': syncStatus,
      'city': city,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'syncedAt': syncedAt?.toIso8601String(),
    };
  }

  /// Member-facing view — never includes createdBy.
  Map<String, dynamic> toMemberView() {
    final map = toFirestore(includeCreatedBy: false);
    map.remove('createdBy');
    map.remove('createdByRole');
    return map;
  }

  factory IfcmMemberRecord.fromFirestore(String docId, Map<String, dynamic> data) {
    return IfcmMemberRecord(
      id: data['localId'] as String? ?? docId,
      localId: data['localId'] as String? ?? docId,
      memberCode: data['memberCode'] as String? ?? '',
      qrCodeId: data['qrCodeId'] as String? ?? '',
      qrData: data['qrData'] as String? ?? '',
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      fullName: data['fullName'] as String?,
      phone: data['phone'] as String?,
      email: data['email'] as String?,
      address: data['address'] as String?,
      commune: data['commune'] as String? ?? 'Lubumbashi',
      departmentId: data['departmentId'] as String?,
      departmentName: data['departmentName'] as String?,
      pastorId: data['pastorId'] as String?,
      pastorName: data['pastorName'] as String?,
      discipleId: data['discipleId'] as String?,
      discipleName: data['discipleName'] as String?,
      leaderId: data['leaderId'] as String?,
      leaderName: data['leaderName'] as String?,
      createdBy: data['createdBy'] as String?,
      createdByRole: data['createdByRole'] as String?,
      cloudId: docId,
      role: data['role'] as String? ?? 'member',
      city: data['city'] as String? ?? 'Lubumbashi',
      isActive: data['isActive'] as bool? ?? true,
      isDeleted: data['isDeleted'] as bool? ?? false,
      deletedAt: _dt(data['deletedAt']),
      deletedBy: data['deletedBy'] as String?,
      deletedReason: data['deletedReason'] as String?,
      syncStatus: data['syncStatus'] as String? ?? 'synced',
      createdAt: _dt(data['createdAt']),
      updatedAt: _dt(data['updatedAt']),
      syncedAt: _dt(data['syncedAt']),
    );
  }

  static DateTime? _dt(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());
}
