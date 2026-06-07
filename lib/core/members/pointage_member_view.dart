import '../../shared/models/member_model.dart';
import '../../shared/models/ifcm_member_record.dart';

/// Vue membre enrichie pour le pointage (SQLite local-first).
class PointageMemberView {
  const PointageMemberView({
    required this.id,
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.departmentId,
    required this.role,
    required this.commune,
    required this.memberCode,
    required this.syncStatus,
    this.email,
    this.qrData,
    this.departmentName,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String firstName;
  final String lastName;
  final String phone;
  final String departmentId;
  final String role;
  final String commune;
  final String memberCode;
  final String syncStatus;
  final String? email;
  final String? qrData;
  final String? departmentName;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasQr => qrData != null && qrData!.isNotEmpty;
  bool get isPendingSync =>
      syncStatus == 'pending' || syncStatus == 'local';

  Member toMember() => Member(
        id: id,
        name: name,
        phone: phone,
        departmentId: departmentId,
        role: role,
        commune: commune,
        email: email,
        isActive: isActive,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory PointageMemberView.fromRecord(IfcmMemberRecord r) {
    return PointageMemberView(
      id: r.id,
      name: r.displayName,
      firstName: r.firstName,
      lastName: r.lastName,
      phone: r.phone ?? '',
      departmentId: r.departmentId ?? Member.mediaDepartmentId,
      role: r.role,
      commune: r.commune,
      memberCode: r.memberCode,
      syncStatus: r.syncStatus,
      email: r.email,
      qrData: r.qrData,
      departmentName: r.departmentName,
      isActive: r.isActive,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    );
  }

  bool matchesQuery(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    final tokens = [
      name,
      firstName,
      lastName,
      phone,
      memberCode,
      qrData ?? '',
      departmentId,
      departmentName ?? '',
      commune,
      role,
      email ?? '',
    ];
    return tokens.any((t) => t.toLowerCase().contains(q));
  }
}
