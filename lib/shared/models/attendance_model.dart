/// Media attendance records for IFCM Lubumbashi.
library;

enum MediaAttendanceStatus {
  present,
  absent,
  late,
  excused;

  String get label {
    switch (this) {
      case MediaAttendanceStatus.present:
        return 'Présent';
      case MediaAttendanceStatus.absent:
        return 'Absent';
      case MediaAttendanceStatus.late:
        return 'Retard';
      case MediaAttendanceStatus.excused:
        return 'Excusé';
    }
  }

  static MediaAttendanceStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'present':
      case 'présent':
      case 'presente':
        return MediaAttendanceStatus.present;
      case 'late':
      case 'retard':
        return MediaAttendanceStatus.late;
      case 'excused':
      case 'excusé':
      case 'excuse':
        return MediaAttendanceStatus.excused;
      case 'absent':
      default:
        return MediaAttendanceStatus.absent;
    }
  }
}

enum MediaSessionType {
  sundayService,
  rehearsal,
  specialEvent,
  training,
  other;

  String get label {
    switch (this) {
      case MediaSessionType.sundayService:
        return 'Culte du dimanche';
      case MediaSessionType.rehearsal:
        return 'Répétition';
      case MediaSessionType.specialEvent:
        return 'Événement spécial';
      case MediaSessionType.training:
        return 'Formation';
      case MediaSessionType.other:
        return 'Autre';
    }
  }

  static MediaSessionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'sunday_service':
      case 'sundayservice':
      case 'dimanche':
        return MediaSessionType.sundayService;
      case 'rehearsal':
      case 'repetition':
        return MediaSessionType.rehearsal;
      case 'special_event':
      case 'specialevent':
        return MediaSessionType.specialEvent;
      case 'training':
      case 'formation':
        return MediaSessionType.training;
      default:
        return MediaSessionType.other;
    }
  }
}

class MediaAttendanceRecord {
  const MediaAttendanceRecord({
    required this.id,
    required this.memberId,
    required this.date,
    required this.status,
    required this.sessionType,
    this.sessionId,
    this.notes,
    this.recordedBy,
    this.city = 'Lubumbashi',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String memberId;
  final DateTime date;
  final MediaAttendanceStatus status;
  final MediaSessionType sessionType;
  final String? sessionId;
  final String? notes;
  final String? recordedBy;
  final String city;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MediaAttendanceRecord copyWith({
    String? id,
    String? memberId,
    DateTime? date,
    MediaAttendanceStatus? status,
    MediaSessionType? sessionType,
    String? sessionId,
    String? notes,
    String? recordedBy,
    String? city,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MediaAttendanceRecord(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      date: date ?? this.date,
      status: status ?? this.status,
      sessionType: sessionType ?? this.sessionType,
      sessionId: sessionId ?? this.sessionId,
      notes: notes ?? this.notes,
      recordedBy: recordedBy ?? this.recordedBy,
      city: city ?? this.city,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory MediaAttendanceRecord.fromMap(Map<String, dynamic> map, {String? id}) {
    return MediaAttendanceRecord(
      id: id ?? map['id'] as String? ?? '',
      memberId: map['memberId'] as String? ?? '',
      date: _parseDate(map['date']) ?? DateTime.now(),
      status: MediaAttendanceStatus.fromString(
        map['status'] as String? ?? 'absent',
      ),
      sessionType: MediaSessionType.fromString(
        map['sessionType'] as String? ?? 'other',
      ),
      sessionId: map['sessionId'] as String?,
      notes: map['notes'] as String?,
      recordedBy: map['recordedBy'] as String?,
      city: map['city'] as String? ?? 'Lubumbashi',
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'memberId': memberId,
      'date': date.toIso8601String(),
      'status': status.name,
      'sessionType': sessionType.name,
      if (sessionId != null) 'sessionId': sessionId,
      if (notes != null) 'notes': notes,
      if (recordedBy != null) 'recordedBy': recordedBy,
      'city': city,
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

class MediaAttendanceSession {
  const MediaAttendanceSession({
    required this.id,
    required this.date,
    required this.sessionType,
    this.title,
    this.city = 'Lubumbashi',
    this.isOpen = true,
    this.createdBy,
    this.createdAt,
  });

  final String id;
  final DateTime date;
  final MediaSessionType sessionType;
  final String? title;
  final String city;
  final bool isOpen;
  final String? createdBy;
  final DateTime? createdAt;

  factory MediaAttendanceSession.fromMap(Map<String, dynamic> map, {String? id}) {
    return MediaAttendanceSession(
      id: id ?? map['id'] as String? ?? '',
      date: MediaAttendanceRecord._parseDate(map['date']) ?? DateTime.now(),
      sessionType: MediaSessionType.fromString(
        map['sessionType'] as String? ?? 'sundayService',
      ),
      title: map['title'] as String?,
      city: map['city'] as String? ?? 'Lubumbashi',
      isOpen: map['isOpen'] as bool? ?? true,
      createdBy: map['createdBy'] as String?,
      createdAt: MediaAttendanceRecord._parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'sessionType': sessionType.name,
      if (title != null) 'title': title,
      'city': city,
      'isOpen': isOpen,
      if (createdBy != null) 'createdBy': createdBy,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }
}
