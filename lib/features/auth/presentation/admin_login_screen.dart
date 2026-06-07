import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../../../core/auth/admin_owner_recovery_service.dart';
import '../../../core/auth/login_controller.dart';
import '../../../core/navigation/app_deep_link_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/auth/logout_service.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../shared/components/auth_ui_kit.dart';

/// Connexion Admin — responsive, centré, police 14 px, carte compacte.
class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  static const _accent = AppTheme.brandOrange;
  static const _accentLight = Color(0xFFFF8A50);
  static const _accentGlow = Color(0xFFE64A19);

  bool _showOwnerRecovery = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      disableLoginAutofill();
      ref.read(authFormControllerProvider).reset();
      _checkRecovery();
    });
  }

  Future<void> _checkRecovery() async {
    final status = await AdminOwnerRecoveryService().evaluate();
    if (mounted) setState(() => _showOwnerRecovery = status.needsRecovery);
  }

  @override
  void deactivate() {
    ref.read(authFormControllerProvider).reset();
    super.deactivate();
  }

  Future<void> _submit() async {
    final form = ref.read(authFormControllerProvider);
    if (form.rememberMe) {
      final ok = await form.confirmRememberMe(context);
      if (!ok) form.setRememberMe(false);
    }

    final controller = LoginController(form: form, ref: ref);
    final result = await controller.signInAdmin();

    if (!mounted) return;
    if (result.error != null) {
      form.setError(result.error);
      return;
    }
    final session = await ref.read(localSessionProvider.future);
    if (!mounted) return;
    await AppDeepLinkService.instance.navigateAfterLogin(
      GoRouter.of(context),
      session,
      fallbackRoute: result.route ?? '/dashboard',
    );
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(authFormControllerProvider);
    final labelStyle = authTextStyle(color: AppTheme.textMuted);

    return Scaffold(
      backgroundColor: AppTheme.premiumBlack,
      body: Stack(
        children: [
          AuthCenteredShell(
            accentColor: _accent,
            builder: (context, m) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppLogo(size: m.logoSize, showTitle: false),
                  SizedBox(height: m.gapMd),
                  const AuthRoleBadge(
                    label: 'Espace responsable',
                    icon: Icons.admin_panel_settings_outlined,
                    accent: _accent,
                    accentLight: _accentLight,
                  ),
                  SizedBox(height: m.gapSm + 2),
                  Text(
                    'Connexion Admin / Responsable',
                    textAlign: TextAlign.center,
                    style: authTextStyle(weight: FontWeight.w700),
                  ),
                  SizedBox(height: m.gapSm),
                  Text(
                    'Accès réservé aux administrateurs et responsables ${AppConstants.city}.',
                    textAlign: TextAlign.center,
                    style: authTextStyle(color: AppTheme.textMuted),
                  ),
                  SizedBox(height: m.gapMd),
                  AuthFormCard(
                    accentColor: _accent,
                    compact: true,
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Theme(
                            data: Theme.of(context).copyWith(
                              inputDecorationTheme: InputDecorationTheme(
                                labelStyle: labelStyle,
                                hintStyle: labelStyle,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                floatingLabelStyle: labelStyle.copyWith(
                                  color: AppTheme.goldAccent,
                                ),
                              ),
                              checkboxTheme: CheckboxThemeData(
                                fillColor: WidgetStateProperty.resolveWith(
                                  (states) => states.contains(
                                    WidgetState.selected,
                                  )
                                      ? _accent
                                      : Colors.transparent,
                                ),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.35),
                                ),
                              ),
                            ),
                            child: Column(
                              children: [
                                SecureInputField(
                                  controller: form.identifierController,
                                  label: 'Identifiant ou e-mail',
                                  hint: 'Tapez manuellement',
                                  prefixIcon: Icons.badge_outlined,
                                  onClear: () =>
                                      form.identifierController.clear(),
                                ),
                                SizedBox(height: m.gapSm + 4),
                                PasswordInputField(
                                  controller: form.passwordController,
                                  obscure: form.obscurePassword,
                                  onToggleVisibility:
                                      form.togglePasswordVisibility,
                                ),
                              ],
                            ),
                          ),
                          if (form.errorMessage != null) ...[
                            SizedBox(height: m.gapSm + 4),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.danger.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      AppTheme.danger.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Text(
                                form.errorMessage!,
                                textAlign: TextAlign.center,
                                style: authTextStyle(color: AppTheme.danger),
                              ),
                            ),
                          ],
                          SizedBox(height: m.gapSm + 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: Checkbox(
                                  value: form.rememberMe,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  onChanged: (v) =>
                                      form.setRememberMe(v ?? false),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Mémoriser la session (identifiant uniquement)',
                                  style: authTextStyle(
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: m.gapMd),
                          FilledButton.icon(
                            onPressed: form.isLoading ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: AppTheme.brandWhite,
                              disabledBackgroundColor:
                                  _accent.withValues(alpha: 0.45),
                              minimumSize: Size(
                                double.infinity,
                                m.isCompactHeight ? 44 : 46,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              shadowColor: _accentGlow.withValues(alpha: 0.45),
                            ),
                            icon: form.isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.brandWhite,
                                    ),
                                  )
                                : const Icon(Icons.login, size: 18),
                            label: Text(
                              'Se connecter',
                              style: authTextStyle(
                                color: AppTheme.brandWhite,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(height: m.gapSm),
                          AuthLinkButton(
                            label: 'Mot de passe oublié ?',
                            color: AppTheme.goldLight,
                            onPressed: () =>
                                context.push('/auth/forgot-password'),
                          ),
                          AuthLinkButton(
                            label: 'Connexion Membre',
                            color: AppTheme.brandBlue,
                            weight: FontWeight.w500,
                            onPressed: () => context.go('/login/member'),
                          ),
                          if (_showOwnerRecovery)
                            AuthLinkButton(
                              label: 'Récupération responsable principal',
                              color: AppTheme.goldLight,
                              weight: FontWeight.w500,
                              onPressed: () =>
                                  context.push('/auth/owner-recovery'),
                            ),
                        ],
                      ),
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
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  color: AppTheme.brandWhite.withValues(alpha: 0.85),
                  tooltip: 'Retour',
                  onPressed: () => context.go('/login/choice'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
