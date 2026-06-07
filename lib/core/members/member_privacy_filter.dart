import '../../shared/models/ifcm_member_record.dart';
import 'member_visibility_service.dart';
import 'pointage_member_view.dart';

/// DTO pointage — sans createdBy ni données admin internes.
class AttendanceMemberDto {
  const AttendanceMemberDto({
    required this.id,
    required this.displayName,
    required this.memberCode,
    this.phone,
    this.departmentName,
    this.qrData,
    this.syncStatus,
    this.isActive = true,
  });

  final String id;
  final String displayName;
  final String memberCode;
  final String? phone;
  final String? departmentName;
  final String? qrData;
  final String? syncStatus;
  final bool isActive;

  factory AttendanceMemberDto.fromView(PointageMemberView view) {
    return AttendanceMemberDto(
      id: view.id,
      displayName: view.name,
      memberCode: view.memberCode,
      phone: view.phone.isNotEmpty ? view.phone : null,
      departmentName: view.departmentName,
      qrData: view.qrData,
      syncStatus: view.syncStatus,
      isActive: view.isActive,
    );
  }
}

/// DTO admin complet (sans filtre créateur pour admins complets).
class AdminMemberDto {
  const AdminMemberDto({
    required this.id,
    required this.displayName,
    required this.memberCode,
    this.phone,
    this.email,
    this.departmentName,
    this.syncStatus,
    this.isActive = true,
    this.createdBy,
  });

  final String id;
  final String displayName;
  final String memberCode;
  final String? phone;
  final String? email;
  final String? departmentName;
  final String? syncStatus;
  final bool isActive;
  final String? createdBy;

  factory AdminMemberDto.fromRecord(IfcmMemberRecord record) {
    return AdminMemberDto(
      id: record.id,
      displayName: record.displayName,
      memberCode: record.memberCode,
      phone: record.phone,
      email: record.email,
      departmentName: record.departmentName,
      syncStatus: record.syncStatus,
      isActive: record.isActive,
      createdBy: record.createdBy,
    );
  }
}

/// Filtre les champs sensibles selon le rôle connecté.
class MemberPrivacyFilter {
  MemberPrivacyFilter._();

  static AttendanceMemberDto forAttendance(PointageMemberView view) =>
      AttendanceMemberDto.fromView(view);

  static dynamic mapForRole({
    required IfcmMemberRecord record,
    required String? role,
  }) {
    if (MemberVisibilityService.shouldHideSensitiveFields(role)) {
      return AttendanceMemberDto.fromView(PointageMemberView.fromRecord(record));
    }
    return AdminMemberDto.fromRecord(record);
  }
}

/// Alias demandés.
typedef MemberSafeDtoMapper = MemberPrivacyFilter;
typedef MemberPrivacyGuardFilter = MemberPrivacyFilter;
