import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../../../core/advanced/pdf/pdf_preview_cache.dart';
import '../../../core/messaging/user_friendly_message_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/components/advanced_design_system.dart';
import '../../advanced/presentation/advanced_providers.dart';

/// Panneau d'actions rapides intelligentes pour le tableau de bord Admin.
class DashboardSmartQuickActions extends ConsumerStatefulWidget {
  const DashboardSmartQuickActions({super.key, required this.userRole});

  final String userRole;

  bool get _isAdminPanel {
    return userRole == AppConstants.roleAdmin ||
        userRole == AppConstants.roleAdminGeneral ||
        userRole == AppConstants.roleAdminGeneralOwner ||
        userRole == AppConstants.roleMediaLead;
  }

  @override
  ConsumerState<DashboardSmartQuickActions> createState() =>
      _DashboardSmartQuickActionsState();
}

class _DashboardSmartQuickActionsState
    extends ConsumerState<DashboardSmartQuickActions> {
  String? _runningKey;

  static const _actions = <_QuickActionDef>[
    _QuickActionDef(
      key: 'fix_invisible_pointage',
      title: 'Corriger membres invisibles au pointage',
      icon: Icons.visibility_off_outlined,
      color: AppTheme.errorProd,
      priority: true,
    ),
    _QuickActionDef(
      key: 'merge_duplicates',
      title: 'Fusionner doublons',
      icon: Icons.merge_type,
      color: AppTheme.brandOrange,
      priority: true,
      navigateTo: '/advanced/duplicate-merge',
    ),
    _QuickActionDef(
      key: 'generate_sunday_lists',
      title: 'Générer listes Média du dimanche',
      icon: Icons.calendar_month_outlined,
      color: AppTheme.goldAccent,
    ),
    _QuickActionDef(
      key: 'preview_last_pdf',
      title: 'Prévisualiser dernier PDF',
      icon: Icons.picture_as_pdf_outlined,
      color: AppTheme.brandBlue,
      navigateTo: '/advanced/pdf-preview?key=last_pdf',
    ),
    _QuickActionDef(
      key: 'verify_qr_codes',
      title: 'Vérifier QR Codes',
      icon: Icons.qr_code_scanner,
      color: AppTheme.brandBlue,
    ),
    _QuickActionDef(
      key: 'fix_incomplete_lists',
      title: 'Vérifier listes incomplètes',
      icon: Icons.playlist_add_check_outlined,
      color: AppTheme.warningProd,
    ),
    _QuickActionDef(
      key: 'retry_sync',
      title: 'Relancer synchronisation',
      icon: Icons.cloud_sync_outlined,
      color: AppTheme.brandBlue,
    ),
    _QuickActionDef(
      key: 'verify_media_requests',
      title: 'Vérifier demandes Google',
      icon: Icons.mail_outline,
      color: AppTheme.brandOrange,
      navigateTo: '/admin/media-activation-requests',
    ),
    _QuickActionDef(
      key: 'verify_deleted_members',
      title: 'Vérifier membres supprimés',
      icon: Icons.delete_sweep_outlined,
      color: AppTheme.textMuted,
      navigateTo: '/members/trash',
    ),
    _QuickActionDef(
      key: 'prepare_exports',
      title: 'Préparer rapport intelligent',
      icon: Icons.analytics_outlined,
      color: AppTheme.goldAccent,
      navigateTo: '/advanced/report',
    ),
    _QuickActionDef(
      key: 'open_diagnostic',
      title: 'Ouvrir Diagnostic Admin',
      icon: Icons.medical_services_outlined,
      color: AppTheme.cardSecondary,
      navigateTo: '/admin/diagnostic',
    ),
  ];

  Future<void> _run(_QuickActionDef action) async {
    if (_runningKey != null) return;

    if (action.key == 'preview_last_pdf' &&
        PdfPreviewCache.instance.get('last_pdf') == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun document récent. Générez d\'abord un rapport.'),
        ),
      );
      return;
    }

    setState(() => _runningKey = action.key);
    try {
      final session = await ref.read(localSessionProvider.future);
      final service = ref.read(quickActionServiceProvider);
      final entry = await service.run(
        action.key,
        actorId: session.userId,
        actorName: session.displayName,
        responsible: session.displayName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            entry.success
                ? (entry.message ?? UserFriendlyMessageService.success())
                : UserFriendlyMessageService.genericError(),
          ),
        ),
      );
      if (action.navigateTo != null) {
        context.push(action.navigateTo!);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(UserFriendlyMessageService.genericError())),
        );
      }
    } finally {
      if (mounted) setState(() => _runningKey = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget._isAdminPanel) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions intelligentes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        for (final action in _actions)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: QuickActionCard(
              title: action.title,
              icon: action.icon,
              color: action.color,
              status: action.priority ? 'Priorité' : null,
              loading: _runningKey == action.key,
              onTap: () => _run(action),
            ),
          ),
      ],
    );
  }
}

class _QuickActionDef {
  const _QuickActionDef({
    required this.key,
    required this.title,
    required this.icon,
    required this.color,
    this.priority = false,
    this.navigateTo,
  });

  final String key;
  final String title;
  final IconData icon;
  final Color color;
  final bool priority;
  final String? navigateTo;
}

typedef SmartQuickActionsPanelWidget = DashboardSmartQuickActions;
