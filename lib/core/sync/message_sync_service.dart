import '../../app/constants.dart';
import 'offline_sync_queue.dart';

/// Offline-first message sync (local queue → Firestore).
class MessageSyncService {
  MessageSyncService({OfflineSyncQueue? queue})
      : _queue = queue ?? OfflineSyncQueue();

  final OfflineSyncQueue _queue;

  Future<String> enqueueOutgoing({
    required String messageId,
    required Map<String, dynamic> payload,
  }) {
    return _queue.enqueue(
      entityType: 'message',
      entityId: messageId,
      actionType: AppConstants.syncActionSendMessage,
      payload: payload,
    );
  }
}

class OfflineMessageQueue {
  OfflineMessageQueue({MessageSyncService? service})
      : _service = service ?? MessageSyncService();

  final MessageSyncService _service;

  Future<String> add(Map<String, dynamic> message) =>
      _service.enqueueOutgoing(
        messageId: message['id'] as String,
        payload: message,
      );
}
