/// Snapshot d'un membre supprimé (corbeille locale).
library;

class DeletedMemberRecord {
  const DeletedMemberRecord({
    required this.id,
    required this.memberId,
    this.memberCode,
    this.fullName,
    this.phone,
    this.departmentId,
    this.departmentName,
    this.deletedBy,
    this.deletedByRole,
    this.deletedReason,
    required this.deletedAt,
    this.restoreAvailable = true,
    this.syncedAt,
  });

  final String id;
  final String memberId;
  final String? memberCode;
  final String? fullName;
  final String? phone;
  final String? departmentId;
  final String? departmentName;
  final String? deletedBy;
  final String? deletedByRole;
  final String? deletedReason;
  final DateTime deletedAt;
  final bool restoreAvailable;
  final DateTime? syncedAt;

  factory DeletedMemberRecord.fromSqlite(Map<String, Object?> row) {
    return DeletedMemberRecord(
      id: row['id'] as String,
      memberId: row['member_id'] as String,
      memberCode: row['member_code'] as String?,
      fullName: row['full_name'] as String?,
      phone: row['phone'] as String?,
      departmentId: row['department_id'] as String?,
      departmentName: row['department_name'] as String?,
      deletedBy: row['deleted_by'] as String?,
      deletedByRole: row['deleted_by_role'] as String?,
      deletedReason: row['deleted_reason'] as String?,
      deletedAt: DateTime.parse(row['deleted_at'] as String),
      restoreAvailable: (row['restore_available'] as int? ?? 1) == 1,
      syncedAt: row['synced_at'] != null
          ? DateTime.tryParse(row['synced_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toSqlite() {
    return {
      'id': id,
      'member_id': memberId,
      'member_code': memberCode,
      'full_name': fullName,
      'phone': phone,
      'department_id': departmentId,
      'department_name': departmentName,
      'deleted_by': deletedBy,
      'deleted_by_role': deletedByRole,
      'deleted_reason': deletedReason,
      'deleted_at': deletedAt.toIso8601String(),
      'restore_available': restoreAvailable ? 1 : 0,
      'synced_at': syncedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'memberId': memberId,
      'memberCode': memberCode,
      'fullName': fullName,
      'phone': phone,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'deletedBy': deletedBy,
      'deletedByRole': deletedByRole,
      'deletedReason': deletedReason,
      'deletedAt': deletedAt.toIso8601String(),
      'restoreAvailable': restoreAvailable,
      'city': 'Lubumbashi',
    };
  }
}
