import 'package:flutter/material.dart';

import '../../../../app/constants.dart';
import '../../../../app/theme.dart';

class ActivationStatusBadge extends StatelessWidget {
  const ActivationStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      AppConstants.activationStatusActive => (AppTheme.success, 'Actif'),
      AppConstants.activationStatusRejected => (AppTheme.danger, 'Refusé'),
      AppConstants.activationStatusSuspended => (AppTheme.warningProd, 'Suspendu'),
      AppConstants.activationStatusDisabled => (AppTheme.textMuted, 'Désactivé'),
      _ => (const Color(0xFFFFB74D), 'En attente'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color)),
    );
  }
}
