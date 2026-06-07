import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../app/theme.dart';
import '../../core/members/qr_display_formatter.dart';

/// Badge showing member sync status (green/orange/blue/red).
class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({super.key, required this.status, this.compact = true});

  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (color, label) = _style(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon(status), size: compact ? 12 : 14, color: color),
          if (!compact) ...[
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  static (Color, String) _style(String status) {
    switch (status) {
      case AppConstants.syncStatusSynced:
        return (AppTheme.success, 'Synchronisé');
      case AppConstants.syncStatusPending:
        return (const Color(0xFFFFB74D), 'En attente');
      case AppConstants.syncStatusSyncing:
        return (const Color(0xFF42A5F5), 'En cours');
      case AppConstants.syncStatusError:
        return (AppTheme.danger, 'Erreur');
      case AppConstants.syncStatusConflict:
        return (const Color(0xFFCE93D8), 'Conflit');
      case AppConstants.syncStatusLocal:
      default:
        return (AppTheme.textSecondary, 'Local');
    }
  }

  static IconData _icon(String status) {
    switch (status) {
      case AppConstants.syncStatusSynced:
        return Icons.cloud_done;
      case AppConstants.syncStatusPending:
        return Icons.schedule;
      case AppConstants.syncStatusSyncing:
        return Icons.sync;
      case AppConstants.syncStatusError:
        return Icons.error_outline;
      case AppConstants.syncStatusConflict:
        return Icons.merge_type;
      default:
        return Icons.storage;
    }
  }
}

/// Manual refresh button (blue) with loader and snackbar feedback.
class RefreshButton extends StatefulWidget {
  const RefreshButton({
    super.key,
    required this.onRefresh,
    this.label = 'Actualiser',
    this.compact = false,
  });

  final Future<String> Function() onRefresh;
  final String label;
  final bool compact;

  @override
  State<RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends State<RefreshButton> {
  bool _loading = false;

  Future<void> _run() async {
    setState(() => _loading = true);
    try {
      final message = await widget.onRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return IconButton(
        onPressed: _loading ? null : _run,
        icon: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.refresh, color: Color(0xFF42A5F5)),
        tooltip: widget.label,
      );
    }

    return OutlinedButton.icon(
      onPressed: _loading ? null : _run,
      icon: _loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh, color: Color(0xFF42A5F5)),
      label: Text(
        _loading ? 'Actualisation…' : widget.label,
        style: const TextStyle(color: Color(0xFF42A5F5)),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFF42A5F5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class PullToRefreshMembers extends StatelessWidget {
  const PullToRefreshMembers({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.goldAccent,
      backgroundColor: AppTheme.surfaceContainer,
      onRefresh: onRefresh,
      child: child,
    );
  }
}

class MemberQrCard extends StatelessWidget {
  const MemberQrCard({
    super.key,
    required this.qrData,
    required this.memberCode,
    required this.qrWidget,
  });

  final String qrData;
  final String memberCode;
  final Widget qrWidget;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              memberCode,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.goldAccent,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: qrWidget,
            ),
            const SizedBox(height: 12),
            Text(
              QrDisplayFormatter.displayLabel(qrData, memberCode: memberCode),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              QrDisplayFormatter.syncHint(qrData),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: QrDisplayFormatter.isLocalOnly(qrData)
                    ? const Color(0xFFFFB74D)
                    : AppTheme.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RealtimeUpdateBanner extends StatelessWidget {
  const RealtimeUpdateBanner({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.success.withValues(alpha: 0.15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.cloud_done, color: AppTheme.success, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 13)),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}

class SyncErrorCard extends StatelessWidget {
  const SyncErrorCard({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.danger.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.danger),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}

class DuplicateWarningDialog extends StatelessWidget {
  const DuplicateWarningDialog({
    super.key,
    required this.reason,
    required this.onViewExisting,
    this.onContinue,
    this.showContinue = false,
  });

  final String reason;
  final VoidCallback onViewExisting;
  final VoidCallback? onContinue;
  final bool showContinue;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceContainer,
      title: const Row(
        children: [
          Icon(Icons.warning_amber, color: Color(0xFFFFB74D)),
          SizedBox(width: 8),
          Text('Doublon détecté'),
        ],
      ),
      content: Text(reason),
      actions: [
        if (showContinue && onContinue != null)
          TextButton(onPressed: onContinue, child: const Text('Continuer quand même')),
        TextButton(
          onPressed: onViewExisting,
          child: const Text('Voir membre existant'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}

class MemberCreatedSuccessDialog extends StatelessWidget {
  const MemberCreatedSuccessDialog({
    super.key,
    required this.memberName,
    required this.memberCode,
    required this.syncStatus,
  });

  final String memberName;
  final String memberCode;
  final String syncStatus;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceContainer,
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: AppTheme.success),
          SizedBox(width: 8),
          Text('Membre créé'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(memberName, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Code: $memberCode'),
          const SizedBox(height: 8),
          SyncStatusBadge(status: syncStatus, compact: false),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
