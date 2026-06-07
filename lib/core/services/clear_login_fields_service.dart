import 'package:flutter/material.dart';

/// Clears login form fields — never pre-fills credentials.
class ClearLoginFieldsService {
  ClearLoginFieldsService({
    required this.identifierController,
    required this.passwordController,
    this.confirmPasswordController,
  });

  final TextEditingController identifierController;
  final TextEditingController passwordController;
  final TextEditingController? confirmPasswordController;

  void clearAll() {
    identifierController.clear();
    passwordController.clear();
    confirmPasswordController?.clear();
  }

  void resetForNewVisit() {
    clearAll();
  }
}
