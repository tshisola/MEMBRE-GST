import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../app/constants.dart';
import '../firebase/firebase_initializer.dart';
import '../sync/message_sync_service.dart';

/// Messagerie temps réel — Firestore + cache offline.
class RealtimeMessagingService {
  RealtimeMessagingService({
    FirebaseFirestore? firestore,
    MessageSyncService? sync,
    Uuid? uuid,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _sync = sync ?? MessageSyncService(),
        _uuid = uuid ?? const Uuid();

  final FirebaseFirestore _firestore;
  final MessageSyncService _sync;
  final Uuid _uuid;

  bool get isAvailable => FirebaseInitializer.isInitialized;

  Stream<List<Map<String, dynamic>>> watchConversation(String conversationId) {
    if (!isAvailable) return Stream.value([]);
    return _firestore
        .collection(AppConstants.collectionMessages)
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  Stream<List<Map<String, dynamic>>> watchConversations() {
    if (!isAvailable) return Stream.value([]);
    return _firestore
        .collection(AppConstants.collectionConversations)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String text,
    String? groupType,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final payload = {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'groupType': groupType ?? 'general',
      'createdAt': now,
      'status': 'sent',
      'city': AppConstants.city,
    };

    if (isAvailable) {
      await _firestore
          .collection(AppConstants.collectionMessages)
          .doc(id)
          .set(payload);
      await _firestore
          .collection(AppConstants.collectionConversations)
          .doc(conversationId)
          .set({'updatedAt': now, 'lastMessage': text}, SetOptions(merge: true));
    } else {
      await _sync.enqueueOutgoing(messageId: id, payload: payload);
    }
  }
}

typedef GroupChatService = RealtimeMessagingService;
typedef MessageNotificationService = RealtimeMessagingService;
