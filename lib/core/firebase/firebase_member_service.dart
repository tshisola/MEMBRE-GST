import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app/constants.dart';
import '../../shared/models/ifcm_member_record.dart';
import 'firebase_initializer.dart';
import 'firestore_service.dart';

/// Firestore CRUD for IFCM members collection.
class FirebaseMemberRepository {
  FirebaseMemberRepository({
    FirestoreService? firestore,
    FirebaseFirestore? rawFirestore,
  })  : _firestore = firestore ?? FirestoreService(),
        _raw = rawFirestore ?? FirebaseFirestore.instance;

  final FirestoreService _firestore;
  final FirebaseFirestore _raw;

  bool get isAvailable => FirebaseInitializer.isInitialized;

  Future<String> upsertMember(IfcmMemberRecord member) async {
    final docId = member.cloudId ?? member.localId;
    final data = member.toFirestore();
    data['syncedAt'] = DateTime.now().toIso8601String();
    data['syncStatus'] = AppConstants.syncStatusSynced;

    await _firestore.createDocument(
      AppConstants.collectionMembers,
      data,
      id: docId,
    );

    await _firestore.createDocument(
      AppConstants.collectionMemberQrCodes,
      {
        'memberId': member.localId,
        'memberCode': member.memberCode,
        'qrCodeId': member.qrCodeId,
        'qrData': member.qrData,
        'isActive': member.isActive,
      },
      id: member.qrCodeId,
    );

    return docId;
  }

  Future<List<IfcmMemberRecord>> fetchAll() async {
    if (!isAvailable) return [];
    final rows = await _firestore.queryCollection(
      AppConstants.collectionMembers,
      queryBuilder: (ref) => ref
          .where('city', isEqualTo: AppConstants.city)
          .where('isDeleted', isEqualTo: false),
    );
    return rows
        .map((r) => IfcmMemberRecord.fromFirestore(
              r['id'] as String? ?? r['localId'] as String? ?? '',
              r,
            ))
        .toList();
  }

  Stream<List<IfcmMemberRecord>> watchAll() {
    if (!isAvailable) return Stream.value([]);

    return _raw
        .collection(AppConstants.collectionMembers)
        .where('city', isEqualTo: AppConstants.city)
        .snapshots()
        .map(
          (snap) => snap.docs
              .where((d) => (d.data()['isDeleted'] as bool? ?? false) == false)
              .map((d) => IfcmMemberRecord.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }
}
