import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/appointments/appointment_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../shared/components/auth_ui_kit.dart';
import '../../../shared/components/pop_scope_back_guard.dart';

/// Rendez-vous — liste et création rapide.
class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  final _titleCtrl = TextEditingController();
  final _svc = AppointmentService();

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    final session = await ref.read(localSessionProvider.future);
    await _svc.createAppointment(
      title: title,
      scheduledAt: DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      createdBy: session.userId ?? 'admin',
    );
    _titleCtrl.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rendez-vous créé.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScopeBackGuard(
      fallbackRoute: '/dashboard',
      child: Scaffold(
        backgroundColor: AppTheme.premiumBlack,
        appBar: AppBar(
          leading: const AppBackButton(fallbackRoute: '/dashboard'),
          title: const Text('Rendez-vous'),
          backgroundColor: AppTheme.cardDark,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nouveau rendez-vous',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: AppTheme.brandOrange),
                    onPressed: _create,
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _svc.watchAppointments(),
                builder: (context, snap) {
                  final items = snap.data ?? [];
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        'Aucun rendez-vous.',
                        style: authTextStyle(color: AppTheme.textMuted),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final a = items[i];
                      return ListTile(
                        leading: const Icon(Icons.event, color: AppTheme.brandBlue),
                        title: Text(a['title']?.toString() ?? '', style: authTextStyle()),
                        subtitle: Text(
                          a['scheduledAt']?.toString() ?? '',
                          style: authTextStyle(color: AppTheme.textMuted),
                        ),
                        trailing: Chip(
                          label: Text(a['status']?.toString() ?? 'prévu'),
                        ),
                        onTap: () => context.push('/appointments/${a['id']}'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
