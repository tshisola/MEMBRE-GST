import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../app/constants.dart';
import '../../app/theme.dart';

/// Taille unique pour tous les écrans de connexion.
const double kAuthFontSize = 14;

/// Largeur max de la carte — ne grandit jamais au-delà (tablettes / grands écrans).
const double kAuthCardMaxWidth = 360;

/// Largeur min de la carte (petits téléphones).
const double kAuthCardMinWidth = 280;

TextStyle authTextStyle({
  Color color = AppTheme.brandWhite,
  FontWeight weight = FontWeight.w400,
}) {
  return TextStyle(
    fontSize: kAuthFontSize,
    color: color,
    fontWeight: weight,
    height: 1.45,
  );
}

/// Métriques adaptatives — carte compacte centrée sur toute résolution.
class AuthScreenMetrics {
  const AuthScreenMetrics({
    required this.cardWidth,
    required this.logoSize,
    required this.padding,
    required this.minContentHeight,
    required this.gapSm,
    required this.gapMd,
    required this.isCompactHeight,
  });

  final double cardWidth;
  final double logoSize;
  final EdgeInsets padding;
  final double minContentHeight;
  final double gapSm;
  final double gapMd;
  final bool isCompactHeight;

  static AuthScreenMetrics resolve({
    required BoxConstraints constraints,
    required MediaQueryData media,
  }) {
    final width = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : media.size.width;
    final height = constraints.maxHeight.isFinite
        ? constraints.maxHeight
        : media.size.height;

    final cardWidth = math.min(
      kAuthCardMaxWidth,
      math.max(kAuthCardMinWidth, width * 0.9),
    );

    final isCompactHeight = height < 620;
    final isLargeHeight = height > 820;

    final horizontalInset = math.max(16.0, (width - cardWidth) / 2);

    return AuthScreenMetrics(
      cardWidth: cardWidth,
      logoSize: isCompactHeight ? 52 : (isLargeHeight ? 64 : 58),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalInset,
        vertical: isCompactHeight ? 8 : 12,
      ),
      minContentHeight: height - media.padding.vertical - 8,
      gapSm: isCompactHeight ? 6 : 8,
      gapMd: isCompactHeight ? 10 : 14,
      isCompactHeight: isCompactHeight,
    );
  }
}

/// Fond radial auth — accent sans remplir l'écran de couleur.
BoxDecoration authRadialBackground(Color accent) {
  return BoxDecoration(
    gradient: RadialGradient(
      center: Alignment.topCenter,
      radius: 1.2,
      colors: [
        accent.withValues(alpha: 0.15),
        AppTheme.premiumBlack.withValues(alpha: 0.94),
        AppTheme.premiumBlack,
      ],
      stops: const [0.0, 0.42, 1.0],
    ),
  );
}

/// Conteneur centré — le login ne s'étire jamais sur grands écrans.
class AuthCenteredShell extends StatelessWidget {
  const AuthCenteredShell({
    super.key,
    required this.accentColor,
    required this.builder,
  });

  final Color accentColor;
  final Widget Function(BuildContext context, AuthScreenMetrics metrics) builder;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return DecoratedBox(
      decoration: authRadialBackground(accentColor),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final metrics = AuthScreenMetrics.resolve(
              constraints: constraints,
              media: media,
            );

            return Align(
              alignment: Alignment.center,
              child: SingleChildScrollView(
                padding: metrics.padding,
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: metrics.minContentHeight,
                    maxWidth: metrics.cardWidth,
                  ),
                  child: Center(
                    child: builder(context, metrics),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Bouton lien auth — police 14 px.
class AuthLinkButton extends StatelessWidget {
  const AuthLinkButton({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
    this.weight = FontWeight.w400,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: authTextStyle(color: color, weight: weight),
      ),
    );
  }
}

/// Badge rôle (membre / responsable).
class AuthRoleBadge extends StatelessWidget {
  const AuthRoleBadge({
    super.key,
    required this.label,
    required this.icon,
    required this.accent,
    required this.accentLight,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final Color accentLight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.22),
            accent.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentLight.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accentLight),
          const SizedBox(width: 6),
          Text(
            label,
            style: authTextStyle(color: accentLight, weight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Carte connexion premium — accent coloré en haut.
class AuthFormCard extends StatelessWidget {
  const AuthFormCard({
    super.key,
    required this.child,
    this.accentColor = AppTheme.brandBlue,
    this.compact = false,
  });

  final Widget child;
  final Color accentColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final padding = compact
        ? const EdgeInsets.fromLTRB(16, 18, 16, 16)
        : const EdgeInsets.fromLTRB(20, 22, 20, 20);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor,
                    accentColor.withValues(alpha: 0.45),
                  ],
                ),
              ),
            ),
            Padding(
              padding: padding,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bannière sécurité — même taille de police que le reste de l'auth.
class AuthSecurityBanner extends StatelessWidget {
  const AuthSecurityBanner({
    super.key,
    this.message = AppConstants.securityLoginMessage,
    this.accentColor = AppTheme.brandOrange,
  });

  final String message;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.18),
            accentColor.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: accentColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: authTextStyle(color: accentColor.withValues(alpha: 0.95)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Alias demandé — même widget que [SecureInputField].
typedef SecureLoginField = SecureInputField;

/// Professional auth input widgets — no autofill, no suggestions.
class SecureInputField extends StatelessWidget {
  const SecureInputField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon = Icons.person_outline,
    this.keyboardType = TextInputType.text,
    this.onClear,
    this.textInputAction = TextInputAction.next,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final VoidCallback? onClear;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autocorrect: false,
      enableSuggestions: false,
      enableIMEPersonalizedLearning: false,
      smartDashesType: SmartDashesType.disabled,
      smartQuotesType: SmartQuotesType.disabled,
      autofillHints: const <String>[],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(prefixIcon, color: AppTheme.goldAccent),
        suffixIcon: ClearInputButton(onPressed: onClear ?? controller.clear),
      ),
    );
  }
}

class PasswordInputField extends StatelessWidget {
  const PasswordInputField({
    super.key,
    required this.controller,
    required this.obscure,
    required this.onToggleVisibility,
    this.label = 'Mot de passe',
    this.textInputAction = TextInputAction.done,
  });

  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggleVisibility;
  final String label;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      textInputAction: textInputAction,
      autocorrect: false,
      enableSuggestions: false,
      enableIMEPersonalizedLearning: false,
      smartDashesType: SmartDashesType.disabled,
      smartQuotesType: SmartQuotesType.disabled,
      autofillHints: const <String>[],
      keyboardType: TextInputType.visiblePassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.goldAccent),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PasswordVisibilityButton(
              obscure: obscure,
              onToggle: onToggleVisibility,
            ),
            ClearInputButton(onPressed: controller.clear),
          ],
        ),
      ),
    );
  }
}

