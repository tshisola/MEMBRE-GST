import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../app/constants.dart';
import '../firebase/firebase_initializer.dart';

/// Rendez-vous — pastoral, média, technique.
class AppointmentService {
  AppointmentService({FirebaseFirestore? firestore, Uuid? uuid})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = uuid ?? const Uuid();

  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  bool get isAvailable => FirebaseInitializer.isInitialized;

  Stream<List<Map<String, dynamic>>> watchAppointments({String? assigneeId}) {
    if (!isAvailable) return Stream.value([]);
    Query<Map<String, dynamic>> q =
        _firestore.collection(AppConstants.collectionAppointments);
    if (assigneeId != null) {
      q = q.where('assigneeId', isEqualTo: assigneeId);
    }
    return q
        .orderBy('scheduledAt')
        .snapshots()
        .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  Future<void> createAppointment({
    required String title,
    required String scheduledAt,
    required String createdBy,
    String? assigneeId,
    String type = 'pastoral',
    String status = 'planned',
  }) async {
    if (!isAvailable) return;
    final id = _uuid.v4();
    await _firestore.collection(AppConstants.collectionAppointments).doc(id).set({
      'id': id,
      'title': title,
      'scheduledAt': scheduledAt,
      'createdBy': createdBy,
      if (assigneeId != null) 'assigneeId': assigneeId,
      'type': type,
      'status': status,
      'city': AppConstants.city,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
}

typedef AppointmentReminderService = AppointmentService;
typedef AppointmentNotificationService = AppointmentService;
typedef WebAppointmentCalendar = AppointmentService;
