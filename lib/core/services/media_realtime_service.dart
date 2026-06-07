import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/models/attendance_model.dart';
import '../../shared/models/department_model.dart';
import '../../shared/models/member_model.dart';
import '../../shared/models/role_models.dart';
import 'lubumbashi_branding_service.dart';
import 'media_firestore_constants.dart';

/// Firestore real-time streams for media attendance and lists (Lubumbashi).
class MediaRealtimeService {
  MediaRealtimeService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<MediaAttendanceRecord>> attendanceStream({
    DateTime? from,
    DateTime? to,
    int limit = 200,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(MediaFirestoreCollections.attendance)
        .where('type', isEqualTo: 'record')
        .where('city', isEqualTo: LubumbashiBrandingService.city)
        .orderBy('date', descending: true)
        .limit(limit);

    if (from != null) {
      query = query.where(
        'date',
        isGreaterThanOrEqualTo: from.toIso8601String(),
      );
    }
    if (to != null) {
      query = query.where('date', isLessThan: to.toIso8601String());
    }

    return query.snapshots().map(
          (snap) => snap.docs
              .map((d) => MediaAttendanceRecord.fromMap(d.data(), id: d.id))
              .toList(),
        );
  }

  Stream<List<MediaAttendanceSession>> openSessionsStream() {
    return _firestore
        .collection(MediaFirestoreCollections.attendance)
        .where('type', isEqualTo: 'session')
        .where('isOpen', isEqualTo: true)
        .where('city', isEqualTo: LubumbashiBrandingService.city)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => MediaAttendanceSession.fromMap(d.data(), id: d.id))
              .toList(),
        );
  }

  Stream<List<MediaSundayList>> listsStream({bool manualOnly = false}) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(MediaFirestoreCollections.lists)
        .where('city', isEqualTo: LubumbashiBrandingService.city)
        .orderBy('serviceDate', descending: true)
        .limit(100);

    if (manualOnly) {
      query = query.where('isManual', isEqualTo: true);
    }

    return query.snapshots().map(
          (snap) => snap.docs
              .map((d) => MediaSundayList.fromMap(d.data(), id: d.id))
              .toList(),
        );
  }

  Stream<MediaSundayList?> listStream(String listId) {
    return _firestore
        .collection(MediaFirestoreCollections.lists)
        .doc(listId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return MediaSundayList.fromMap(doc.data()!, id: doc.id);
    });
  }

  Stream<List<Member>> membersStream() {
    return _firestore
        .collection(MediaFirestoreCollections.members)
        .where('departmentId', isEqualTo: Member.mediaDepartmentId)
        .where('commune', isEqualTo: Member.defaultCommune)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => Member.fromMap(d.data(), id: d.id))
              .toList(),
        );
  }

  Stream<List<MediaRoleAssignment>> rolesStream() {
    return _firestore
        .collection(MediaFirestoreCollections.roles)
        .where('city', isEqualTo: LubumbashiBrandingService.city)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => MediaRoleAssignment.fromMap(d.data()))
              .toList(),
        );
  }
}
