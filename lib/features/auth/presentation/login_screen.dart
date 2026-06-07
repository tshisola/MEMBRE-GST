import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/messaging/app_error_presenter.dart';
import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../../../core/auth/logout_service.dart';
import '../../../core/firebase/firebase_initializer.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/storage/local_session.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../shared/components/premium_ui_kit.dart';
import 'login_choice_screen.dart';
import 'member_login_screen.dart';

/// Point d'entrée connexion — redirige vers la connexion membre.
/// Choix Admin/Membre : route `/login/choice`. Legacy : `/login/legacy`.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MemberLoginScreen();
  }
}

/// Connexion IFCM legacy — Firebase ou mode hors-ligne Lubumbashi.
/// Accessible via /login/legacy — code original conservé.
class LegacyLoginScreen extends ConsumerStatefulWidget {
  const LegacyLoginScreen({super.key});

  @override
  ConsumerState<LegacyLoginScreen> createState() => _LegacyLoginScreenState();
}

class _LegacyLoginScreenState extends ConsumerState<LegacyLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailController.clear();
    _passwordController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      disableLoginAutofill();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = ref.read(firebaseAuthServiceProvider);
      if (FirebaseInitializer.isInitialized) {
        await auth.signInWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }

      final prefs = await ref.read(sharedPreferencesProvider.future);
      final session = LocalSession(prefs);
      final email = _emailController.text.trim().isEmpty
          ? 'offline@ifcm.local'
          : _emailController.text.trim();

      await session.saveSession(
        userId: auth.currentUser?.uid ??
            'local-${AppConstants.city.toLowerCase()}',
        email: email,
        role: AppConstants.roleMediaOperator,
        department: AppConstants.mediaDepartmentId,
        isMediaAttendanceOperator: true,
        accountType: AppConstants.accountTypeAdmin,
      );

      ref.invalidate(localSessionProvider);
      await ref.read(localSessionProvider.future);

      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        setState(() => _error = AppErrorPresenter.forUser(e, source: 'login'));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = FirebaseInitializer.isInitialized;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  const AppLogo(size: 100, showTitle: true),
                  const SizedBox(height: 8),
                  Text(
                    AppConstants.appFullName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  FirebaseConnectionIndicator(isConnected: isConnected),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    enableSuggestions: false,
                    autofillHints: const [],
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autocorrect: false,
                    enableSuggestions: false,
                    autofillHints: const [],
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(color: AppTheme.danger, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  AdvancedButton(
                    label: 'Se connecter',
                    icon: Icons.login,
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _signIn,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isConnected
                        ? 'Connexion Firebase active'
                        : 'Mode hors-ligne — ${AppConstants.city}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
