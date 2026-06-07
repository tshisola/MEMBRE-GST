/// Demande de suppression membre (validation admin requise).
library;

class MemberDeleteRequest {
  const MemberDeleteRequest({
    required this.id,
    required this.memberId,
    required this.requestedBy,
    this.requestedByRole,
    required this.reason,
    this.status = 'pending',
    this.approvedBy,
    this.approvedAt,
    required this.createdAt,
    this.syncedAt,
  });

  final String id;
  final String memberId;
  final String requestedBy;
  final String? requestedByRole;
  final String reason;
  final String status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime createdAt;
  final DateTime? syncedAt;

  bool get isPending => status == 'pending';

  factory MemberDeleteRequest.fromSqlite(Map<String, Object?> row) {
    return MemberDeleteRequest(
      id: row['id'] as String,
      memberId: row['member_id'] as String,
      requestedBy: row['requested_by'] as String,
      requestedByRole: row['requested_by_role'] as String?,
      reason: row['reason'] as String,
      status: row['status'] as String? ?? 'pending',
      approvedBy: row['approved_by'] as String?,
      approvedAt: row['approved_at'] != null
          ? DateTime.tryParse(row['approved_at'] as String)
          : null,
      createdAt: DateTime.parse(row['created_at'] as String),
      syncedAt: row['synced_at'] != null
          ? DateTime.tryParse(row['synced_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toSqlite() {
    return {
      'id': id,
      'member_id': memberId,
      'requested_by': requestedBy,
      'requested_by_role': requestedByRole,
      'reason': reason,
      'status': status,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'synced_at': syncedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'memberId': memberId,
      'requestedBy': requestedBy,
      'requestedByRole': requestedByRole,
      'reason': reason,
      'status': status,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'city': 'Lubumbashi',
    };
  }
}
