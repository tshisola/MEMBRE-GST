import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/messaging/realtime_messaging_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../shared/components/pop_scope_back_guard.dart';
import 'conversation_list_screen.dart';

/// Discussion temps réel — groupe ou privée.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _ctrl = TextEditingController();
  final _svc = RealtimeMessagingService();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final session = await ref.read(localSessionProvider.future);
    await _svc.sendMessage(
      conversationId: widget.conversationId,
      senderId: session.userId ?? 'unknown',
      senderName: session.displayName ?? 'Responsable',
      text: text,
    );
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(localSessionProvider).valueOrNull;
    return PopScopeBackGuard(
      fallbackRoute: '/messaging',
      child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        appBar: AppBar(
          leading: const AppBackButton(fallbackRoute: '/messaging'),
          title: const Text('Discussion'),
          backgroundColor: AppTheme.cardDark,
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _svc.watchConversation(widget.conversationId),
                builder: (context, snap) {
                  final msgs = snap.data ?? [];
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: msgs.length,
                    itemBuilder: (context, i) {
                      final m = msgs[i];
                      final isMine = m['senderId'] == session?.userId;
                      return ChatBubblePro(
                        text: m['text']?.toString() ?? '',
                        isMine: isMine,
                        senderName: m['senderName']?.toString(),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(hintText: 'Message…'),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppTheme.brandOrange),
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
