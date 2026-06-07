import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants.dart';
import '../../../app/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/background_sync_providers.dart';
import '../../../core/remote/firestore_config_service.dart';
import '../../../core/remote/models/remote_config_models.dart';
import '../../../core/remote/remote_update_applier.dart';
import '../../../core/remote/sync_all_cloud_config_service.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../shared/components/premium_ui_kit.dart';
import '../../../shared/components/screen_header.dart';
import 'widgets/online_update_ui_kit.dart';

/// Centre Admin — Mises à jour en ligne (config, thème, sync).
class OnlineUpdateCenterScreen extends ConsumerStatefulWidget {
  const OnlineUpdateCenterScreen({super.key});

  @override
  ConsumerState<OnlineUpdateCenterScreen> createState() =>
      _OnlineUpdateCenterScreenState();
}

class _OnlineUpdateCenterScreenState extends ConsumerState<OnlineUpdateCenterScreen> {
  bool _loading = false;
  bool _syncing = false;
  String? _configVersion;
  String? _webVersion;
  String? _lastSync;
  RemoteThemeConfig _theme = const RemoteThemeConfig();
  Map<String, bool> _flags = {};
  Map<String, String> _texts = {};

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final applier = RemoteUpdateApplier();
      await applier.applyAll();
      final versions = await FirestoreConfigService().loadAppVersions();
      final appConfig = await FirestoreConfigService().loadAppConfig();

      String? pkgVersion = '1.0.0';

