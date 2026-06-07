import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app/constants.dart';
import 'firebase_initializer.dart';

/// Generic Firestore CRUD operations.
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  bool get isAvailable => FirebaseInitializer.isInitialized;

  CollectionReference<Map<String, dynamic>> collection(String name) {
    _ensureAvailable();
    return _firestore.collection(name);
  }

  Future<Map<String, dynamic>?> getDocument(
    String collection,
    String id,
  ) async {
    if (!isAvailable) return null;
    final snapshot = await _firestore.collection(collection).doc(id).get();
    if (!snapshot.exists) return null;
    return snapshot.data();
  }

  Future<String> createDocument(
    String collection,
    Map<String, dynamic> data, {
    String? id,
  }) async {
    _ensureAvailable();
    final ref = id != null
        ? _firestore.collection(collection).doc(id)
        : _firestore.collection(collection).doc();
    await ref.set({
      ...data,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'city': AppConstants.city,
    });
    return ref.id;
  }

  Future<void> updateDocument(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    _ensureAvailable();
    await _firestore.collection(collection).doc(id).update({
      ...data,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteDocument(String collection, String id) async {
    _ensureAvailable();
    await _firestore.collection(collection).doc(id).delete();
  }

  Future<List<Map<String, dynamic>>> queryCollection(
    String collection, {
    Query<Map<String, dynamic>> Function(
      CollectionReference<Map<String, dynamic>> ref,
    )? queryBuilder,
  }) async {
    if (!isAvailable) return [];
    Query<Map<String, dynamic>> query = _firestore.collection(collection);
    if (queryBuilder != null) {
      query = queryBuilder(_firestore.collection(collection));
    }
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
  }

  Stream<List<Map<String, dynamic>>> watchCollection(
    String collection, {
    Query<Map<String, dynamic>> Function(
      CollectionReference<Map<String, dynamic>> ref,
    )? queryBuilder,
  }) {
    if (!isAvailable) {
      return Stream.value([]);
    }
    Query<Map<String, dynamic>> query = _firestore.collection(collection);
    if (queryBuilder != null) {
      query = queryBuilder(_firestore.collection(collection));
    }
    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  void _ensureAvailable() {
    if (!isAvailable) {
      throw StateError(
        'Firestore is unavailable. App is running in offline mode.',
      );
    }
  }
}
