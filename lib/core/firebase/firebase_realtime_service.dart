import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app/constants.dart';
import 'firebase_initializer.dart';

/// Real-time Firestore listeners for media department collections.
class FirebaseRealtimeService {
  FirebaseRealtimeService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  bool get isAvailable => FirebaseInitializer.isInitialized;

  Stream<List<Map<String, dynamic>>> watchMediaAttendance({
    String? sessionDate,
  }) {
    return _watchMediaCollection(
      AppConstants.collectionMediaAttendance,
      extraFilter: sessionDate != null
          ? (query) => query.where('session_date', isEqualTo: sessionDate)
          : null,
    );
  }

  Stream<List<Map<String, dynamic>>> watchMediaLists() {
    return _watchMediaCollection(AppConstants.collectionMediaLists);
  }

  Stream<List<Map<String, dynamic>>> watchMediaRoles() {
    return _watchMediaCollection(AppConstants.collectionMediaRoles);
  }

  Stream<List<Map<String, dynamic>>> watchMediaMembers() {
    if (!isAvailable) return Stream.value([]);

    return _firestore
        .collection(AppConstants.collectionMembers)
        .where('department_id', isEqualTo: AppConstants.mediaDepartmentId)
        .where('city', isEqualTo: AppConstants.city)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  /// Real-time listener for all IFCM members (admin sync).
  Stream<List<Map<String, dynamic>>> watchIfcmMembers() {
    if (!isAvailable) return Stream.value([]);

    return _firestore
        .collection(AppConstants.collectionMembers)
        .where('city', isEqualTo: AppConstants.city)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((d) => (d.data()['isDeleted'] as bool? ?? false) == false)
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  Stream<Map<String, dynamic>?> watchDocument(
    String collection,
    String documentId,
  ) {
    if (!isAvailable) return Stream.value(null);

    return _firestore.collection(collection).doc(documentId).snapshots().map(
          (snapshot) =>
              snapshot.exists ? {'id': snapshot.id, ...snapshot.data()!} : null,
        );
  }

  Stream<List<Map<String, dynamic>>> _watchMediaCollection(
    String collection, {
    Query<Map<String, dynamic>> Function(
      Query<Map<String, dynamic>> query,
    )? extraFilter,
  }) {
    if (!isAvailable) return Stream.value([]);

    Query<Map<String, dynamic>> query = _firestore
        .collection(collection)
        .where('department_id', isEqualTo: AppConstants.mediaDepartmentId)
        .where('city', isEqualTo: AppConstants.city);

    if (extraFilter != null) {
      query = extraFilter(query);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }
}
