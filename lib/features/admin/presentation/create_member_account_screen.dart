import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/messaging/app_error_presenter.dart';
import '../../../app/constants.dart';
import '../../../core/auth/member_auth_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/components/auth_ui_kit.dart';
import '../../../shared/components/screen_header.dart';

/// Création d'un compte membre par l'Admin.
class CreateMemberAccountScreen extends ConsumerStatefulWidget {
  const CreateMemberAccountScreen({super.key});

  @override
  ConsumerState<CreateMemberAccountScreen> createState() =>
      _CreateMemberAccountScreenState();
}

class _CreateMemberAccountScreenState
    extends ConsumerState<CreateMemberAccountScreen> {
  final _service = MemberAuthService();
  final _memberNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _customIdController = TextEditingController();
  final _departmentController = TextEditingController(text: 'chorale');
  bool _loading = false;
  String? _generatedCode;
  String? _tempPassword;
  String? _loginId;

  @override
  void dispose() {
    _memberNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _customIdController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  void _generateIdentifier() {
    setState(() => _generatedCode = _service.generateMemberCode());
  }

  Future<void> _create() async {
    if (_memberNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nom du membre requis')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final session = await ref.read(localSessionProvider.future);
      final memberId = const Uuid().v4();
      final loginId = _customIdController.text.trim().isNotEmpty
          ? _customIdController.text.trim()
          : (_generatedCode ?? _service.generateMemberCode());

      final result = await _service.createAccount(
        memberId: memberId,
        memberName: _memberNameController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        departmentId: _departmentController.text.trim(),
        createdBy: session.userId ?? 'admin',
        customIdentifier: loginId,
      );

      setState(() {
        _loginId = result.account.loginIdentifier;
        _tempPassword = result.temporaryPassword;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppErrorPresenter.forSnackBar(e, source: 'create_member_account'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_tempPassword != null && _loginId != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Compte créé')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: TemporaryPasswordCard(
              identifier: _loginId!,
              temporaryPassword: _tempPassword!,
              onDone: () => context.go('/admin/member-accounts'),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Créer compte membre')),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const ScreenHeader(
            title: 'Nouveau compte membre',
            subtitle: AppConstants.appFullName,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _memberNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet du membre',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    labelText: 'E-mail (facultatif)',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _departmentController,
                  decoration: const InputDecoration(
                    labelText: 'Département',
                    prefixIcon: Icon(Icons.groups),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _customIdController,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    labelText: 'Identifiant personnalisé (facultatif)',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _generateIdentifier,
                  icon: const Icon(Icons.auto_fix_high),
                  label: Text(
                    _generatedCode ?? 'Générer identifiant IFCM-YYYY-XXXXXX',
                  ),
                ),
                const SizedBox(height: 24),
                ProfessionalActionButton(
                  label: 'Créer le compte',
                  icon: Icons.person_add,
                  isLoading: _loading,
                  onPressed: _create,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
