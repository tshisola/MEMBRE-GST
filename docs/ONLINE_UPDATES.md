# Mises à jour en ligne — MEDIA LUBUMBASHI

## Sans nouvel APK

L'application mobile installée peut recevoir en ligne :

- Données Firestore (membres, listes, pointage)
- Rôles et permissions
- Textes (`remote_texts`)
- Couleurs (`remote_theme`)
- Feature flags (`feature_flags`)
- Menus et dashboards (Server-Driven UI)
- Règles de présence (`remote_attendance_rules`)
- Templates PDF (`remote_pdf_templates`)

## Nécessite nouvel APK (Diagnostic Admin uniquement)

- Nouveau plugin natif
- Nouvel écran non prévu par le renderer dynamique
- Permission Android native
- Changement profond du code Dart non prévu

## Collections Firestore

| Collection | Usage |
|------------|--------|
| `app_config` | Paramètres généraux |
| `ui_config` | Interface |
| `feature_flags` | Modules on/off |
| `remote_texts` | Textes visibles |
| `remote_theme` | Couleurs |
| `remote_menus` | Menus dynamiques |
| `remote_dashboards` | Cartes dashboard |
| `app_versions` | Versions Android/Web/config |

## Admin Owner

1. **Mises à jour en ligne** (`/admin/sync/online-updates`)
2. **Synchroniser tout** — config + permissions + données
3. **Publier la configuration** — incrémente `config_version`

## CI/CD

Push sur `main` → GitHub Actions déploie Web + génère `version.json`.
