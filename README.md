# MEDIA LUBUMBASHI

Application de gestion des membres, pointage, listes et administration pour **Impact For Christ Ministries — Lubumbashi**.

| Plateforme | Technologie |
|------------|-------------|
| Mobile | Flutter (Android) — offline-first SQLite + Firebase |
| Web | Flutter Web — Firebase Hosting |
| Backend | Firebase Auth, Firestore, Cloud Functions, Remote Config |
| CI/CD | GitHub Actions |

**Web production :** https://membremedia.web.app  
**Projet Firebase :** `membremedia`

---

## Fonctionnalités

- Gestion des membres IFCM (création, sync temps réel, QR)
- Pointage Média (présence, pourcentages hebdomadaires)
- Listes départements / Média (PDF, CSV)
- Comptes staff (Admin Général, opérateurs pointage)
- Messagerie, rendez-vous, assistant IA (Gemini)
- **Mises à jour en ligne** : Remote Config + Firestore config + Server-Driven UI
- Synchronisation cloud sans régénérer l'APK (données, rôles, permissions, textes, couleurs)

---

## Prérequis

- Flutter stable (SDK ^3.11)
- Node.js 20+ (Cloud Functions)
- Firebase CLI (`npm i -g firebase-tools`)
- Compte Firebase projet `membremedia`

---

## Installation locale

```powershell
cd "d:\MEMBRE GST\MEMBRE GST"
C:\flutter\bin\flutter pub get
copy .env.example .env
# Remplir .env localement — ne jamais commiter
```

---

## Build

### Web

```powershell
C:\flutter\bin\flutter clean
C:\flutter\bin\flutter pub get
C:\flutter\bin\flutter analyze
C:\flutter\bin\flutter build web --release
firebase deploy --only hosting
```

### Android (production manuelle)

```powershell
C:\flutter\bin\flutter build apk --release
```

> Les mises à jour **données / config / rules / functions / web** ne nécessitent pas de nouvel APK.

### Firebase Rules & Functions

```powershell
cd functions
npm install
npm run build
cd ..
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
firebase deploy --only functions
```

> Cloud Functions requiert le plan Firebase **Blaze**.

---

## Stratégie de branches

| Branche | Usage |
|---------|--------|
| `main` | Production stable — déploie Web + Firebase |
| `develop` | Développement — preview optionnel |
| `feature/*` | Nouvelles fonctionnalités |
| `hotfix/*` | Corrections urgentes |

Voir [docs/BRANCHING.md](docs/BRANCHING.md).

---

## CI/CD (GitHub Actions)

| Workflow | Déclencheur | Action |
|----------|-------------|--------|
| `deploy_web.yml` | Push `main` | Build Web + Firebase Hosting |
| `deploy_firebase.yml` | Push `main` ou manuel | Rules, Indexes, Functions |

**Secrets GitHub requis :**

- `FIREBASE_SERVICE_ACCOUNT` — JSON compte de service (jamais dans le repo)
- `FIREBASE_PROJECT_ID` — `membremedia`

Voir [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md).

---

## Mises à jour en ligne (sans APK)

Collections Firestore de configuration :

- `app_config`, `ui_config`, `feature_flags`
- `remote_texts`, `remote_theme`, `remote_menus`, `remote_dashboards`
- `remote_permissions`, `remote_attendance_rules`, `remote_pdf_templates`
- `remote_screens`, `remote_components`, `remote_layouts`
- `app_versions`

Services Flutter : `RemoteConfigService`, `FirestoreConfigService`, `DynamicThemeService`, `RemoteUpdateApplier`.

**Admin Général Owner** : bouton **« Synchroniser tout »** dans Synchronisation / Mises à jour en ligne.

---

## Sécurité

- Aucun secret dans GitHub
- `.gitignore` protège clés, `.env`, service accounts
- Messages techniques uniquement dans Diagnostic Admin
- Voir [SECURITY.md](SECURITY.md)

---

## Structure

```
lib/
  core/remote/          # Config distante, SDUI, sync cloud
  core/sync/            # Synchronisation Firebase
  core/web/             # Auth & layout Web
  features/             # Écrans métier
functions/              # Cloud Functions
.github/workflows/      # CI/CD
firestore.rules
firebase.json
```

---

## Licence

MIT — voir [LICENSE](LICENSE).
