import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/components/screen_header.dart';
import '../../../shared/models/media_activation_request.dart';
import '../services/admin_media_activation_controller.dart';
import 'providers/media_activation_providers.dart';
import 'widgets/activation_status_badge.dart';

class MediaActivationRequestsScreen extends ConsumerStatefulWidget {
  const MediaActivationRequestsScreen({super.key});

  @override
  ConsumerState<MediaActivationRequestsScreen> createState() =>
      _MediaActivationRequestsScreenState();
}

class _MediaActivationRequestsScreenState
    extends ConsumerState<MediaActivationRequestsScreen> {
  String _filter = 'pending';

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(pendingMediaActivationRequestsProvider);

    return Scaffold(
      backgroundColor: AppTheme.premiumBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.premiumBlack,
        title: const Text('Demandes comptes Média'),
      ),
      body: Column(
        children: [
          const ScreenHeader(
            title: 'Activation Google',
            subtitle: 'Mise à jour automatique en temps réel',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('En attente'),
                  selected: _filter == 'pending',
                  onSelected: (_) => setState(() => _filter = 'pending'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () =>
                      ref.invalidate(pendingMediaActivationRequestsProvider),
                ),
              ],
            ),
          ),
          Expanded(
            child: requestsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(
                child: Text(
                  'Chargement en cours…',
                  style: TextStyle(color: AppTheme.brandWhite),
                ),
              ),
              data: (list) {
                final filtered = list
                    .where((r) => _filter == 'all' || r.isPending)
                    .toList();
                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucune demande en attente',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) =>
                      _MediaActivationRequestCard(request: filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaActivationRequestCard extends ConsumerStatefulWidget {
  const _MediaActivationRequestCard({required this.request});

  final MediaActivationRequest request;

  @override
  ConsumerState<_MediaActivationRequestCard> createState() =>
      _MediaActivationRequestCardState();
}

class _MediaActivationRequestCardState
    extends ConsumerState<_MediaActivationRequestCard> {
  bool _working = false;

  Future<void> _activate() async {
    setState(() => _working = true);
    final session = ref.read(localSessionProvider).valueOrNull;
    final adminId = session?.userId ?? 'admin';
    final result = await AdminMediaActivationController().activate(
      requestId: widget.request.firebaseUid,
      adminId: adminId,
    );
    if (mounted) {
      setState(() => _working = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      ref.invalidate(pendingMediaActivationRequestsProvider);
    }
  }

  Future<void> _reject() async {
    setState(() => _working = true);
    final session = ref.read(localSessionProvider).valueOrNull;
    final result = await AdminMediaActivationController().reject(
      requestId: widget.request.firebaseUid,
      adminId: session?.userId ?? 'admin',
    );
    if (mounted) {
      setState(() => _working = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      ref.invalidate(pendingMediaActivationRequestsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    return Card(
      color: AppTheme.cardDark,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage:
                      r.photoUrl != null ? NetworkImage(r.photoUrl!) : null,
                  child: r.photoUrl == null
                      ? const Icon(Icons.person, color: AppTheme.brandWhite)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.displayName ?? r.email,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.brandWhite,
                        ),
                      ),
                      Text(
                        r.email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                ActivationStatusBadge(status: r.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _working ? null : _activate,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.success,
                    ),
                    child: const Text('Activer'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _working ? null : _reject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.danger,
                      side: const BorderSide(color: AppTheme.danger),
                    ),
                    child: const Text('Refuser'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
