import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../../../core/auth/logout_service.dart';
import '../../../core/auth/member_dashboard_service.dart';
import '../../../core/advanced/notifications/local_notification_repository.dart';
import '../../../core/storage/local_session.dart';
import '../../../core/sync/manual_sync_refresh_service.dart';
import '../../../shared/components/advanced_design_system.dart';
import '../../../core/bootstrap/background_sync_host.dart';
import '../../../core/widgets/app_shell_screens.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/background_sync_providers.dart';

/// Dashboard personnel membre — sans accès admin ni métadonnées sensibles.
class MemberDashboardScreen extends ConsumerWidget {
  const MemberDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(localSessionProvider);

    return Scaffold(
      backgroundColor: AppTheme.premiumBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.premiumBlack,
        title: const Text('Mon espace membre'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () async {
              await ref.read(logoutServiceProvider).logout(ref);
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: sessionAsync.when(
        loading: () => const AppLoadingScreen(message: 'Chargement de votre espace…'),
        error: (e, _) => AppErrorScreen(
          technicalError: e,
          onBackToLogin: () => context.go('/login'),
        ),
        data: (session) {
          final dataAsync = ref.watch(memberDashboardDataProvider(session));

          return dataAsync.when(
            loading: () => const AppLoadingScreen(message: 'Chargement des données…'),
            error: (e, _) => AppErrorScreen(
              technicalError: e,
              onRetry: () => ref.invalidate(memberDashboardDataProvider(session)),
            ),
            data: (data) => _MemberDashboardContent(data: data, session: session),
          );
        },
      ),
    );
  }
}

class _MemberDashboardContent extends ConsumerStatefulWidget {
  const _MemberDashboardContent({required this.data, required this.session});

  final MemberDashboardData data;
  final LocalSession session;

