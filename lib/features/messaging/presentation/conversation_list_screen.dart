import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../../../core/messaging/realtime_messaging_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../shared/components/auth_ui_kit.dart';
import '../../../shared/components/pop_scope_back_guard.dart';

/// Liste des conversations — temps réel.
class ConversationListScreen extends ConsumerWidget {
  const ConversationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(localSessionProvider).valueOrNull;
    final svc = RealtimeMessagingService();

    return PopScopeBackGuard(
      fallbackRoute: '/dashboard',
      child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        appBar: AppBar(
          leading: const AppBackButton(fallbackRoute: '/dashboard'),
          title: const Text('Messagerie'),
          backgroundColor: AppTheme.cardDark,
          actions: [
            IconButton(
              icon: const Icon(Icons.add_comment_outlined),
              onPressed: () => context.push('/messaging/media-general'),
            ),
          ],
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: svc.watchConversations(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.goldAccent),
              );
            }
            final items = snap.data ?? [];
            if (items.isEmpty) {
              return Center(
                child: Text(
                  'Aucune conversation.',
                  style: authTextStyle(color: AppTheme.textMuted),
                ),
              );
            }
            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, i) {
                final c = items[i];
                return ListTile(
                  leading: const Icon(Icons.forum_outlined, color: AppTheme.brandBlue),
                  title: Text(
                    c['title']?.toString() ?? 'Conversation',
                    style: authTextStyle(),
                  ),
                  subtitle: Text(
                    c['lastMessage']?.toString() ?? '',
                    style: authTextStyle(color: AppTheme.textMuted),
                  ),
                  onTap: () => context.push(
                    '/messaging/chat/${c['id']}',
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: session?.isAdminAccount == true
            ? FloatingActionButton.extended(
                backgroundColor: AppTheme.brandOrange,
                onPressed: () => context.push('/messaging/media-general'),
                label: const Text('Groupe Média'),
                icon: const Icon(Icons.groups),
              )
            : null,
      ),
    );
  }
}

/// Bulle message professionnelle.
class ChatBubblePro extends StatelessWidget {
  const ChatBubblePro({
    super.key,
    required this.text,
    required this.isMine,
    this.senderName,
  });

  final String text;
  final bool isMine;
  final String? senderName;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
        decoration: BoxDecoration(
          color: isMine ? AppTheme.brandOrange.withValues(alpha: 0.85) : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (senderName != null && !isMine)
              Text(senderName!, style: authTextStyle(color: AppTheme.goldAccent)),
            Text(text, style: authTextStyle(color: AppTheme.brandWhite)),
          ],
        ),
      ),
    );
  }
}
