/// Member model for IFCM media department (Lubumbashi).
library;

class Member {
  const Member({
    required this.id,
    required this.name,
    required this.phone,
    required this.departmentId,
    required this.role,
    this.commune = 'Lubumbashi',
    this.email,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String phone;
  final String departmentId;
  final String role;
  final String commune;
  final String? email;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static const String defaultCommune = 'Lubumbashi';
  static const String mediaDepartmentId = 'media';

  Member copyWith({
    String? id,
    String? name,
    String? phone,
    String? departmentId,
    String? role,
    String? commune,
    String? email,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      departmentId: departmentId ?? this.departmentId,
      role: role ?? this.role,
      commune: commune ?? this.commune,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Member.fromMap(Map<String, dynamic> map, {String? id}) {
    return Member(
      id: id ?? map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      departmentId: map['departmentId'] as String? ?? mediaDepartmentId,
      role: map['role'] as String? ?? 'member',
      commune: map['commune'] as String? ?? defaultCommune,
      email: map['email'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'departmentId': departmentId,
      'role': role,
      'commune': commune,
      if (email != null) 'email': email,
      'isActive': isActive,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
