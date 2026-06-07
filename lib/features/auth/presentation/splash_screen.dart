import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../../../core/bootstrap/splash_controller.dart';
import '../../../core/ui/startup_loading_guard.dart';
import '../../../core/widgets/app_shell_screens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.statusMessage = 'Initialisation en cours…',
  });

  final String statusMessage;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scale = _ClampedScaleAnimation(
      Tween<double>(begin: 0.88, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  /// Arrête l'animation avant navigation (évite TransformLayer invalide).
  void prepareForNavigation() {
    if (_controller.isAnimating) {
      _controller.stop();
    }
    _controller.value = 1;
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.premiumBlack,
      child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.premiumBlack,
                Color(0xFF0D0D0D),
                Color(0xFF1A1208),
              ],
            ),
          ),
          child: SafeArea(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fade.value.clamp(0.0, 1.0),
                  child: child,
                );
              },
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.goldAccent.withValues(alpha: 0.35),
                                blurRadius: 36,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 110,
                              height: 110,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.church,
                                size: 72,
                                color: AppTheme.goldAccent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          AppConstants.appName,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.goldAccent,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          AppConstants.appFullName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.brandWhite,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppConstants.city,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.goldLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 40),
                        const ProfessionalLoader(),
                        const SizedBox(height: 16),
                        Text(
                          widget.statusMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary.withValues(alpha: 0.95),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Splash route — max 2 s then session-aware navigation.
class SplashRouteScreen extends ConsumerStatefulWidget {
  const SplashRouteScreen({super.key});

  @override
  ConsumerState<SplashRouteScreen> createState() => _SplashRouteScreenState();
}

class _SplashRouteScreenState extends ConsumerState<SplashRouteScreen> {
  bool _navigated = false;
  final GlobalKey<_SplashScreenState> _splashKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final delay = StartupUiFlags.bootstrapGateCompleted
        ? const Duration(milliseconds: 400)
        : SplashController.maxSplashDuration;
    Future<void>.delayed(delay, _goNext);
  }

  Future<void> _goNext() async {
    if (_navigated || !mounted) return;
    _navigated = true;

    _splashKey.currentState?.prepareForNavigation();
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    await SplashController.completeSplashNavigation(context: context, ref: ref);
  }

  @override
  Widget build(BuildContext context) {
    return SplashScreen(key: _splashKey);
  }
}

/// Scale toujours > 0 — évite « TransformLayer invalid matrix ».
class _ClampedScaleAnimation extends Animation<double>
    with AnimationWithParentMixin<double> {
  _ClampedScaleAnimation(this.parent);

  @override
  final Animation<double> parent;

  @override
  double get value {
    final v = parent.value;
    if (!v.isFinite || v <= 0) return 0.01;
    return v.clamp(0.01, 2.0);
  }
}
