import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../../../core/members/member_deletion.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/permission_providers.dart';
import '../../../core/messaging/app_error_presenter.dart';
import '../../../core/services/department_list_export_service.dart';
import '../../../core/services/manual_department_list_service.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../shared/components/auth_ui_kit.dart';
import '../../../shared/components/pop_scope_back_guard.dart';
import '../../../shared/components/professional_list_viewer.dart';
import '../../../shared/components/screen_header.dart';
import '../../../shared/models/member_account_model.dart';

/// Listes manuelles par département (hors Média).
class DepartmentListsScreen extends ConsumerStatefulWidget {
  const DepartmentListsScreen({super.key});

  @override
  ConsumerState<DepartmentListsScreen> createState() =>
      _DepartmentListsScreenState();
}

class _DepartmentListsScreenState extends ConsumerState<DepartmentListsScreen> {
  final _service = ManualDepartmentListService();
  List<DepartmentManualList> _lists = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _lists = await _service.listAll();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _confirmDeleteList(DepartmentManualList list) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la liste ?'),
        content: Text(
          '« ${list.listTitle} » sera définitivement supprimée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final session = await ref.read(localSessionProvider.future);
    await _service.deleteList(list.id, session.userId ?? 'admin');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Liste supprimée')),
      );
      _load();
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
        title: const Text('Listes départements'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/departments/lists/create'),
        icon: const Icon(Icons.add),
        label: const Text('Créer liste'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.zero,
              children: [
                const ScreenHeader(
                  title: 'Listes manuelles',
                  subtitle: AppConstants.appFullName,
                ),
                if (_lists.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Aucune liste')),
                  )
                else
                  ..._lists.map(
                    (list) => ManualListCard(
                      departmentName: list.departmentName,
                      listTitle: list.listTitle,
                      memberCount: list.entries.length,
                      onTap: () => context.push(
                        '/departments/lists/${list.id}',
                        extra: list,
                      ),
                      onDelete: () => _confirmDeleteList(list),
                    ),
                  ),
              ],
            ),
    ),
    );
  }
}

class DepartmentListDetailScreen extends ConsumerStatefulWidget {
  const DepartmentListDetailScreen({
    super.key,
    required this.listId,
    this.initialList,
  });

  final String listId;
  final DepartmentManualList? initialList;

  @override
  ConsumerState<DepartmentListDetailScreen> createState() =>
      _DepartmentListDetailScreenState();
}

