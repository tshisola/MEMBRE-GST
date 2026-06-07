import 'package:flutter/material.dart';

import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../shared/components/pop_scope_back_guard.dart';
import '../../../shared/components/auth_ui_kit.dart';

/// Journal sécurité — admins autorisés uniquement (route guard).
class AdminAuditLogsScreen extends StatefulWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  State<AdminAuditLogsScreen> createState() => _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends State<AdminAuditLogsScreen> {
  List<Map<String, Object?>> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      AppConstants.tableAuditLogs,
      orderBy: 'created_at DESC',
      limit: 100,
    );
    if (mounted) {
      setState(() {
        _logs = rows;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScopeBackGuard(
      fallbackRoute: '/dashboard',
      child: Scaffold(
      backgroundColor: AppTheme.premiumBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        leading: const AppBackButton(fallbackRoute: '/dashboard'),
        title: const Text('Historique sécurité'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.goldAccent))
          : _logs.isEmpty
              ? Center(
                  child: Text(
                    'Aucun événement enregistré.',
                    style: authTextStyle(color: AppTheme.textMuted),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final log = _logs[i];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${log['action']}',
                            style: authTextStyle(weight: FontWeight.w600),
                          ),
                          Text(
                            '${log['created_at']}',
                            style: authTextStyle(color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    ),
    );
  }
}
