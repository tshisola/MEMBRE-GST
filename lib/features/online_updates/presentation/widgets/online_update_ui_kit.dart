import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// Composants UI premium — Mises à jour en ligne.
class OnlineUpdateCard extends StatelessWidget {
  const OnlineUpdateCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.cloud_outlined,
    this.trailing,
    this.onTap,
    this.accentColor = AppTheme.brandOrange,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.cardDark,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class ConfigVersionBadge extends StatelessWidget {
  const ConfigVersionBadge({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? AppTheme.brandBlue).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color ?? AppTheme.brandBlue),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color ?? AppTheme.brandBlue,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class FeatureFlagToggle extends StatelessWidget {
  const FeatureFlagToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: value,
      onChanged: enabled ? onChanged : null,
      activeThumbColor: AppTheme.brandOrange,
      tileColor: AppTheme.cardSecondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

class RemoteThemePreview extends StatelessWidget {
  const RemoteThemePreview({
    super.key,
    required this.primary,
    required this.background,
    required this.card,
  });

  final Color primary;
  final Color background;
  final Color card;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardSecondary),
      ),
      child: Row(
        children: [
          Expanded(child: ColoredBox(color: background)),
          Expanded(child: ColoredBox(color: card)),
          Expanded(child: ColoredBox(color: primary)),
        ],
      ),
    );
  }
}

class PublishSuccessDialog extends StatelessWidget {
  const PublishSuccessDialog({super.key, this.message});

  final String? message;

  static Future<void> show(BuildContext context, {String? message}) {
    return showDialog<void>(
      context: context,
      builder: (_) => PublishSuccessDialog(message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardDark,
      icon: const Icon(Icons.check_circle, color: AppTheme.successProd, size: 48),
      title: const Text('Publication réussie'),
      content: Text(message ?? 'Configuration publiée avec succès.'),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(backgroundColor: AppTheme.brandOrange),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class SyncAllResultDialog extends StatelessWidget {
  const SyncAllResultDialog({super.key, required this.message, required this.success});

  final String message;
  final bool success;

  static Future<void> show(
    BuildContext context, {
    required String message,
    required bool success,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => SyncAllResultDialog(message: message, success: success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardDark,
      icon: Icon(
        success ? Icons.cloud_done : Icons.info_outline,
        color: success ? AppTheme.successProd : AppTheme.warningProd,
        size: 48,
      ),
      title: Text(success ? 'Synchronisation terminée' : 'Information'),
      content: Text(message),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(backgroundColor: AppTheme.brandOrange),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class SyncAllButton extends StatelessWidget {
  const SyncAllButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.brandOrange,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.brandWhite),
            )
          : const Icon(Icons.cloud_sync),
      label: const Text(
        'Synchroniser tout',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    );
  }
}

class PublishConfigButton extends StatelessWidget {
  const PublishConfigButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.brandBlue,
        side: const BorderSide(color: AppTheme.brandBlue),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.publish),
      label: const Text('Publier la configuration'),
    );
  }
}