class _DepartmentListDetailScreenState
    extends ConsumerState<DepartmentListDetailScreen> {
  final _service = ManualDepartmentListService();
  DepartmentManualList? _list;

  @override
  void initState() {
    super.initState();
    _list = widget.initialList;
    _load();
  }

  Future<void> _load() async {
    final list = await _service.getById(widget.listId);
    if (mounted) setState(() => _list = list);
  }

  Future<void> _confirmDeleteList() async {
    final list = _list;
    if (list == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la liste ?'),
        content: Text('« ${list.listTitle} » sera définitivement supprimée.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final session = await ref.read(localSessionProvider.future);
    await _service.deleteList(list.id, session.userId ?? 'admin');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Liste supprimée')),
      );
      context.pop();
    }
  }

  Future<void> _removeMember(DepartmentManualListEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer ce membre ?'),
        content: Text('${entry.memberName} sera retiré de la liste.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final session = await ref.read(localSessionProvider.future);
    try {
      await _service.removeMember(
        listId: widget.listId,
        memberId: entry.memberId,
        actorId: session.userId ?? 'admin',
      );
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppErrorPresenter.forSnackBar(e, source: 'dept_list_remove'),
            ),
          ),
        );
      }
    }
  }

  Future<void> _addMember() async {
    final nameController = TextEditingController();
    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajouter membre'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nom complet'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    if (added != true || nameController.text.trim().isEmpty) return;

    final session = await ref.read(localSessionProvider.future);
    try {
      await _service.addMember(
        listId: widget.listId,
        entry: DepartmentManualListEntry(
          memberId: const Uuid().v4(),
          memberName: nameController.text.trim(),
        ),
        actorId: session.userId ?? 'admin',
      );
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppErrorPresenter.forSnackBar(e, source: 'dept_list_add'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _list;
    if (list == null) {
      return PopScopeBackGuard(
        fallbackRoute: '/departments/lists',
        child: Scaffold(
          backgroundColor: AppTheme.premiumBlack,
          appBar: AppBar(
            leading: const AppBackButton(fallbackRoute: '/departments/lists'),
            title: const Text('Liste département'),
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final sorted = [...list.entries]
      ..sort((a, b) => a.memberName.compareTo(b.memberName));
    final roleAsync = ref.watch(currentUserRoleProvider);
    const deletionChecker = MemberDeletionPermissionChecker();

    return PopScopeBackGuard(
      fallbackRoute: '/departments/lists',
      child: Scaffold(
      backgroundColor: AppTheme.premiumBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        leading: const AppBackButton(fallbackRoute: '/departments/lists'),
        title: Text(list.listTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Supprimer la liste',
            onPressed: _confirmDeleteList,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMember,
        backgroundColor: AppTheme.brandOrange,
        child: const Icon(Icons.person_add),
      ),
      body: ProfessionalListViewer<DepartmentManualListEntry>(
        title: list.listTitle,
        departmentName: list.departmentName,
        items: sorted,
        nameOf: (e) => e.memberName,
        subtitleOf: (e) => e.notes ?? '',
        searchHint: 'Rechercher un membre…',
        onPdf: () => DepartmentListPdfExportService().exportAndShare(list),
        onCsv: () => DepartmentListCsvExportService().exportAndShare(list),
        canDeleteItem: (e) =>
            e.memberId.isNotEmpty &&
            deletionChecker.canDelete(roleAsync.valueOrNull),
        onDeleteItem: (e) => context.push('/members/${e.memberId}/delete'),
        onSecondaryItem: _removeMember,
        onItemTap: (e) {
          if (e.memberId.isNotEmpty) {
            context.push('/members/${e.memberId}');
          }
        },
        emptyTitle: 'Liste vide',
        emptyMessage: 'Ajoutez des membres à cette liste.',
      ),
    ),
    );
  }
}

class CreateDepartmentListScreen extends ConsumerStatefulWidget {
  const CreateDepartmentListScreen({super.key});

  @override
  ConsumerState<CreateDepartmentListScreen> createState() =>
      _CreateDepartmentListScreenState();
}

class _CreateDepartmentListScreenState
    extends ConsumerState<CreateDepartmentListScreen> {
  final _deptController = TextEditingController();
  final _deptNameController = TextEditingController();
  final _titleController = TextEditingController();
  final _service = ManualDepartmentListService();
  bool _loading = false;

  @override
  void dispose() {
    _deptController.dispose();
    _deptNameController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_deptNameController.text.trim().isEmpty ||
        _titleController.text.trim().isEmpty) {
      return;
    }
    setState(() => _loading = true);
    try {
      final session = await ref.read(localSessionProvider.future);
      final list = await _service.createList(
        departmentId: _deptController.text.trim().isEmpty
            ? _deptNameController.text.trim().toLowerCase()
            : _deptController.text.trim(),
        departmentName: _deptNameController.text.trim(),
        listTitle: _titleController.text.trim(),
        entries: const [],
        createdBy: session.userId ?? 'admin',
      );
      if (mounted) context.go('/departments/lists/${list.id}', extra: list);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScopeBackGuard(
      fallbackRoute: '/departments/lists',
      child: Scaffold(
      backgroundColor: AppTheme.premiumBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        leading: const AppBackButton(fallbackRoute: '/departments/lists'),
        title: const Text('Créer liste manuelle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _deptNameController,
              decoration: const InputDecoration(
                labelText: 'Nom du département',
                hintText: 'Ex: SON, CHORALE',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Nom de la liste',
                hintText: 'Ex: TECHNICIENS SON',
              ),
            ),
            const SizedBox(height: 24),
            ProfessionalActionButton(
              label: 'Créer la liste',
              icon: Icons.check,
              isLoading: _loading,
              onPressed: _create,
            ),
          ],
        ),
      ),
    ),
    );
  }
}
