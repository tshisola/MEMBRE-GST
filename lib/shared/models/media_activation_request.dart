import '../../app/constants.dart';

class MediaActivationRequest {
  const MediaActivationRequest({
    required this.id,
    required this.firebaseUid,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.status,
    this.departmentName = AppConstants.departmentNameMedia,
    this.requestedRole = AppConstants.requestedRoleMediaMember,
    this.provider = AppConstants.authProviderGoogle,
    this.activationCompleted = false,
    this.rejectionReason,
    this.reviewedBy,
    this.reviewedAt,
    this.memberId,
    required this.createdAt,
    required this.updatedAt,
    this.syncedAt,
  });

  final String id;
  final String firebaseUid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String status;
  final String departmentName;
  final String requestedRole;
  final String provider;
  final bool activationCompleted;
  final String? rejectionReason;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? memberId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? syncedAt;

  bool get isPending => status == AppConstants.activationStatusPending;
  bool get isActive => status == AppConstants.activationStatusActive;
  bool get isRejected => status == AppConstants.activationStatusRejected;

  Map<String, dynamic> toMap() => {
        'id': id,
        'firebase_uid': firebaseUid,
        'email': email,
        'display_name': displayName,
        'photo_url': photoUrl,
        'status': status,
        'department_name': departmentName,
        'requested_role': requestedRole,
        'provider': provider,
        'activation_completed': activationCompleted ? 1 : 0,
        'rejection_reason': rejectionReason,
        'reviewed_by': reviewedBy,
        'reviewed_at': reviewedAt?.toIso8601String(),
        'member_id': memberId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'synced_at': syncedAt?.toIso8601String(),
      };

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'firebaseUid': firebaseUid,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'provider': provider,
        'departmentName': departmentName,
        'requestedRole': requestedRole,
        'status': status,
        'activationCompleted': activationCompleted,
        'rejectionReason': rejectionReason,
        'reviewedBy': reviewedBy,
        'reviewedAt': reviewedAt?.toIso8601String(),
        'memberId': memberId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'city': AppConstants.city,
      };

  factory MediaActivationRequest.fromMap(Map<String, dynamic> map) {
    return MediaActivationRequest(
      id: map['id'] as String? ?? map['firebase_uid'] as String,
      firebaseUid: map['firebase_uid'] as String? ?? map['firebaseUid'] as String,
      email: map['email'] as String,
      displayName: map['display_name'] as String? ?? map['displayName'] as String?,
      photoUrl: map['photo_url'] as String? ?? map['photoUrl'] as String?,
      status: map['status'] as String? ?? AppConstants.activationStatusPending,
      departmentName: map['department_name'] as String? ??
          map['departmentName'] as String? ??
          AppConstants.departmentNameMedia,
      requestedRole: map['requested_role'] as String? ??
          map['requestedRole'] as String? ??
          AppConstants.requestedRoleMediaMember,
      provider: map['provider'] as String? ?? AppConstants.authProviderGoogle,
      activationCompleted: (map['activation_completed'] as int? ?? 0) == 1 ||
          (map['activationCompleted'] as bool? ?? false),
      rejectionReason:
          map['rejection_reason'] as String? ?? map['rejectionReason'] as String?,
      reviewedBy: map['reviewed_by'] as String? ?? map['reviewedBy'] as String?,
      reviewedAt: _parseDate(map['reviewed_at'] ?? map['reviewedAt']),
      memberId: map['member_id'] as String? ?? map['memberId'] as String?,
      createdAt: _parseDate(map['created_at'] ?? map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updated_at'] ?? map['updatedAt']) ?? DateTime.now(),
      syncedAt: _parseDate(map['synced_at'] ?? map['syncedAt']),
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}
