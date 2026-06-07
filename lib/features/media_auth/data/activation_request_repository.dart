import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../app/constants.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/firebase/firebase_initializer.dart';
import '../../../shared/models/media_activation_request.dart';

/// Lecture/écriture demandes d'activation — SQLite + Firestore.
class ActivationRequestRepository {
  ActivationRequestRepository({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  FirebaseFirestore? get _firestore =>
      FirebaseInitializer.isInitialized ? FirebaseFirestore.instance : null;

  Future<MediaActivationRequest?> findByFirebaseUid(String firebaseUid) async {
    final local = await _findLocalByUid(firebaseUid);
    if (local != null) return local;

    final remote = await _findRemoteByUid(firebaseUid);
    if (remote != null) {
      await _upsertLocal(remote);
    }
    return remote;
  }

  Future<MediaActivationRequest?> findByEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      AppConstants.tableMediaGoogleActivationRequests,
      where: 'LOWER(email) = ?',
      whereArgs: [normalized],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return MediaActivationRequest.fromMap(rows.first);
    }
    if (_firestore == null) return null;
    final snap = await _firestore!
        .collection(AppConstants.collectionMediaActivationRequests)
        .where('email', isEqualTo: normalized)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final req = _fromFirestore(snap.docs.first);
    await _upsertLocal(req);
    return req;
  }

  Future<MediaActivationRequest> createPendingRequest({
    required String firebaseUid,
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    final existing = await findByFirebaseUid(firebaseUid);
    if (existing != null) return existing;

    final byEmail = await findByEmail(email);
    if (byEmail != null && byEmail.firebaseUid != firebaseUid) {
      return byEmail;
    }

    final now = DateTime.now();
    final request = MediaActivationRequest(
      id: firebaseUid,
      firebaseUid: firebaseUid,
      email: email.trim().toLowerCase(),
      displayName: displayName,
      photoUrl: photoUrl,
      status: AppConstants.activationStatusPending,
      createdAt: now,
      updatedAt: now,
    );

    await _upsertLocal(request);
    await _upsertRemote(request);
    return request;
  }

  Future<void> updateStatus(
    MediaActivationRequest request, {
    required String status,
    String? memberId,
    bool activationCompleted = false,
    String? rejectionReason,
    String? reviewedBy,
  }) async {
    final updated = MediaActivationRequest(
      id: request.id,
      firebaseUid: request.firebaseUid,
      email: request.email,
      displayName: request.displayName,
      photoUrl: request.photoUrl,
      status: status,
      departmentName: request.departmentName,
      requestedRole: request.requestedRole,
      provider: request.provider,
      activationCompleted: activationCompleted,
      rejectionReason: rejectionReason,
      reviewedBy: reviewedBy,
      reviewedAt: reviewedBy != null ? DateTime.now() : request.reviewedAt,
      memberId: memberId ?? request.memberId,
      createdAt: request.createdAt,
      updatedAt: DateTime.now(),
      syncedAt: DateTime.now(),
    );
    await _upsertLocal(updated);
    await _upsertRemote(updated);
  }

  Stream<List<MediaActivationRequest>> watchPendingForAdmin() {
    if (_firestore == null) {
      return Stream.fromFuture(_listLocalPending());
    }
    return _firestore!
        .collection(AppConstants.collectionMediaActivationRequests)
        .where('status', isEqualTo: AppConstants.activationStatusPending)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snap) async {
      final list = snap.docs.map(_fromFirestore).toList();
      for (final r in list) {
        await _upsertLocal(r);
      }
      return list;
    });
  }

  Stream<MediaActivationRequest?> watchByFirebaseUid(String firebaseUid) {
    if (_firestore == null) {
      return Stream.periodic(const Duration(seconds: 3))
          .asyncMap((_) => findByFirebaseUid(firebaseUid));
    }
    return _firestore!
        .collection(AppConstants.collectionMediaActivationRequests)
        .doc(firebaseUid)
        .snapshots()
        .asyncMap((doc) async {
      if (!doc.exists) return await findByFirebaseUid(firebaseUid);
      final req = _fromFirestore(doc);
      await _upsertLocal(req);
      return req;
    });
  }

  Future<int> countPendingLocal() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as c FROM ${AppConstants.tableMediaGoogleActivationRequests} '
      "WHERE status = ?",
      [AppConstants.activationStatusPending],
    );
    return (result.first['c'] as int?) ?? 0;
  }

  Future<MediaActivationRequest?> _findLocalByUid(String uid) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      AppConstants.tableMediaGoogleActivationRequests,
      where: 'firebase_uid = ?',
      whereArgs: [uid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return MediaActivationRequest.fromMap(rows.first);
  }

  Future<MediaActivationRequest?> _findRemoteByUid(String uid) async {
    if (_firestore == null) return null;
    final doc = await _firestore!
        .collection(AppConstants.collectionMediaActivationRequests)
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    return _fromFirestore(doc);
  }

  Future<void> _upsertLocal(MediaActivationRequest request) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      AppConstants.tableMediaGoogleActivationRequests,
      request.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _upsertRemote(MediaActivationRequest request) async {
    if (_firestore == null) return;
    await _firestore!
        .collection(AppConstants.collectionMediaActivationRequests)
        .doc(request.firebaseUid)
        .set(request.toFirestore(), SetOptions(merge: true));
  }

  Future<List<MediaActivationRequest>> _listLocalPending() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      AppConstants.tableMediaGoogleActivationRequests,
      where: 'status = ?',
      whereArgs: [AppConstants.activationStatusPending],
      orderBy: 'created_at DESC',
    );
    return rows.map(MediaActivationRequest.fromMap).toList();
  }

  MediaActivationRequest _fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return MediaActivationRequest.fromMap({
      ...data,
      'id': doc.id,
      'firebase_uid': data['firebaseUid'] ?? doc.id,
    });
  }
}
