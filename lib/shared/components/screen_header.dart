import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'premium_ui_kit.dart';

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showFirebaseIndicator = false,
    this.isFirebaseConnected = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showFirebaseIndicator;
  final bool isFirebaseConnected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceContainer,
            AppTheme.surfaceContainer.withValues(alpha: 0.8),
            AppTheme.goldDark.withValues(alpha: 0.08),
          ],
        ),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF333333)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showFirebaseIndicator)
                FirebaseConnectionIndicator(isConnected: isFirebaseConnected),
            ],
          ),
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions!,
            ),
          ],
        ],
      ),
    );
  }
}
