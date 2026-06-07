import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/ai/gemini_assistant_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../shared/components/auth_ui_kit.dart';
import '../../../shared/components/pop_scope_back_guard.dart';

/// Chat Assistant IA MEDIA — Gemini via Cloud Function.
class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _ctrl = TextEditingController();
  final _messages = <({String text, bool isUser})>[];
  bool _loading = false;

  static const _suggestions = [
    'Résumer les absences du dimanche',
    'Quels membres sont en retard ?',
    'Proposer une équipe Média',
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send([String? text]) async {
    final prompt = (text ?? _ctrl.text).trim();
    if (prompt.isEmpty || _loading) return;
    _ctrl.clear();
    setState(() {
      _messages.add((text: prompt, isUser: true));
      _loading = true;
    });

    final session = await ref.read(localSessionProvider.future);
    final answer = await GeminiAssistantService().ask(
      prompt: AiPromptSanitizer.clean(prompt),
      role: session.role ?? 'member',
      permissions: session.permissions,
    );

    if (!mounted) return;
    setState(() {
      _messages.add((text: answer, isUser: false));
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScopeBackGuard(
      fallbackRoute: '/dashboard',
      child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        appBar: AppBar(
          leading: const AppBackButton(fallbackRoute: '/dashboard'),
          title: const Text('Assistant IA MEDIA'),
          backgroundColor: AppTheme.cardDark,
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (context, i) {
                  final m = _messages[i];
                  return Align(
                    alignment:
                        m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: m.isUser ? AppTheme.brandOrange : AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(m.text, style: authTextStyle()),
                    ),
                  );
                },
              ),
            ),
            if (_messages.isEmpty)
              Wrap(
                spacing: 8,
                children: _suggestions
                    .map(
                      (s) => ActionChip(
                        label: Text(s),
                        onPressed: () => _send(s),
                      ),
                    )
                    .toList(),
              ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(color: AppTheme.goldAccent),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(
                        hintText: 'Posez votre question…',
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppTheme.brandOrange),
                    onPressed: () => _send(),
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

typedef AiAssistantScreen = AiChatScreen;
