import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/members/member_deletion.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/permission_providers.dart';
import '../../../features/admin_realtime/presentation/members_live_provider.dart';
import '../../../features/members/data/deleted_member_repository.dart';
import '../../../features/members/data/local_member_repository.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../shared/components/app_drawer.dart';
import '../../../shared/components/auth_ui_kit.dart';
import '../../../shared/components/pop_scope_back_guard.dart';
import '../../../shared/components/premium_ui_kit.dart';
import '../../../shared/models/deleted_member_record.dart';
import '../../../shared/models/member_delete_request.dart';

final deletedMembersProvider =
    FutureProvider<List<DeletedMemberRecord>>((ref) async {
  return DeletedMemberRepository().listDeleted();
});

final memberDeleteRequestsProvider =
    FutureProvider<List<MemberDeleteRequest>>((ref) async {
  return DeletedMemberRepository().listPendingRequests();
});

/// Corbeille des membres supprimés (soft delete).
class DeletedMembersTrashScreen extends ConsumerStatefulWidget {
  const DeletedMembersTrashScreen({super.key});

  @override
  ConsumerState<DeletedMembersTrashScreen> createState() =>
      _DeletedMembersTrashScreenState();
}

class _DeletedMembersTrashScreenState
    extends ConsumerState<DeletedMembersTrashScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final deletedAsync = ref.watch(deletedMembersProvider);
    final roleAsync = ref.watch(currentUserRoleProvider);
    const checker = MemberDeletionPermissionChecker();
    final canView = checker.canViewTrash(roleAsync.valueOrNull);

    if (roleAsync.isLoading) {
      return PopScopeBackGuard(
        fallbackRoute: '/dashboard',
        child: Scaffold(
          backgroundColor: AppTheme.premiumBlack,
          appBar: AppBar(
            leading: const AppBackButton(fallbackRoute: '/dashboard'),
            title: const Text('Corbeille membres'),
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (!canView) {
      return PopScopeBackGuard(
        fallbackRoute: '/dashboard',
        child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        appBar: AppBar(
          leading: const AppBackButton(fallbackRoute: '/dashboard'),
          title: const Text('Corbeille membres'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              checker.denialMessage(),
              style: authTextStyle(),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      );
    }

    return PopScopeBackGuard(
      fallbackRoute: '/dashboard',
      child: Scaffold(
      backgroundColor: AppTheme.premiumBlack,
      drawer: const AppDrawer(currentRoute: '/members/trash'),
      appBar: AppBar(
        backgroundColor: AppTheme.premiumBlack,
        leading: const AppBackButton(fallbackRoute: '/members'),
        title: const Text('Corbeille membres'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historique',
            onPressed: () => context.push('/members/deletion-history'),
          ),
          IconButton(
            icon: const Icon(Icons.pending_actions_outlined),
            tooltip: 'Demandes',
            onPressed: () => context.push('/members/delete-requests'),
          ),
        ],
      ),
      body: deletedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(
            'Impossible de charger la corbeille.',
            style: authTextStyle(color: AppTheme.textSecondary),
          ),
        ),
        data: (items) {
          final filtered = items.where((m) {
            if (_search.isEmpty) return true;
            final q = _search.toLowerCase();
            return (m.fullName?.toLowerCase().contains(q) ?? false) ||
                (m.memberCode?.toLowerCase().contains(q) ?? false);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: authTextStyle(),
                  decoration: const InputDecoration(
                    hintText: 'Rechercher…',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'Aucun membre supprimé.',
                          style: authTextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) => _TrashCard(
                          item: filtered[i],
                          canRestore: checker.canRestore(roleAsync.value),
                          onRestored: () {
                            ref.invalidate(deletedMembersProvider);
                            bumpMembersRevision(ref);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    ),
    );
  }
}

class _TrashCard extends ConsumerStatefulWidget {
  const _TrashCard({
    required this.item,
    required this.canRestore,
    required this.onRestored,
  });

  final DeletedMemberRecord item;
  final bool canRestore;
  final VoidCallback onRestored;

  @override
  ConsumerState<_TrashCard> createState() => _TrashCardState();
}

class _TrashCardState extends ConsumerState<_TrashCard> {
  bool _loading = false;

  Future<void> _restore() async {
    final passwordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainer,
        title: const Text('Restaurer membre'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Restaurer ${widget.item.fullName ?? widget.item.memberCode} ?',
              style: authTextStyle(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe admin',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restaurer', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      passwordController.dispose();
      return;
    }

    setState(() => _loading = true);
    final role = await ref.read(currentUserRoleProvider.future);
    final session = await ref.read(localSessionProvider.future);

    final result = await MemberRestoreService().restore(
      actor: role!,
      actorName: session.displayName ?? 'Admin',
      memberId: widget.item.memberId,
      adminPassword: passwordController.text,
      reason: 'Restauration depuis corbeille',
    );
    passwordController.dispose();

    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message ?? '')),
    );
    if (result.success) widget.onRestored();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Card(
      color: AppTheme.surfaceContainer,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.fullName ?? item.memberCode ?? 'Membre',
                style: authTextStyle(weight: FontWeight.w600)),
            if (item.memberCode != null)
              Text(item.memberCode!,
                  style: authTextStyle(color: AppTheme.textSecondary)),
            Text(item.departmentName ?? '—',
                style: authTextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Text('Supprimé le ${_formatDate(item.deletedAt)}',
                style: authTextStyle(color: AppTheme.textSecondary)),
            if (item.deletedReason != null)
              Text('Motif : ${item.deletedReason}', style: authTextStyle()),
            if (item.deletedByRole != null)
              Text('Par : ${item.deletedByRole}',
                  style: authTextStyle(color: AppTheme.textSecondary)),
            if (widget.canRestore && item.restoreAvailable) ...[
              const SizedBox(height: 12),
              AdvancedButton(
                label: 'Restaurer',
                variant: AdvancedButtonVariant.sync,
                isLoading: _loading,
                onPressed: _loading ? null : _restore,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';
}

/// Demandes de suppression en attente de validation.
class MemberDeleteRequestsScreen extends ConsumerWidget {
  const MemberDeleteRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(memberDeleteRequestsProvider);
    final roleAsync = ref.watch(currentUserRoleProvider);
    const checker = MemberDeletionPermissionChecker();

    return PopScopeBackGuard(
      fallbackRoute: '/members/trash',
      child: Scaffold(
      backgroundColor: AppTheme.premiumBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        leading: const AppBackButton(fallbackRoute: '/members/trash'),
        title: const Text('Demandes suppression'),
      ),
      body: !checker.canApproveRequests(roleAsync.valueOrNull)
          ? Center(child: Text(checker.denialMessage(), style: authTextStyle()))
          : requestsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Chargement impossible.')),
              data: (requests) {
                if (requests.isEmpty) {
                  return Center(
                    child: Text(
                      'Aucune demande en attente.',
                      style: authTextStyle(color: AppTheme.textSecondary),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, i) {
                    final req = requests[i];
                    return Card(
                      color: AppTheme.surfaceContainer,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text('Membre ${req.memberId}',
                            style: authTextStyle(weight: FontWeight.w600)),
                        subtitle: Text(
                          '${req.reason}\nDemandé par : ${req.requestedByRole ?? req.requestedBy}',
                          style: authTextStyle(color: AppTheme.textSecondary),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.check_circle_outline,
                              color: Colors.orange),
                          onPressed: () => _approve(context, ref, req),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    ),
    );
  }

  Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    MemberDeleteRequest request,
  ) async {
    final passwordController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainer,
        title: const Text('Approuver suppression'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Mot de passe admin'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Approuver')),
        ],
      ),
    );
    if (ok != true || !context.mounted) {
      passwordController.dispose();
      return;
    }

    final member = await LocalMemberRepository().getById(request.memberId);
    if (member == null || !context.mounted) {
      passwordController.dispose();
      return;
    }

    final role = await ref.read(currentUserRoleProvider.future);
    final session = await ref.read(localSessionProvider.future);
    final result = await MemberDeletionService().approveRequest(
      actor: role!,
      actorName: session.displayName ?? 'Admin',
      request: request,
      member: member,
      adminPassword: passwordController.text,
    );
    passwordController.dispose();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message ?? '')),
    );
    if (result.success) {
      ref.invalidate(memberDeleteRequestsProvider);
      bumpMembersRevision(ref);
    }
  }
}

/// Historique des suppressions et restaurations.
class MemberDeletionHistoryScreen extends ConsumerWidget {
  const MemberDeletionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deletedAsync = ref.watch(deletedMembersProvider);

    return PopScopeBackGuard(
      fallbackRoute: '/members/trash',
      child: Scaffold(
      backgroundColor: AppTheme.premiumBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        leading: const AppBackButton(fallbackRoute: '/members/trash'),
        title: const Text('Historique suppressions'),
      ),
      body: deletedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Chargement impossible.')),
        data: (items) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            return ListTile(
              tileColor: AppTheme.surfaceContainer,
              title: Text(item.fullName ?? item.memberCode ?? 'Membre'),
              subtitle: Text(
                'Supprimé le ${_formatDate(item.deletedAt)} — ${item.deletedReason ?? ''}',
                style: authTextStyle(color: AppTheme.textSecondary),
              ),
            );
          },
        ),
      ),
    ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';
}
