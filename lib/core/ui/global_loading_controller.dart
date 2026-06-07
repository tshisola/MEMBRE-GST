import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'loading_timeout_service.dart';

/// État global du loader — jamais bloquant sur les écrans d'authentification.
class GlobalLoadingState {
  const GlobalLoadingState({
    this.isVisible = false,
    this.message,
    this.startedAt,
    this.reason,
  });

  final bool isVisible;
  final String? message;
  final DateTime? startedAt;
  final String? reason;

  GlobalLoadingState copyWith({
    bool? isVisible,
    String? message,
    DateTime? startedAt,
    String? reason,
    bool clearMessage = false,
  }) {
    return GlobalLoadingState(
      isVisible: isVisible ?? this.isVisible,
      message: clearMessage ? null : (message ?? this.message),
      startedAt: startedAt ?? this.startedAt,
      reason: reason ?? this.reason,
    );
  }
}

class GlobalLoadingController extends StateNotifier<GlobalLoadingState> {
  GlobalLoadingController() : super(const GlobalLoadingState());

  Timer? _safetyTimer;

  void show({String? message, String? reason}) {
    _safetyTimer?.cancel();
    state = GlobalLoadingState(
      isVisible: true,
      message: message,
      startedAt: DateTime.now(),
      reason: reason,
    );
    _safetyTimer = Timer(LoadingTimeoutService.defaultTimeout, hide);
  }

  void hide() {
    _safetyTimer?.cancel();
    _safetyTimer = null;
    state = const GlobalLoadingState(isVisible: false);
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    super.dispose();
  }
}

final globalLoadingControllerProvider =
    StateNotifierProvider<GlobalLoadingController, GlobalLoadingState>(
  (ref) => GlobalLoadingController(),
);

/// Chemins où aucun overlay ne doit bloquer les clics.
bool isAuthPublicRoute(String path) {
  return path == '/' ||
      path == '/login' ||
      path.startsWith('/login/') ||
      path.startsWith('/auth/');
}
