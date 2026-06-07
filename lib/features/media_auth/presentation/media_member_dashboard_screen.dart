import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../../../core/auth/logout_service.dart';
import '../../../core/auth/member_dashboard_service.dart';
import '../../../core/advanced/notifications/local_notification_repository.dart';
import '../../../core/bootstrap/background_sync_host.dart';
import '../../../core/messaging/user_facing_messages.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/background_sync_providers.dart';
import '../../../core/storage/local_session.dart';
import '../../../core/sync/manual_sync_refresh_service.dart';
import '../../../core/widgets/app_shell_screens.dart';
import '../../../shared/components/advanced_design_system.dart';

/// Dashboard membre Média (Google) — même richesse que l'espace membre classique.
class MediaMemberDashboardScreen extends ConsumerWidget {
  const MediaMemberDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(localSessionProvider);

    return Scaffold(
      backgroundColor: AppTheme.premiumBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.premiumBlack,
        title: Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(logoutServiceProvider).logout(ref);
              if (context.mounted) context.go('/login/member');
            },
          ),
        ],
      ),
      body: sessionAsync.when(
        loading: () =>
            const AppLoadingScreen(message: UserFacingMessages.pleaseWait),
        error: (_, __) => AppErrorScreen(
          onBackToLogin: () => context.go('/login/member'),
        ),
        data: (session) {
          if (session.memberId == null && session.userId == null) {
            return _GoogleOnlyBody(session: session);
          }
          final dataAsync = ref.watch(memberDashboardDataProvider(session));
          return dataAsync.when(
            loading: () => const AppLoadingScreen(message: 'Chargement…'),
            error: (_, __) => AppErrorScreen(
              onRetry: () => ref.invalidate(memberDashboardDataProvider(session)),
              onBackToLogin: () => context.go('/login/member'),
            ),
            data: (data) => _MediaMemberBody(session: session, data: data),
          );
        },
      ),
    );
  }
}

class _GoogleOnlyBody extends ConsumerWidget {
  const _GoogleOnlyBody({required this.session});

  final LocalSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MediaMemberHeader(
          name: session.googleDisplayName ?? 'Membre Média',
          email: session.email ?? '',
          photoUrl: session.googlePhotoUrl,
        ),
        const SizedBox(height: 12),
        Consumer(
          builder: (context, ref, _) {
            final sync = ref.watch(backgroundSyncStateProvider);
            return MemberSimpleSyncBadge(state: sync);
          },
        ),
        const SizedBox(height: 16),
        PremiumCard(
          child: Text(
            'Votre profil sera enrichi dès que votre compte membre sera lié.',
            style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.9)),
          ),
        ),
      ],
    );
  }
}

class _MediaMemberBody extends ConsumerStatefulWidget {
  const _MediaMemberBody({required this.session, required this.data});

  final LocalSession session;
  final MemberDashboardData data;

  @override
  ConsumerState<_MediaMemberBody> createState() => _MediaMemberBodyState();
}

class _MediaMemberBodyState extends ConsumerState<_MediaMemberBody> {
  Future<void> _refresh() async {
    await ManualSyncRefreshService().refresh();
    ref.invalidate(memberDashboardDataProvider(widget.session));
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final session = widget.session;

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppTheme.brandOrange,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _MediaMemberHeader(
            name: data.displayName,
            email: session.email ?? '',
            photoUrl: session.googlePhotoUrl,
            badge: data.isHabilite
                ? MemberStatusBadge.habilite()
                : MemberStatusBadge.watch(),
          ),
          const SizedBox(height: 12),
          Consumer(
            builder: (context, ref, _) {
              final sync = ref.watch(backgroundSyncStateProvider);
              return MemberSimpleSyncBadge(state: sync);
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              MemberProgressRing(percent: data.weekAttendancePercent),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${data.weekPresentCount}/${data.weekSessionCount} séances',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.brandWhite,
                      ),
                    ),
                    Text(
                      'Présence : ${data.weekAttendancePercent.round()} %',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (data.mediaAssignment != null) ...[
            const SizedBox(height: 14),
            MemberAssignmentCard(
              title: 'Affectation Média',
              subtitle: data.mediaAssignment!,
              icon: Icons.videocam_outlined,
            ),
          ],
          const SizedBox(height: 14),
          PremiumCard(
            child: Column(
              children: [
                _row('Code membre', data.memberCode),
                _row('Département', data.department),
                _row('Rôle', data.role),
                _row('QR Code', data.qrAvailable ? 'Disponible' : 'Non généré'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (data.attendanceHistory.isNotEmpty)
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
          const SizedBox(height: 14),
          if (data.notifications.isNotEmpty) ...[
            const Text('Notifications',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.brandOrange)),
            const SizedBox(height: 8),
            ...data.notifications.map(
              (n) => PremiumCard(
                onTap: () async {
                  if (!n.isRead) {
                    await LocalNotificationRepository.instance.markRead(n.id);
                    ref.invalidate(memberDashboardDataProvider(session));
                  }
                },
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    n.isRead ? Icons.notifications_none : Icons.notifications_active,
                    color: AppTheme.brandOrange,
                  ),
                  title: Text(n.title),
                  subtitle: n.message.isNotEmpty ? Text(n.message) : null,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppTheme.textMuted))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _MediaMemberHeader extends StatelessWidget {
  const _MediaMemberHeader({
    required this.name,
    required this.email,
    this.photoUrl,
    this.badge,
  });

  final String name;
  final String email;
  final String? photoUrl;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppTheme.brandBlue.withValues(alpha: 0.2),
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
            child: photoUrl == null
                ? const Icon(Icons.person, size: 36, color: AppTheme.brandBlue)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.brandWhite,
                  ),
                ),
                Text(email, style: const TextStyle(color: AppTheme.textSecondary)),
                if (badge != null) ...[const SizedBox(height: 8), badge!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
