import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../../../core/firebase/firebase_initializer.dart';
import '../../../core/auth/logout_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../shared/components/app_drawer.dart';
import '../../../shared/components/pop_scope_back_guard.dart';
import '../../../shared/components/premium_ui_kit.dart';
import '../../../shared/components/screen_header.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = FirebaseInitializer.isInitialized;

    return PopScopeBackGuard(
      fallbackRoute: '/dashboard',
      child: Scaffold(
      backgroundColor: AppTheme.premiumBlack,
      drawer: const AppDrawer(currentRoute: '/settings'),
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        leading: const AppBackButton(fallbackRoute: '/dashboard'),
        title: const Text('Paramètres'),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          ScreenHeader(
            title: 'Paramètres',
            subtitle: AppConstants.appFullName,
            showFirebaseIndicator: true,
            isFirebaseConnected: isConnected,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _SettingsSection(
                  title: 'Organisation',
                  children: [
                    _SettingsTile(
                      icon: Icons.location_city,
                      title: 'Ville',
                      subtitle: AppConstants.city,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.goldAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Lubumbashi',
                          style: TextStyle(
                            color: AppTheme.goldAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.church,
                      title: 'Ministère',
                      subtitle: AppConstants.appFullName,
                    ),
                    _SettingsTile(
                      icon: Icons.videocam,
                      title: 'Département actif',
                      subtitle: 'Département Média',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SettingsSection(
                  title: 'Application',
                  children: [
                    _SettingsTile(
                      icon: Icons.dark_mode,
                      title: 'Thème',
                      subtitle: 'Sombre (par défaut)',
                    ),
                    _SettingsTile(
                      icon: Icons.language,
                      title: 'Langue',
                      subtitle: 'Français',
                    ),
                    _SettingsTile(
                      icon: Icons.info_outline,
                      title: 'Version',
                      subtitle: '1.0.0',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SettingsSection(
                  title: 'Firebase',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.cloud_outlined, color: AppTheme.goldAccent),
                      title: const Text('Statut Firebase'),
                      subtitle: Text(isConnected ? 'Connecté' : 'Hors ligne'),
                      trailing: FirebaseConnectionIndicator(
                        isConnected: isConnected,
                        compact: true,
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.sync, color: AppTheme.goldAccent),
                      title: const Text('Synchronisation'),
                      subtitle: const Text('Gérer la sync Firebase'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/admin/sync'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                AdvancedButton(
                  label: 'Se déconnecter',
                  icon: Icons.logout,
                  variant: AdvancedButtonVariant.danger,
                  onPressed: () async {
                    await ref.read(logoutServiceProvider).logout(ref);
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.goldAccent,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.goldAccent),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing,
    );
  }
}
