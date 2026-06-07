import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/local_session.dart';
import 'app_providers.dart';

/// Session en cache pour les redirections GoRouter sans écran de chargement bloquant.
final sessionForRedirectProvider = Provider<LocalSession?>((ref) {
  final async = ref.watch(localSessionProvider);
  return async.when(
    data: (session) => session,
    loading: () => async.value,
    error: (_, __) => async.value,
  );
});
