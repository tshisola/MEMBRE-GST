import 'package:flutter/material.dart';

import '../services/clear_login_fields_service.dart';

/// Manages secure login form state — fields always start empty.
class AuthFormController extends ChangeNotifier {
  AuthFormController() {
    _clearService = ClearLoginFieldsService(
      identifierController: identifierController,
      passwordController: passwordController,
    );
    reset();
  }

  final identifierController = TextEditingController();
  final passwordController = TextEditingController();
  late final ClearLoginFieldsService _clearService;

  bool obscurePassword = true;
  bool rememberMe = false;
  bool isLoading = false;
  String? errorMessage;

  void reset() {
    _clearService.clearAll();
    obscurePassword = true;
    rememberMe = false;
    isLoading = false;
    errorMessage = null;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void clearFields() {
    _clearService.clearAll();
    notifyListeners();
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void setError(String? message) {
    errorMessage = message;
    notifyListeners();
  }

  void setRememberMe(bool value) {
    rememberMe = value;
    notifyListeners();
  }

  Future<bool> confirmRememberMe(BuildContext context) async {
    if (!rememberMe) return false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mémoriser la session ?'),
        content: const Text(
          'Seul l\'identifiant de session sera conservé, jamais le mot de passe. '
          'Pour votre sécurité, tapez vos identifiants manuellement à chaque connexion.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Non'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Oui, mémoriser'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  void dispose() {
    identifierController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
