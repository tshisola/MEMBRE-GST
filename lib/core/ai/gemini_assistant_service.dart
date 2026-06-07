import 'package:cloud_functions/cloud_functions.dart';

import '../firebase/firebase_initializer.dart';
import '../messaging/auth_error_sanitizer.dart';
import '../security/role_permission_matrix.dart';

/// Assistant IA MEDIA — appels via Cloud Function (clé serveur uniquement).
class GeminiAssistantService {
  GeminiAssistantService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<String> ask({
    required String prompt,
    required String role,
    List<String> permissions = const [],
  }) async {
    if (!FirebaseInitializer.isInitialized) {
      return 'Connexion en ligne requise pour l\'assistant.';
    }
    if (!_canUseAi(role, permissions)) {
      return 'Accès non autorisé.';
    }
    try {
      final result = await _functions
          .httpsCallable('askGeminiAssistantCallable')
          .call({'prompt': prompt, 'role': role});
      final data = result.data;
      if (data is Map && data['answer'] is String) {
        return AiResponseFormatter.clean(data['answer'] as String);
      }
      return 'Réponse indisponible pour le moment.';
    } catch (e) {
      return AuthErrorSanitizer.sanitize(e);
    }
  }

  bool _canUseAi(String role, List<String> permissions) {
    if (role == 'admin_general_owner') return true;
    return permissions.contains(RolePermissionMatrix.canManageAiAssistant);
  }
}

class AiPermissionGuard {
  AiPermissionGuard._();
  static bool allow({required String role, required List<String> permissions}) {
    if (role == 'admin_general_owner') return true;
    return permissions.contains(RolePermissionMatrix.canManageAiAssistant);
  }
}

class AiPromptSanitizer {
  AiPromptSanitizer._();
  static String clean(String input) =>
      input.replaceAll(RegExp(r'(password|api[_-]?key|token)', caseSensitive: false), '[masqué]');
}

class AiResponseFormatter {
  AiResponseFormatter._();
  static String clean(String input) {
    return input
        .replaceAll(RegExp(r'FirebaseException|permission-denied|stacktrace', caseSensitive: false), '')
        .trim();
  }
}

typedef GeminiAssistantServiceAlias = GeminiAssistantService;
