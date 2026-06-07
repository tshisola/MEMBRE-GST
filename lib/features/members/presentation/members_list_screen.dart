import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/theme.dart';
import '../../../core/production/excel_like_search_service.dart';
import '../../../core/widgets/app_shell_screens.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../shared/components/pop_scope_back_guard.dart';
import '../../../shared/components/professional_list_viewer.dart';
import '../../../shared/components/premium_ui_kit.dart';
import '../../../shared/components/smart_ui_kit.dart';
import '../../smart/presentation/smart_providers.dart';
import '../../../shared/components/production_ui_kit.dart';
import '../../../core/providers/app_providers.dart';
import '../../../features/admin_realtime/presentation/members_live_provider.dart';
import '../../../shared/components/app_drawer.dart';
import '../../../shared/components/member_sync_ui_kit.dart';
import '../../../shared/components/screen_header.dart';
import '../../../core/members/member_deletion.dart';
import '../../../core/providers/permission_providers.dart';
import '../../../features/members/data/local_member_repository.dart';
import '../../../shared/models/ifcm_member_record.dart';

class MembersListScreen extends ConsumerStatefulWidget {
  const MembersListScreen({super.key, this.departmentId});

  final String? departmentId;

  @override
  ConsumerState<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends ConsumerState<MembersListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersLiveProvider);
    final banner = ref.watch(memberSyncBannerProvider);

    return PopScopeBackGuard(
      fallbackRoute: '/dashboard',
      child: Scaffold(
      backgroundColor: AppTheme.premiumBlack,
      drawer: AppDrawer(currentRoute: '/members'),
      appBar: AppBar(
        leading: const AppBackButton(fallbackRoute: '/dashboard'),
        title: Text(widget.departmentId == null ? 'Membres' : 'Membres département'),
        actions: [
          RefreshButton(
            compact: true,
            onRefresh: () => _refresh(ref),
          ),
          IconButton(
            icon: const Icon(Icons.person_add, color: AppTheme.goldAccent),
            onPressed: () => context.push('/members/create'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/members/create'),
        backgroundColor: AppTheme.goldAccent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau'),
      ),
      body: Column(
        children: [
          if (banner != null)
            RealtimeUpdateBanner(
              message: banner,
              onDismiss: () =>
                  ref.read(memberSyncBannerProvider.notifier).state = null,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SearchExcelLikeField(
              hint: 'Rechercher un membre (nom, code, téléphone)…',
              onChanged: (q) => setState(() => _searchQuery = q),
            ),
          ),
          Expanded(
            child: PullToRefreshMembers(
              onRefresh: () async {
                await _refresh(ref);
                ref.invalidate(membersLiveProvider);
              },
              child: membersAsync.when(
                loading: () => const AppLoadingScreen(message: 'Chargement des membres…'),
                error: (e, _) => AppErrorScreen(
                  technicalError: e,
                  onRetry: () => ref.invalidate(membersLiveProvider),
                ),
                data: (members) {
                  var filtered = widget.departmentId == null
                      ? members
                      : members
                          .where((m) => m.departmentId == widget.departmentId)
                          .toList();
                  if (_searchQuery.isNotEmpty) {
                    filtered = filtered
                        .where(
                          (m) => ExcelLikeSearchService.matches(
                            query: _searchQuery,
                            fields: [
                              m.displayName,
                              m.memberCode,
                              m.phone ?? '',
                              m.email ?? '',
                              m.departmentName ?? '',
                            ],
                          ),
                        )
                        .toList();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ProfessionalListHeader(
                        title: 'Liste des membres',
                        departmentName: widget.departmentId == null
                            ? 'Tous les départements'
                            : 'Département filtré',
                        totalCount: filtered.length,
                        syncLabel: banner == null ? null : 'Mise à jour disponible',
                      ),
                      Expanded(
                        child: filtered.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 80),
                                  Center(
                                    child: Text(
                                      'Aucun membre enregistré.\nCréez un membre pour démarrer.',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filtered.length,
                                itemBuilder: (_, i) =>
                                    _MemberTile(member: filtered[i]),
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Future<String> _refresh(WidgetRef ref) async {
    final result = await ref.read(manualSyncRefreshServiceProvider).refresh();
    bumpMembersRevision(ref);
    return result.message;
  }
}

class _MemberTile extends ConsumerWidget {
  const _MemberTile({required this.member});

  final IfcmMemberRecord member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(currentUserRoleProvider);
    const deletionChecker = MemberDeletionPermissionChecker();
    final canDelete = deletionChecker.canDelete(roleAsync.valueOrNull) ||
        deletionChecker.canRequestDelete(roleAsync.valueOrNull, member);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.goldAccent.withValues(alpha: 0.2),
          child: Text(
            member.firstName.isNotEmpty ? member.firstName[0].toUpperCase() : '?',
            style: const TextStyle(color: AppTheme.goldAccent),
          ),
        ),
        title: Text(
          member.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${member.memberCode}\n${member.departmentName ?? ''}',
          style: const TextStyle(fontSize: 12),
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canDelete && !member.isDeleted)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.errorProd),
                tooltip: 'Supprimer',
                onPressed: () => context.push('/members/${member.id}/delete'),
              ),
            SyncStatusBadge(status: member.syncStatus),
          ],
        ),
        onTap: () => context.push('/members/${member.id}'),
      ),
    );
  }
}

class MemberDetailScreen extends ConsumerWidget {
  const MemberDetailScreen({super.key, required this.memberId});

  final String memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(currentUserRoleProvider);
    const deletionChecker = MemberDeletionPermissionChecker();

    return FutureBuilder<IfcmMemberRecord?>(
      future: LocalMemberRepository().getById(memberId),
      builder: (context, memberSnap) {
        if (memberSnap.connectionState != ConnectionState.done) {
          return PopScopeBackGuard(
            fallbackRoute: '/members',
            child: Scaffold(
            backgroundColor: AppTheme.premiumBlack,
            appBar: AppBar(
              leading: const AppBackButton(fallbackRoute: '/members'),
              title: const Text('Détail membre'),
            ),
            body: const AppLoadingScreen(message: 'Chargement du membre…'),
          ),
          );
        }

        final member = memberSnap.data;
        if (member == null) {
          return PopScopeBackGuard(
            fallbackRoute: '/members',
            child: Scaffold(
            backgroundColor: AppTheme.premiumBlack,
            appBar: AppBar(
              leading: const AppBackButton(fallbackRoute: '/members'),
              title: const Text('Détail membre'),
            ),
            body: const Center(child: Text('Membre introuvable')),
          ),
          );
        }

        final canDeleteOrRequest =
            deletionChecker.canDelete(roleAsync.valueOrNull) ||
                deletionChecker.canRequestDelete(roleAsync.valueOrNull, member);

        return PopScopeBackGuard(
          fallbackRoute: '/members',
          child: Scaffold(
          backgroundColor: AppTheme.premiumBlack,
          appBar: AppBar(
            backgroundColor: AppTheme.premiumBlack,
            leading: const AppBackButton(fallbackRoute: '/members'),
            title: const Text('Détail membre'),
            actions: [
              RefreshButton(
                compact: true,
                onRefresh: () async {
                  final r =
                      await ref.read(manualSyncRefreshServiceProvider).refresh();
                  bumpMembersRevision(ref);
                  return r.message;
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ScreenHeader(
                title: member.displayName,
                subtitle: member.memberCode,
              ),
              const SizedBox(height: 16),
              SyncStatusBadge(status: member.syncStatus, compact: false),
              const SizedBox(height: 16),
              ref.watch(memberScoreProvider(member.id)).when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (score) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: MemberScoreCard(score: score),
                    ),
                  ),
              _infoRow('Téléphone', member.phone),
              _infoRow('Email', member.email),
              _infoRow('Adresse', member.address),
              _infoRow('Commune', member.commune),
              _infoRow('Département', member.departmentName),
              const SizedBox(height: 16),
              MemberQrCard(
                memberCode: member.memberCode,
                qrData: member.qrData,
                qrWidget: QrImageView(
                  data: member.qrData,
                  size: 180,
                  backgroundColor: Colors.white,
                ),
              ),
              if (canDeleteOrRequest && !member.isDeleted) ...[
                const SizedBox(height: 24),
                AdvancedButton(
                  label: 'Supprimer membre',
                  variant: AdvancedButtonVariant.danger,
                  onPressed: () => context.push('/members/$memberId/delete'),
                ),
              ],
            ],
          ),
        ),
        );
      },
    );
  }

  Widget _infoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
