import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../../../core/auth/login_controller.dart';
import '../../../core/navigation/app_deep_link_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/auth/logout_service.dart';
import '../../media_auth/presentation/media_member_auth_controller.dart';
import '../../media_auth/presentation/widgets/google_login_button.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../shared/components/auth_ui_kit.dart';

/// Connexion Membre — responsive, centré, police 14 px, carte compacte.
class MemberLoginScreen extends ConsumerStatefulWidget {
  const MemberLoginScreen({super.key});

  @override
  ConsumerState<MemberLoginScreen> createState() => _MemberLoginScreenState();
}

class _MemberLoginScreenState extends ConsumerState<MemberLoginScreen> {
  static const _accent = AppTheme.brandBlue;
  static const _accentLight = Color(0xFF4DA3E0);
  static const _accentGlow = Color(0xFF1E88E5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      disableLoginAutofill();
      ref.read(authFormControllerProvider).reset();
    });
  }

  @override
  void deactivate() {
    ref.read(authFormControllerProvider).reset();
    super.deactivate();
  }

  Future<void> _signInGoogle() async {
    final form = ref.read(authFormControllerProvider);
    form.setLoading(true);
    form.setError(null);
    try {
      final controller = ref.read(mediaMemberAuthControllerProvider);
      final result = await controller.signInWithGoogle();
      if (!mounted) return;
      if (result.userMessage != null && !result.success) {
        form.setError(result.userMessage);
        return;
      }
      if (result.route != null) context.go(result.route!);
    } finally {
      form.setLoading(false);
    }
  }

  Future<void> _submit() async {
    final form = ref.read(authFormControllerProvider);
    final controller = LoginController(form: form, ref: ref);
    final result = await controller.signInMember();

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
      fallbackRoute: result.route ?? '/member/dashboard',
    );
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(authFormControllerProvider);
    final labelStyle = authTextStyle(color: AppTheme.textMuted);

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
                label: 'Espace membre',
                icon: Icons.person_outline,
                accent: _accent,
                accentLight: _accentLight,
              ),
              SizedBox(height: m.gapSm + 2),
              Text(
                'Connexion Membre',
                textAlign: TextAlign.center,
                style: authTextStyle(weight: FontWeight.w700),
              ),
              SizedBox(height: m.gapSm),
              Text(
                AppTheme.memberLoginHintMessage,
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
                      ),
                      child: Column(
                        children: [
                          SecureInputField(
                            controller: form.identifierController,
                            label: 'Identifiant / téléphone / e-mail',
                            hint: 'Tapez manuellement',
                            prefixIcon: Icons.badge_outlined,
                            onClear: () => form.identifierController.clear(),
                          ),
                          SizedBox(height: m.gapSm + 4),
                          PasswordInputField(
                            controller: form.passwordController,
                            obscure: form.obscurePassword,
                            onToggleVisibility: form.togglePasswordVisibility,
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
                            color: AppTheme.danger.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          form.errorMessage!,
                          textAlign: TextAlign.center,
                          style: authTextStyle(color: AppTheme.danger),
                        ),
                      ),
                    ],
                    SizedBox(height: m.gapMd),
                    FilledButton.icon(
                      onPressed: form.isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: AppTheme.brandWhite,
                        disabledBackgroundColor:
                            _accent.withValues(alpha: 0.45),
                        minimumSize: Size(double.infinity, m.isCompactHeight ? 44 : 46),
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
                    SizedBox(height: m.gapMd),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'ou',
                            style: authTextStyle(color: AppTheme.textMuted),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: m.gapMd),
                    GoogleLoginButton(
                      onPressed: form.isLoading ? null : _signInGoogle,
                      isLoading: form.isLoading,
                      fontSize: kAuthFontSize,
                    ),
                    SizedBox(height: m.gapSm),
                    Text(
                      'Département Média uniquement',
                      textAlign: TextAlign.center,
                      style: authTextStyle(color: AppTheme.textMuted),
                    ),
                    SizedBox(height: m.gapSm),
                    AuthLinkButton(
                      label: AppTheme.memberForgotPasswordMessage,
                      color: _accent,
                      onPressed: () {
                        showDialog<void>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppTheme.cardDark,
                            title: Text(
                              'Mot de passe oublié',
                              style: authTextStyle(weight: FontWeight.w600),
                            ),
                            content: Text(
                              AppTheme.memberForgotPasswordMessage,
                              style: authTextStyle(color: AppTheme.textMuted),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(
                                  'OK',
                                  style: authTextStyle(color: _accent),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    AuthLinkButton(
                      label: 'Connexion Admin / Responsable',
                      color: AppTheme.brandOrange,
                      weight: FontWeight.w500,
                      onPressed: () => context.push('/login/choice'),
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
