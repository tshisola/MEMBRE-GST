import 'package:flutter/material.dart';

import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../../../core/firebase/firebase_initializer.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../shared/components/pop_scope_back_guard.dart';
import '../../../shared/components/app_drawer.dart';
import '../../../shared/components/media_components.dart';
import '../../../shared/components/premium_states.dart';
import '../../../shared/components/premium_ui_kit.dart';
import '../../../shared/components/screen_header.dart';
import '../../../shared/models/member_model.dart';
import '../../../shared/models/role_models.dart';

class MediaRolesScreen extends StatefulWidget {
  const MediaRolesScreen({super.key});

  @override
  State<MediaRolesScreen> createState() => _MediaRolesScreenState();
}

class _MediaRolesScreenState extends State<MediaRolesScreen> {
  bool _isLoading = false;

  static final List<({Member member, MediaRole? role})> _assignments = [
    (
      member: const Member(
        id: '1',
        name: 'Jean Mukendi',
        phone: '+243 990 000 001',
        departmentId: Member.mediaDepartmentId,
        role: 'media_lead',
      ),
      role: MediaRole.chefMedia,
    ),
    (
      member: const Member(
        id: '2',
        name: 'Marie Kabongo',
        phone: '+243 990 000 002',
        departmentId: Member.mediaDepartmentId,
        role: 'camera',
      ),
      role: MediaRole.camera,
    ),
    (
      member: const Member(
        id: '3',
        name: 'Paul Tshilombo',
        phone: '+243 990 000 003',
        departmentId: Member.mediaDepartmentId,
        role: 'son',
      ),
      role: MediaRole.son,
    ),
    (
      member: const Member(
        id: '4',
        name: 'Grace Mwamba',
        phone: '+243 990 000 004',
        departmentId: Member.mediaDepartmentId,
        role: 'assistant',
      ),
      role: null,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _assignRole(Member member, MediaRole? currentRole) async {
    final selected = await showModalBottomSheet<MediaRole>(
      context: context,
      backgroundColor: AppTheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Assigner un rôle à ${member.name}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ...MediaRole.values.map(
              (role) => ListTile(
                leading: RoleBadge(role: role, compact: true),
                title: Text(role.label),
                trailing: currentRole == role
                    ? const Icon(Icons.check, color: AppTheme.goldAccent)
                    : null,
                onTap: () => Navigator.pop(context, role),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (selected != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rôle ${selected.label} assigné à ${member.name}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = FirebaseInitializer.isInitialized;

    return PopScopeBackGuard(
      fallbackRoute: '/media',
      child: Scaffold(
      backgroundColor: AppTheme.premiumBlack,
      drawer: const AppDrawer(currentRoute: '/media/roles'),
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        leading: const AppBackButton(fallbackRoute: '/media'),
        title: const Text('Rôles Média'),
      ),
      body: Column(
        children: [
          ScreenHeader(
            title: 'Gestion des rôles',
            subtitle: 'Département Média · ${AppConstants.city}',
            showFirebaseIndicator: true,
            isFirebaseConnected: isConnected,
          ),
          Expanded(
            child: _isLoading
                ? const LoadingState()
                : _assignments.isEmpty
                    ? const EmptyState(
                        title: 'Aucun membre média',
                        message: 'Ajoutez des membres au département média.',
                        icon: Icons.badge_outlined,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _assignments.length,
                        itemBuilder: (context, index) {
                          final item = _assignments[index];
                          return MediaMemberTile(
                            member: item.member,
                            trailing: item.role != null
                                ? RoleBadge(role: item.role!)
                                : const Text(
                                    'Non assigné',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                            onTap: () => _assignRole(item.member, item.role),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppTheme.goldAccent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Ajouter membre'),
      ),
    ),
    );
  }
}
