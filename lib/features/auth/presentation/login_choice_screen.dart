import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../shared/components/auth_ui_kit.dart';

/// Écran de choix — même kit UI que membre / admin (14 px, centré, compact).
class LoginChoiceScreen extends StatelessWidget {
  const LoginChoiceScreen({super.key});

  static const _accent = AppTheme.goldAccent;
  static const _accentLight = AppTheme.goldLight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.premiumBlack,
      body: AuthCenteredShell(
        accentColor: _accent,
        builder: (context, m) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppLogo(size: m.logoSize, showTitle: false),
              SizedBox(height: m.gapMd),
              const AuthRoleBadge(
                label: 'Accueil',
                icon: Icons.home_outlined,
                accent: _accent,
                accentLight: _accentLight,
              ),
              SizedBox(height: m.gapSm + 2),
              Text(
                'Bienvenue sur ${AppConstants.appName}',
                textAlign: TextAlign.center,
                style: authTextStyle(weight: FontWeight.w700),
              ),
              SizedBox(height: m.gapSm),
              Text(
                'Choisissez votre espace de connexion',
                textAlign: TextAlign.center,
                style: authTextStyle(color: AppTheme.textMuted),
              ),
              SizedBox(height: m.gapMd),
              AuthFormCard(
                accentColor: _accent,
                compact: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _AuthChoiceButton(
                      label: 'Connexion Admin / Responsable',
                      icon: Icons.admin_panel_settings_outlined,
                      color: AppTheme.brandOrange,
                      glowColor: const Color(0xFFE64A19),
                      minHeight: m.isCompactHeight ? 44 : 46,
                      onPressed: () => context.push('/login/admin'),
                    ),
                    SizedBox(height: m.gapSm + 4),
                    _AuthChoiceButton(
                      label: 'Connexion Membre',
                      icon: Icons.person_outline,
                      color: AppTheme.brandBlue,
                      glowColor: const Color(0xFF1E88E5),
                      minHeight: m.isCompactHeight ? 44 : 46,
                      onPressed: () => context.push('/login/member'),
                    ),
                    SizedBox(height: m.gapMd),
                    AuthSecurityBanner(
                      message: AppTheme.memberChoiceSecurityMessage,
                      accentColor: AppTheme.brandBlue,
                    ),
                  ],
                ),
              ),
              SizedBox(height: m.gapMd),
              Text(
                AppConstants.organizationLegalLine,
                textAlign: TextAlign.center,
                style: authTextStyle(
                  color: AppTheme.textMuted.withValues(alpha: 0.65),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AuthChoiceButton extends StatelessWidget {
  const _AuthChoiceButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.glowColor,
    required this.minHeight,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color glowColor;
  final double minHeight;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      elevation: 2,
      shadowColor: glowColor.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: minHeight),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: AppTheme.brandWhite),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: authTextStyle(
                    color: AppTheme.brandWhite,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
