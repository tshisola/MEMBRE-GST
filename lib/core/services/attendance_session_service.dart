import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../shared/models/attendance_model.dart';
import '../../shared/models/role_models.dart';
import 'lubumbashi_branding_service.dart';
import 'media_attendance_permission_service.dart';
import 'media_firestore_constants.dart';

/// Creates and manages media attendance sessions (Lubumbashi).
class AttendanceSessionService {
  AttendanceSessionService({
    FirebaseFirestore? firestore,
    MediaAttendancePermissionService? permissionService,
    Uuid? uuid,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _permissions = permissionService ?? const MediaAttendancePermissionService(),
        _uuid = uuid ?? const Uuid();

  final FirebaseFirestore _firestore;
  final MediaAttendancePermissionService _permissions;
  final Uuid _uuid;

  CollectionReference<Map<String, dynamic>> get _sessionsRef =>
      _firestore.collection(MediaFirestoreCollections.attendance);

  Future<MediaAttendanceSession> createSession({
    required UserRole actor,
    required DateTime date,
    required MediaSessionType sessionType,
    String? title,
  }) async {
    if (!_permissions.canOpenAttendanceSession(actor)) {
      throw StateError('Permission refusée: ouverture de session pointage.');
    }

    final id = _uuid.v4();
    final session = MediaAttendanceSession(
      id: id,
      date: date,
      sessionType: sessionType,
      title: title ??
          '${sessionType.label} — ${LubumbashiBrandingService.city}',
      city: LubumbashiBrandingService.city,
      isOpen: true,
      createdBy: actor.uid,
      createdAt: DateTime.now(),
    );

    await _sessionsRef.doc(id).set({
      ...session.toMap(),
      'type': 'session',
      'departmentId': 'media',
    });
    return session;
  }

  Future<void> closeSession({
    required UserRole actor,
    required String sessionId,
  }) async {
    if (!_permissions.canCloseAttendanceSession(actor)) {
      throw StateError('Permission refusée: fermeture de session.');
    }
    await _sessionsRef.doc(sessionId).update({
      'isOpen': false,
      'closedAt': FieldValue.serverTimestamp(),
      'closedBy': actor.uid,
    });
  }

  Future<MediaAttendanceRecord> recordAttendance({
    required UserRole actor,
    required String sessionId,
    required String memberId,
    required MediaAttendanceStatus status,
    required MediaSessionType sessionType,
    String? notes,
    DateTime? date,
  }) async {
    if (!_permissions.canTakeAttendance(actor)) {
      throw StateError('Permission refusée: enregistrement pointage.');
    }

    final id = _uuid.v4();
    final record = MediaAttendanceRecord(
      id: id,
      memberId: memberId,
      date: date ?? DateTime.now(),
      status: status,
      sessionType: sessionType,
      sessionId: sessionId,
      notes: notes,
      recordedBy: actor.uid,
      city: LubumbashiBrandingService.city,
      createdAt: DateTime.now(),
    );

    await _sessionsRef.doc(id).set({
      ...record.toMap(),
      'type': 'record',
      'departmentId': 'media',
    });
    return record;
  }

  Stream<List<MediaAttendanceSession>> watchOpenSessions() {
    return _sessionsRef
        .where('type', isEqualTo: 'session')
        .where('isOpen', isEqualTo: true)
        .where('city', isEqualTo: LubumbashiBrandingService.city)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => MediaAttendanceSession.fromMap(d.data(), id: d.id))
            .toList());
  }

  Stream<List<MediaAttendanceRecord>> watchSessionRecords(String sessionId) {
    return _sessionsRef
        .where('type', isEqualTo: 'record')
        .where('sessionId', isEqualTo: sessionId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => MediaAttendanceRecord.fromMap(d.data(), id: d.id))
            .toList());
  }

  Future<List<MediaAttendanceRecord>> getRecordsForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final snap = await _sessionsRef
        .where('type', isEqualTo: 'record')
        .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('date', isLessThan: end.toIso8601String())
        .get();

    return snap.docs
        .map((d) => MediaAttendanceRecord.fromMap(d.data(), id: d.id))
        .toList();
  }
}
