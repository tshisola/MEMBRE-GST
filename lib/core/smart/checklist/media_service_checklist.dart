import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/smart_models.dart';

/// Checklist intelligente avant service Média.
class MediaServiceChecklist {
  MediaServiceChecklist();

  static const _storageKey = 'media_service_checklist_v1';

  static const defaultItems = [
    ('camera_centre', 'Caméra centre prête'),
    ('camera_baladeuse', 'Caméra baladeuse prête'),
    ('telephone_live', 'Téléphone live prêt'),
    ('batterie', 'Batterie chargée'),
    ('carte_memoire', 'Carte mémoire disponible'),
    ('trepied', 'Trépied disponible'),
    ('internet', 'Connexion Internet testée'),
    ('son', 'Son vérifié'),
    ('eclairage', 'Éclairage vérifié'),
    ('equipe_pointee', 'Équipe pointée'),
    ('responsables', 'Responsables présents'),
    ('liste_validee', 'Liste validée'),
    ('qr_scanner', 'QR scanner prêt'),
  ];

  Future<List<ServiceChecklistItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return _defaults();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return defaultItems
          .map(
            (e) => ServiceChecklistItem(
              id: e.$1,
              label: e.$2,
              done: map[e.$1] as bool? ?? false,
            ),
          )
          .toList();
    } catch (_) {
      return _defaults();
    }
  }

  Future<void> save(List<ServiceChecklistItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final map = {for (final i in items) i.id: i.done};
    await prefs.setString(_storageKey, jsonEncode(map));
  }

  Future<int> progressPercent() async {
    final items = await load();
    if (items.isEmpty) return 0;
    final done = items.where((i) => i.done).length;
    return ((done / items.length) * 100).round();
  }

  List<ServiceChecklistItem> _defaults() => defaultItems
      .map((e) => ServiceChecklistItem(id: e.$1, label: e.$2))
      .toList();
}

typedef ChecklistAutomationService = MediaServiceChecklist;
typedef ChecklistProgressCard = MediaServiceChecklist;
