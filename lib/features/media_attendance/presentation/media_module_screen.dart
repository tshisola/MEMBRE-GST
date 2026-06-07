import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../../../core/firebase/firebase_initializer.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../shared/components/pop_scope_back_guard.dart';
import '../../../shared/components/app_drawer.dart';
import '../../../shared/components/premium_ui_kit.dart';
import '../../../shared/components/screen_header.dart';

class MediaModuleScreen extends StatelessWidget {
  const MediaModuleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isConnected = FirebaseInitializer.isInitialized;

    return PopScopeBackGuard(
      fallbackRoute: '/dashboard',
      child: Scaffold(
      backgroundColor: AppTheme.premiumBlack,
      drawer: const AppDrawer(currentRoute: '/media'),
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        leading: const AppBackButton(fallbackRoute: '/dashboard'),
        title: const Text('Département Média'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FirebaseConnectionIndicator(
              isConnected: isConnected,
              compact: true,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          ScreenHeader(
            title: 'Module Média',
            subtitle: 'IFCM ${AppConstants.city} — Gestion complète',
            showFirebaseIndicator: true,
            isFirebaseConnected: isConnected,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.05,
              children: [
                _ModuleTile(
                  title: 'Pointage',
                  subtitle: 'Présence du jour',
                  icon: Icons.fact_check_outlined,
                  gradient: const [AppTheme.goldLight, AppTheme.goldAccent],
                  onTap: () => context.push('/media/attendance'),
                ),
                _ModuleTile(
                  title: 'Rôles',
                  subtitle: 'Assignation média',
                  icon: Icons.badge_outlined,
                  gradient: const [Color(0xFF5C6BC0), Color(0xFF3949AB)],
                  onTap: () => context.push('/media/roles'),
                ),
                _ModuleTile(
                  title: 'Listes',
                  subtitle: 'Dimanche & manuelles',
                  icon: Icons.list_alt,
                  gradient: const [Color(0xFF26A69A), Color(0xFF00897B)],
                  onTap: () => context.push('/media/lists'),
                ),
                _ModuleTile(
                  title: 'Historique',
                  subtitle: 'Archives pointage',
                  icon: Icons.history,
                  gradient: const [Color(0xFF78909C), Color(0xFF546E7A)],
                  onTap: () => context.push('/media/history'),
                ),
                _ModuleTile(
                  title: 'Exports',
                  subtitle: 'PDF & CSV',
                  icon: Icons.file_download_outlined,
                  gradient: const [Color(0xFF66BB6A), Color(0xFF43A047)],
                  onTap: () => context.push('/media/lists'),
                ),
                _ModuleTile(
                  title: 'Synchronisation',
                  subtitle: 'Firebase temps réel',
                  icon: Icons.cloud_sync_outlined,
                  gradient: const [Color(0xFF42A5F5), Color(0xFF1565C0)],
                  onTap: () => context.push('/admin/sync'),
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

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                gradient.first.withValues(alpha: 0.25),
                AppTheme.surfaceContainer,
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
