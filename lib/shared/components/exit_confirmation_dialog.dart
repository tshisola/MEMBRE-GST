import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Confirmation avant de quitter l'application depuis le Dashboard.
class ExitConfirmationDialog {
  ExitConfirmationDialog._();

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text(
          'Quitter l\'application ?',
          style: TextStyle(color: AppTheme.brandWhite),
        ),
        content: const Text(
          'Voulez-vous vraiment quitter MEDIA LUBUMBASHI ?',
          style: TextStyle(color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.brandOrange),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

typedef ExitConfirmation = ExitConfirmationDialog;