class ClearInputButton extends StatelessWidget {
  const ClearInputButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.clear, size: 20),
      tooltip: 'Effacer',
      onPressed: onPressed,
    );
  }
}

class PasswordVisibilityButton extends StatelessWidget {
  const PasswordVisibilityButton({
    super.key,
    required this.obscure,
    required this.onToggle,
  });

  final bool obscure;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
      tooltip: obscure ? 'Afficher' : 'Masquer',
      onPressed: onToggle,
    );
  }
}

class ProfessionalAuthCard extends StatelessWidget {
  const ProfessionalAuthCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.icon,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.surfaceContainer,
              AppTheme.surfaceElevated.withValues(alpha: 0.9),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (icon != null)
              Icon(icon, size: 40, color: AppTheme.actionPrimary),
            if (icon != null) const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class SecurityNoticeBanner extends StatelessWidget {
  const SecurityNoticeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.info.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.info.withValues(alpha: 0.35)),
      ),
      child: const Row(
        children: [
          Icon(Icons.security, color: AppTheme.info, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              AppConstants.securityLoginMessage,
              style: TextStyle(fontSize: 12, color: AppTheme.info),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfessionalActionButton extends StatelessWidget {
  const ProfessionalActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color ?? AppTheme.actionPrimary,
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon ?? Icons.login),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class MemberLoginCard extends StatelessWidget {
  const MemberLoginCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ProfessionalAuthCard(
      title: 'Connexion Membre',
      subtitle: 'Espace personnel IFCM ${AppConstants.city}',
      icon: Icons.person_outline,
      child: child,
    );
  }
}

class AdminLoginCard extends StatelessWidget {
  const AdminLoginCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ProfessionalAuthCard(
      title: 'Connexion Admin / Responsable',
      subtitle: 'Accès réservé aux responsables',
      icon: Icons.admin_panel_settings_outlined,
      child: child,
    );
  }
}

class TemporaryPasswordCard extends StatelessWidget {
  const TemporaryPasswordCard({
    super.key,
    required this.identifier,
    required this.temporaryPassword,
    required this.onDone,
  });

  final String identifier;
  final String temporaryPassword;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return ProfessionalAuthCard(
      title: 'Compte membre créé',
      subtitle: 'Remettez ces identifiants au membre (affichage unique)',
      icon: Icons.vpn_key_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CredentialRow(label: 'Identifiant', value: identifier),
          const SizedBox(height: 12),
          _CredentialRow(label: 'Mot de passe provisoire', value: temporaryPassword),
          const SizedBox(height: 8),
          const Text(
            'Ce mot de passe ne sera plus affiché. Le membre devra le changer à la première connexion.',
            style: TextStyle(fontSize: 11, color: AppTheme.warning),
          ),
          const SizedBox(height: 20),
          ProfessionalActionButton(
            label: 'J\'ai noté les identifiants',
            icon: Icons.check,
            onPressed: onDone,
          ),
        ],
      ),
    );
  }
}

class _CredentialRow extends StatelessWidget {
  const _CredentialRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.goldAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class ManualListCard extends StatelessWidget {
  const ManualListCard({
    super.key,
    required this.departmentName,
    required this.listTitle,
    required this.memberCount,
    required this.onTap,
    this.onDelete,
  });

  final String departmentName;
  final String listTitle;
  final int memberCount;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppTheme.actionPrimary.withValues(alpha: 0.2),
          child: const Icon(Icons.list_alt, color: AppTheme.actionPrimary),
        ),
        title: Text(listTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('$departmentName · $memberCount membres'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
                tooltip: 'Supprimer',
                onPressed: onDelete,
              ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class DepartmentListHeader extends StatelessWidget {
  const DepartmentListHeader({
    super.key,
    required this.departmentName,
    required this.listTitle,
  });

  final String departmentName;
  final String listTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppConstants.appFullName,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        Text(
          'DÉPARTEMENT ${departmentName.toUpperCase()}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.goldAccent,
          ),
        ),
        Text(
          'LISTE : ${listTitle.toUpperCase()}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