      if (mounted) {
        setState(() {
          _configVersion = versions.configVersion ?? appConfig.configVersion;
          _webVersion = versions.webLatestVersion ?? pkgVersion;
          _lastSync = appConfig.updatedAt;
          _theme = applier.theme.current;
          _flags = Map.from(applier.flags.flags);
          _texts = Map.from(applier.texts.all);
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _syncAll() async {
    final session = await ref.read(localSessionProvider.future);
    setState(() => _syncing = true);
    try {
      final result = await SyncAllCloudConfigService().syncAll(role: session.role);
      if (!result.success) {
        if (mounted) {
          await SyncAllResultDialog.show(
            context,
            message: result.message ?? 'Veuillez réessayer.',
            success: false,
          );
        }
        return;
      }

      await ref.read(autoSyncManagerProvider).runBackgroundSync(
            trigger: 'sync_all_cloud',
            forcePull: true,
          );
      await ref.read(syncManagerProvider).flushQueue();

      if (mounted) {
        await SyncAllResultDialog.show(
          context,
          message: result.message ?? 'Synchronisation terminée avec succès.',
          success: true,
        );
        await _refresh();
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _publishConfig() async {
    final session = await ref.read(localSessionProvider.future);
    if (session.role != AppConstants.roleAdminGeneralOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action réservée au responsable principal.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final now = DateTime.now().toIso8601String();
      final config = FirestoreConfigService();
      await config.writeDoc(AppConstants.collectionAppConfig, {
        'configVersion': now,
        'publishedBy': session.userId,
        'city': AppConstants.city,
      });
      await config.writeDoc(AppConstants.collectionAppVersions, {
        'config_version': now,
        'web_latest_version': _webVersion,
        'updatedAt': now,
      }, docId: 'latest');

      if (mounted) {
        await PublishSuccessDialog.show(context);
        await _refresh();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFlag(String key, bool value) async {
    setState(() => _flags[key] = value);
    await FirestoreConfigService().writeDoc(
      AppConstants.collectionFeatureFlags,
      {key: value},
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(localSessionProvider);
    final isOwner =
        sessionAsync.valueOrNull?.role == AppConstants.roleAdminGeneralOwner;

    return Scaffold(
      backgroundColor: AppTheme.premiumBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        leading: const AppBackButton(fallbackRoute: '/admin/sync'),
        title: const Text('Mises à jour en ligne'),
      ),
      body: _loading && _configVersion == null
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brandOrange))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ScreenHeader(
                  title: 'Configuration cloud',
                  subtitle: AppConstants.appName,
                  showFirebaseIndicator: true,
                  isFirebaseConnected: true,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_configVersion != null)
                      ConfigVersionBadge(label: 'Config v$_configVersion'),
                    if (_webVersion != null)
                      ConfigVersionBadge(
                        label: 'Web v$_webVersion',
                        color: AppTheme.brandBlue,
                      ),
                  ],
                ),
                if (_lastSync != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Dernière mise à jour : $_lastSync',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 20),
                if (isOwner) ...[
                  SyncAllButton(onPressed: _syncing ? null : _syncAll, isLoading: _syncing),
                  const SizedBox(height: 12),
                  PublishConfigButton(
                    onPressed: _loading ? null : _publishConfig,
                    isLoading: _loading,
                  ),
                  const SizedBox(height: 24),
                ],
                const SectionHeader(
                  title: 'Modules',
                  subtitle: 'Activation en ligne',
                ),
                FeatureFlagToggle(
                  label: 'Synchronisation automatique',
                  value: _flags['sync_enabled'] ?? true,
                  onChanged: (v) => _toggleFlag('sync_enabled', v),
                  enabled: isOwner,
                ),
                FeatureFlagToggle(
                  label: 'Export PDF',
                  value: _flags['export_pdf_enabled'] ?? true,
                  onChanged: (v) => _toggleFlag('export_pdf_enabled', v),
                  enabled: isOwner,
                ),
                FeatureFlagToggle(
                  label: 'Pointage Média',
                  value: _flags['attendance_enabled'] ?? true,
                  onChanged: (v) => _toggleFlag('attendance_enabled', v),
                  enabled: isOwner,
                ),
                const SizedBox(height: 20),
                const SectionHeader(title: 'Thème', subtitle: 'Couleurs MEDIA LUBUMBASHI'),
                RemoteThemePreview(
                  primary: _theme.primary,
                  background: _theme.background,
                  card: _theme.card,
                ),
                const SizedBox(height: 20),
                OnlineUpdateCard(
                  title: 'Textes distants',
                  subtitle: '${_texts.length} texte(s) configuré(s)',
                  icon: Icons.text_fields,
                  onTap: () => context.push('/admin/online-updates/texts'),
                ),
                OnlineUpdateCard(
                  title: 'Menus dynamiques',
                  subtitle: 'Ordre et visibilité des menus',
                  icon: Icons.menu,
                  onTap: () => context.push('/admin/online-updates/menus'),
                ),
                OnlineUpdateCard(
                  title: 'Règles de présence',
                  subtitle: 'Seuils et paramètres pointage',
                  icon: Icons.fact_check_outlined,
                  accentColor: AppTheme.brandBlue,
                  onTap: () => context.push('/admin/online-updates/attendance-rules'),
                ),
                OnlineUpdateCard(
                  title: 'Accès Web comptes',
                  subtitle: 'Migration comptes mobile → Web',
                  icon: Icons.language,
                  onTap: () => context.push('/admin/sync/web-migration'),
                ),
                OnlineUpdateCard(
                  title: 'Synchronisation données',
                  subtitle: 'Membres, listes, comptes',
                  icon: Icons.sync,
                  onTap: () => context.push('/admin/sync'),
                ),
              ],
            ),
    );
  }
}

/// Éditeur textes distants — lecture seule si non owner.
class RemoteTextEditorScreen extends ConsumerStatefulWidget {
  const RemoteTextEditorScreen({super.key});

  @override
  ConsumerState<RemoteTextEditorScreen> createState() => _RemoteTextEditorScreenState();
}

class _RemoteTextEditorScreenState extends ConsumerState<RemoteTextEditorScreen> {
  final _keyCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  Map<String, String> _texts = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final texts = await FirestoreConfigService().loadTexts();
    if (mounted) setState(() => _texts = texts);
  }

  Future<void> _save() async {
    final key = _keyCtrl.text.trim();
    final value = _valueCtrl.text.trim();
    if (key.isEmpty) return;
    await FirestoreConfigService().writeDoc(
      AppConstants.collectionRemoteTexts,
      {key: value},
    );
    _keyCtrl.clear();
    _valueCtrl.clear();
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Texte enregistré.')),
      );
    }
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.premiumBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        leading: const AppBackButton(fallbackRoute: '/admin/online-updates'),
        title: const Text('Textes distants'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _keyCtrl,
            decoration: const InputDecoration(labelText: 'Clé'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _valueCtrl,
            decoration: const InputDecoration(labelText: 'Texte visible'),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(backgroundColor: AppTheme.brandOrange),
            child: const Text('Enregistrer'),
          ),
          const SizedBox(height: 20),
          ..._texts.entries.map(
            (e) => ListTile(
              title: Text(e.key, style: const TextStyle(fontSize: 13)),
              subtitle: Text(e.value),
              tileColor: AppTheme.cardDark,
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder éditeurs menus / règles — extensible.
class RemoteMenuEditorScreen extends StatelessWidget {
  const RemoteMenuEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.premiumBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        leading: const AppBackButton(fallbackRoute: '/admin/online-updates'),
        title: const Text('Menus dynamiques'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Configurez remote_menus dans Firestore ou via Synchroniser tout.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ),
      ),
    );
  }
}

class RemoteRulesEditorScreen extends StatelessWidget {
  const RemoteRulesEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.premiumBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        leading: const AppBackButton(fallbackRoute: '/admin/online-updates'),
        title: const Text('Règles de présence'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Configurez remote_attendance_rules (seuils, éligibilité) en ligne.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ),
      ),
    );
  }
}

/// Alias écran sync admin.
typedef AdminSyncAllScreen = OnlineUpdateCenterScreen;
