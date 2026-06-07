import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../../../core/firebase/firebase_initializer.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/storage/local_session.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../features/admin_realtime/presentation/members_live_provider.dart';
import '../../../features/media_attendance/presentation/media_attendance_members_provider.dart';
import '../../../core/advanced/automation/advanced_automation_center.dart';
import '../../../core/smart/automation/smart_automation_center.dart';
import '../../../core/messaging/app_error_presenter.dart';
import '../../../features/members/domain/create_member_use_case.dart';
import '../../../shared/components/app_drawer.dart';
import '../../../shared/components/member_sync_ui_kit.dart';
import '../../../shared/components/premium_ui_kit.dart';
import '../../../shared/components/pop_scope_back_guard.dart';
import '../../../shared/components/screen_header.dart';

class CreateMemberScreen extends ConsumerStatefulWidget {
  const CreateMemberScreen({super.key});

  @override
  ConsumerState<CreateMemberScreen> createState() => _CreateMemberScreenState();
}

class _CreateMemberScreenState extends ConsumerState<CreateMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _commune = TextEditingController(text: 'Lubumbashi');
  String? _departmentId = AppConstants.mediaDepartmentId;
  bool _loading = false;

  static const _departments = [
    ('media', 'Média'),
    ('louange', 'Louange'),
    ('intercession', 'Intercession'),
    ('evangelisation', 'Évangélisation'),
    ('accueil', 'Accueil'),
    ('technique', 'Technique'),
  ];

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _commune.dispose();
    super.dispose();
  }

  Future<void> _submit({bool forceDuplicate = false}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final session = await ref.read(localSessionProvider.future);
      final dept = _departments.firstWhere(
        (d) => d.$1 == _departmentId,
        orElse: () => (_departmentId ?? 'general', _departmentId ?? 'Général'),
      );

      final useCase = ref.read(createMemberUseCaseProvider);
      final result = await useCase.execute(
        CreateMemberInput(
          firstName: _firstName.text,
          lastName: _lastName.text,
          phone: _phone.text,
          email: _email.text,
          address: _address.text,
          commune: _commune.text,
          departmentId: dept.$1,
          departmentName: dept.$2,
          createdBy: session.userId,
          createdByRole: session.role,
          forceDuplicate: forceDuplicate,
        ),
      );

      bumpMembersRevision(ref, banner: 'Membre créé avec succès.');
      bumpMediaPointageMembers(ref);
      unawaited(SmartAutomationCenter.instance.onMemberCreated());
      unawaited(AdvancedAutomationCenter.instance.onMemberCreated(
        result.member.displayName,
        memberId: result.member.id,
      ));

      if (!mounted) return;
      await showDialog<bool>(
        context: context,
        builder: (_) => MemberCreatedSuccessDialog(
          memberName: result.member.displayName,
          memberCode: result.member.memberCode,
          syncStatus: result.syncStatus,
        ),
      );
      if (mounted) context.go('/members/${result.member.id}');
    } on DuplicateMemberException catch (e) {
      if (!mounted) return;
      final isAdminGeneral =
          (await ref.read(localSessionProvider.future)).role ==
              AppConstants.roleAdminGeneral;
      await showDialog(
        context: context,
        builder: (_) => DuplicateWarningDialog(
          reason: '${e.result.reason ?? 'Doublon détecté.'}'
              '${e.result.source == 'firebase' ? ' (Firebase)' : ''}',
          showContinue: isAdminGeneral,
          onViewExisting: () {
            Navigator.pop(context);
            if (e.result.existingMember != null) {
              context.push('/members/${e.result.existingMember!.id}');
            }
          },
          onContinue: isAdminGeneral
              ? () {
                  Navigator.pop(context);
                  _submit(forceDuplicate: true);
                }
              : null,
        ),
      );
    } catch (e, st) {
      AppErrorPresenter.recordOnly(e, source: 'create_member', stack: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppErrorPresenter.forSnackBar(e, source: 'create_member'),
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
    final isOnline = FirebaseInitializer.isInitialized;

    return PopScopeBackGuard(
      fallbackRoute: '/members',
      child: Scaffold(
      drawer: const AppDrawer(currentRoute: '/members/create'),
      appBar: AppBar(
        leading: const AppBackButton(fallbackRoute: '/members'),
        title: const Text('Nouveau membre'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FirebaseConnectionIndicator(
              isConnected: isOnline,
              compact: true,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          ScreenHeader(
            title: 'Enregistrer un membre',
            subtitle: isOnline
                ? 'SQLite + Firebase · sync automatique active'
                : 'Mode hors ligne · sync dès retour réseau',
            showFirebaseIndicator: true,
            isFirebaseConnected: isOnline,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              color: AppTheme.surfaceElevated,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      isOnline ? Icons.cloud_sync : Icons.cloud_off,
                      color: isOnline ? AppTheme.success : const Color(0xFFFFB74D),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isOnline
                            ? 'Le membre sera visible par tous les Admins en temps réel.'
                            : 'Enregistrement local immédiat. Firebase synchronisera automatiquement.',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SyncStatusBadge(
                      status: AppConstants.syncStatusPending,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _field(_firstName, 'Prénom', required: true),
                  const SizedBox(height: 12),
                  _field(_lastName, 'Nom', required: true),
                  const SizedBox(height: 12),
                  _field(_phone, 'Téléphone', keyboard: TextInputType.phone),
                  const SizedBox(height: 12),
                  _field(_email, 'Email', keyboard: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  _field(_address, 'Adresse'),
                  const SizedBox(height: 12),
                  _field(_commune, 'Commune'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _departmentId,
                    decoration: const InputDecoration(
                      labelText: 'Département',
                      border: OutlineInputBorder(),
                    ),
                    items: _departments
                        .map(
                          (d) => DropdownMenuItem(value: d.$1, child: Text(d.$2)),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _departmentId = v),
                  ),
                  const SizedBox(height: 24),
                  AdvancedButton(
                    label: 'Créer le membre',
                    icon: Icons.person_add,
                    isLoading: _loading,
                    onPressed: _loading ? null : () => _submit(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    bool required = false,
    TextInputType? keyboard,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: required
          ? (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null
          : null,
    );
  }
}
