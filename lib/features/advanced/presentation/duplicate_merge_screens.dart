import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/advanced/duplicates/duplicate_merge_service.dart';
import '../../../core/advanced/duplicates/duplicate_similarity_engine.dart';
import '../../../core/advanced/models/advanced_models.dart';
import '../../../core/messaging/user_friendly_message_service.dart';
import '../../../core/performance/background_sync_after_action.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/security/duplicate_merge_permission_guard.dart';
import '../../../shared/components/advanced_design_system.dart';
import '../../../shared/components/app_drawer.dart';
import '../../../shared/components/pop_scope_back_guard.dart';
import 'advanced_providers.dart';

final duplicateMergeServiceProvider = Provider((ref) => DuplicateMergeService());

/// Hub fusion intelligente des doublons.
class DuplicateMergeHubScreen extends ConsumerWidget {
  const DuplicateMergeHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(duplicatesProvider);
    final sessionAsync = ref.watch(localSessionProvider);
    final canMerge = sessionAsync.valueOrNull != null &&
        DuplicateMergePermissionGuard.canMerge(sessionAsync.value!);

    return PopScopeBackGuard(
      fallbackRoute: '/advanced/command-center',
      child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        drawer: const AppDrawer(currentRoute: '/advanced/duplicate-merge'),
        appBar: AppBar(
          leading: null,
          title: const Text('Fusion doublons'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(duplicatesProvider),
            ),
          ],
        ),
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: Text(UserFriendlyMessageService.genericError()),
          ),
          data: (matches) {
            if (matches.isEmpty) {
              return const EmptyStatePremium(
                title: 'Aucun doublon détecté',
                subtitle: 'Vos données sont propres.',
                icon: Icons.verified_outlined,
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: matches.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DuplicateCard(
                  match: matches[i],
                  canMerge: canMerge,
                  onMerge: () => _openPreview(context, ref, matches[i]),
                  onDetail: () {
                    final id = matches[i].primaryMemberId ?? matches[i].memberId;
                    context.push('/members/$id');
                  },
                  onIgnore: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Alerte ignorée.')),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openPreview(BuildContext context, WidgetRef ref, DuplicateMatch match) {
    final secondary = match.secondaryMemberId ?? match.memberId;
    final primary = match.primaryMemberId ?? match.memberId;
    context.push(
      '/advanced/duplicate-merge/preview?primary=$primary&secondary=$secondary',
    );
  }
}

/// Aperçu avant fusion — confirmation Admin obligatoire.
class DuplicateMergePreviewScreen extends ConsumerStatefulWidget {
  const DuplicateMergePreviewScreen({
    super.key,
    required this.primaryId,
    required this.secondaryId,
  });

  final String primaryId;
  final String secondaryId;

  @override
  ConsumerState<DuplicateMergePreviewScreen> createState() =>
      _DuplicateMergePreviewScreenState();
}

class _DuplicateMergePreviewScreenState
    extends ConsumerState<DuplicateMergePreviewScreen> {
  bool _merging = false;

  Future<void> _confirmMerge() async {
    final session = await ref.read(localSessionProvider.future);
    if (!DuplicateMergePermissionGuard.canMerge(session)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(DuplicateMergePermissionGuard.deniedMessage())),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer la fusion'),
        content: const Text(
          'Les présences et données seront conservées sur le profil principal. '
          'Cette action est définitive.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Fusionner')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _merging = true);
    final result = await ref.read(duplicateMergeServiceProvider).merge(
          primaryMemberId: widget.primaryId,
          secondaryMemberId: widget.secondaryId,
          actorId: session.userId ?? 'admin',
          actorName: session.displayName,
        );
    await BackgroundSyncAfterAction.run(trigger: 'duplicate_merge');
    ref.invalidate(duplicatesProvider);
    if (!mounted) return;
    setState(() => _merging = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
    if (result.success) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScopeBackGuard(
      fallbackRoute: '/advanced/duplicate-merge',
      child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        appBar: AppBar(
          title: const Text('Aperçu fusion'),
        ),
        body: FutureBuilder(
          future: ref.read(duplicateMergeServiceProvider).preview(
                widget.primaryId,
                widget.secondaryId,
              ),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final result = snap.data;
            if (result?.comparison == null) {
              return Center(child: Text(UserFriendlyMessageService.genericError()));
            }
            final c = result!.comparison!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                MergePreviewCard(
                  similarityScore: c.similarityScore,
                  primaryName: c.primaryMemberName,
                  secondaryName: c.secondaryMemberName,
                  differences: c.differences
                      .map((d) => '${d.label} : ${d.primaryValue} / ${d.secondaryValue}')
                      .toList(),
                ),
                const SizedBox(height: 16),
                SmartActionButton(
                  label: 'Fusionner',
                  icon: Icons.merge_type,
                  loading: _merging,
                  onPressed: _merging ? null : _confirmMerge,
                ),
                const SizedBox(height: 8),
                SmartActionButton(
                  label: 'Ouvrir détail principal',
                  icon: Icons.open_in_new,
                  onPressed: () => context.push('/members/${c.primaryMemberId}'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class DuplicateCard extends StatelessWidget {
  const DuplicateCard({
    super.key,
    required this.match,
    required this.canMerge,
    required this.onMerge,
    required this.onDetail,
    required this.onIgnore,
  });

  final DuplicateMatch match;
  final bool canMerge;
  final VoidCallback onMerge;
  final VoidCallback onDetail;
  final VoidCallback onIgnore;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      borderColor: AppTheme.warningProd.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  match.memberName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              StatusBadge(
                label: '${match.similarityScore ?? match.confidence} %',
                color: AppTheme.brandOrange,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${match.matchType} · ${match.matchValue}',
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          if (match.secondaryMemberName != null) ...[
            const SizedBox(height: 4),
            Text(
              'Doublon : ${match.secondaryMemberName}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              if (canMerge)
                SmartActionButton(label: 'Fusionner', icon: Icons.merge, onPressed: onMerge),
              SmartActionButton(label: 'Détail', icon: Icons.open_in_new, onPressed: onDetail),
              SmartActionButton(label: 'Ignorer', icon: Icons.close, onPressed: onIgnore),
            ],
          ),
        ],
      ),
    );
  }
}

class MergePreviewCard extends StatelessWidget {
  const MergePreviewCard({
    super.key,
    required this.similarityScore,
    required this.primaryName,
    required this.secondaryName,
    required this.differences,
  });

  final int similarityScore;
  final String primaryName;
  final String secondaryName;
  final List<String> differences;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      borderColor: AppTheme.brandBlue.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Similarité : $similarityScore %',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Principal : $primaryName'),
          Text('Secondaire : $secondaryName'),
          if (differences.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Différences', style: TextStyle(fontWeight: FontWeight.w600)),
            ...differences.map((d) => Text('• $d', style: const TextStyle(fontSize: 12))),
          ],
        ],
      ),
    );
  }
}

typedef DuplicateMergePreviewScreenAlias = DuplicateMergePreviewScreen;
