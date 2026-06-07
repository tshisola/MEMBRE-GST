import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../../../core/auth/member_auth_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/security/privacy_guard.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../shared/components/pop_scope_back_guard.dart';
import '../../../shared/components/auth_ui_kit.dart';
import '../../../shared/components/screen_header.dart';
import '../../../shared/models/member_account_model.dart';

/// Liste des comptes membres (actifs / inactifs).
class MemberAccountsListScreen extends ConsumerStatefulWidget {
  const MemberAccountsListScreen({
    super.key,
    this.activeOnly,
  });

  final bool? activeOnly;

  @override
  ConsumerState<MemberAccountsListScreen> createState() =>
      _MemberAccountsListScreenState();
}

class _MemberAccountsListScreenState
    extends ConsumerState<MemberAccountsListScreen> {
  final _service = MemberAuthService();
  List<MemberAccount> _accounts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _accounts = await _service.listAccounts(activeOnly: widget.activeOnly);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.activeOnly == true
        ? 'Comptes actifs'
        : widget.activeOnly == false
            ? 'Comptes désactivés'
            : 'Comptes membres';

    return PopScopeBackGuard(
      fallbackRoute: '/dashboard',
      child: Scaffold(
      backgroundColor: AppTheme.premiumBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        leading: const AppBackButton(fallbackRoute: '/dashboard'),
        title: Text(title),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/member-accounts/create'),
        icon: const Icon(Icons.person_add),
        label: const Text('Créer compte'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.zero,
              children: [
                ScreenHeader(title: title, subtitle: AppConstants.appFullName),
                if (_accounts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Aucun compte')),
                  )
                else
                  ..._accounts.map((account) {
                    final safe = CreatorVisibilityGuard.sanitizeAccount(account);
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: safe.isActive
                              ? AppTheme.success.withValues(alpha: 0.2)
                              : AppTheme.danger.withValues(alpha: 0.2),
                          child: Icon(
                            safe.isActive ? Icons.check : Icons.block,
                            color: safe.isActive
                                ? AppTheme.success
                                : AppTheme.danger,
                          ),
                        ),
                        title: Text(safe.loginIdentifier),
                        subtitle: Text(
                          '${safe.memberId} · ${safe.isActive ? "Actif" : "Inactif"}',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) async {
                            final session =
                                await ref.read(localSessionProvider.future);
                            final actorId = session.userId ?? 'admin';
                            if (action == 'reset') {
                              final result = await _service.resetPassword(
                                accountId: account.id,
                                actorId: actorId,
                              );
                              if (!context.mounted) return;
                              await showDialog<void>(
                                context: context,
                                barrierDismissible: false,
                                builder: (ctx) => Dialog(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: TemporaryPasswordCard(
                                      identifier: account.loginIdentifier,
                                      temporaryPassword:
                                          result.temporaryPassword,
                                      onDone: () => Navigator.pop(ctx),
                                    ),
                                  ),
                                ),
                              );
                            } else if (action == 'toggle') {
                              await _service.setAccountActive(
                                accountId: account.id,
                                isActive: !account.isActive,
                                actorId: actorId,
                              );
                              _load();
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'reset',
                              child: Text('Réinitialiser mot de passe'),
                            ),
                            PopupMenuItem(
                              value: 'toggle',
                              child: Text(
                                account.isActive ? 'Désactiver' : 'Activer',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
    ),
    );
  }
}