  @override
  ConsumerState<_MemberDashboardContent> createState() =>
      _MemberDashboardContentState();
}

class _MemberDashboardContentState extends ConsumerState<_MemberDashboardContent> {
  Future<void> _refresh() async {
    await ManualSyncRefreshService().refresh();
    ref.invalidate(memberDashboardDataProvider(widget.session));
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppTheme.brandOrange,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _HeaderCard(data: data),
          const SizedBox(height: 8),
          Consumer(
            builder: (context, ref, _) {
              final sync = ref.watch(backgroundSyncStateProvider);
              return MemberSimpleSyncBadge(state: sync);
            },
          ),
          const SizedBox(height: 14),
          _StatsRow(data: data),
          const SizedBox(height: 14),
          const _SectionTitle(title: 'Résultat hebdomadaire'),
          PremiumCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data.weekPresentCount} / ${data.weekSessionCount} séances',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.brandWhite,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Présence cette semaine : ${data.weekAttendancePercent.round()} %',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (data.isHabilite)
                  MemberStatusBadge.habilite()
                else if (data.weekAttendancePercent >= 30)
                  MemberStatusBadge.watch()
                else
                  MemberStatusBadge.inactive(),
              ],
            ),
          ),
          if (data.mediaAssignment != null) ...[
            const SizedBox(height: 14),
            const _SectionTitle(title: 'Affectation Média'),
            MemberAssignmentCard(
              title: 'Prochaine affectation',
              subtitle: data.mediaAssignment!,
              icon: Icons.videocam_outlined,
              badge: 'Média',
            ),
          ],
          const SizedBox(height: 14),
          const _SectionTitle(title: 'Informations'),
          _InfoTile(
            icon: Icons.badge_outlined,
            label: 'Code membre',
            value: data.memberCode,
          ),
          _InfoTile(
            icon: Icons.qr_code_2_outlined,
            label: 'QR Code',
            value: data.qrAvailable ? 'Disponible' : 'Non généré',
          ),
          _InfoTile(
            icon: Icons.groups_outlined,
            label: 'Département',
            value: data.department,
          ),
          _InfoTile(
            icon: Icons.shield_outlined,
            label: 'Rôle',
            value: data.role,
          ),
          _InfoTile(
            icon: Icons.church_outlined,
            label: 'Pasteur',
            value: data.pasteur,
          ),
          _InfoTile(
            icon: Icons.volunteer_activism_outlined,
            label: 'Disciple',
            value: data.disciple,
          ),
          const SizedBox(height: 14),
          const _SectionTitle(title: 'Historique de présence'),
          if (data.attendanceHistory.isEmpty)
            const _EmptyCard(
              message: 'Aucune présence enregistrée pour le moment.',
            )
          else ...[
            MemberTimeline(
              entries: data.attendanceHistory
                  .map(
                    (e) => MemberTimelineEntry(
                      date: e.date,
                      status: e.status,
                      sessionType: e.sessionType,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            ...data.attendanceHistory.map((e) => _HistoryTile(entry: e)),
          ],
          const SizedBox(height: 14),
          const _SectionTitle(title: 'Messages'),
          if (data.messages.isEmpty)
            const _EmptyCard(message: 'Aucun message.')
          else
            ...data.messages.map((m) => _MessageTile(message: m)),
          const SizedBox(height: 14),
          const _SectionTitle(title: 'Notifications'),
          if (data.notifications.isEmpty)
            const _EmptyCard(message: 'Aucune notification.')
          else
            ...data.notifications.map(
              (n) => _NotificationTile(
                notification: n,
                onTap: () async {
                  if (n.isRead) return;
                  await LocalNotificationRepository.instance.markRead(n.id);
                  ref.invalidate(memberDashboardDataProvider(widget.session));
                },
              ),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.brandBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.brandBlue.withValues(alpha: 0.25),
              ),
            ),
            child: const Text(
              'La présence est enregistrée par un opérateur autorisé. '
              'Vous ne pouvez pas vous pointer vous-même.',
              style: TextStyle(fontSize: 12, color: AppTheme.brandBlue),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.data});

  final MemberDashboardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.brandBlue.withValues(alpha: 0.2),
            child: const Icon(Icons.person, color: AppTheme.brandBlue, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.brandWhite,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  AppConstants.appFullName,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 8),
                if (data.isHabilite)
                  MemberStatusBadge.habilite()
                else if (data.weekAttendancePercent >= 30)
                  MemberStatusBadge.watch()
                else
                  MemberStatusBadge.inactive(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.data});

  final MemberDashboardData data;

  @override
  Widget build(BuildContext context) {
    final percent = data.weekAttendancePercent.round();
    final habilite = data.isHabilite;

    return Row(
      children: [
        MemberProgressRing(percent: data.weekAttendancePercent),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              _StatCard(
                label: 'Présence semaine',
                value: '$percent%',
                icon: Icons.percent,
                color: AppTheme.brandOrange,
              ),
              const SizedBox(height: 10),
              _StatCard(
                label: 'Statut',
                value: habilite ? 'Habilité' : 'Non habilité',
                icon: habilite ? Icons.check_circle_outline : Icons.cancel_outlined,
                color: habilite ? AppTheme.success : AppTheme.danger,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.brandWhite,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.brandOrange,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.brandBlue),
        title: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppTheme.brandWhite,
          ),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});

  final MemberAttendanceEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.event_available, color: AppTheme.brandOrange),
        title: Text(
          entry.date,
          style: const TextStyle(color: AppTheme.brandWhite),
        ),
        subtitle: Text(
          '${entry.sessionType} · ${entry.status}',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({required this.message});

  final MemberMessageEntry message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.mail_outline, color: AppTheme.brandBlue),
        title: Text(
          message.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.brandWhite,
          ),
        ),
        subtitle: Text(message.body),
        trailing: Text(
          message.date,
          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, this.onTap});

  final MemberNotificationEntry notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: notification.isRead
            ? null
            : Border.all(color: AppTheme.brandOrange.withValues(alpha: 0.35)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          notification.isRead
              ? Icons.notifications_none
              : Icons.notifications_active,
          color: AppTheme.brandOrange,
        ),
        title: Text(
          notification.title,
          style: const TextStyle(color: AppTheme.brandWhite),
        ),
        subtitle: notification.message.isNotEmpty
            ? Text(
                notification.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Text(
          notification.date,
          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
      ),
    );
  }
}
