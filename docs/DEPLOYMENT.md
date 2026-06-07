# Déploiement — MEDIA LUBUMBASHI

## Web (Firebase Hosting)

### Manuel

```powershell
C:\flutter\bin\flutter build web --release
firebase deploy --only hosting --project membremedia
```

### Automatique (GitHub Actions)

Push sur `main` → workflow `.github/workflows/deploy_web.yml`

---

## Firestore Rules & Indexes

```powershell
firebase deploy --only firestore:rules --project membremedia
firebase deploy --only firestore:indexes --project membremedia
```

Workflow : `.github/workflows/deploy_firebase.yml`

---

## Cloud Functions

Prérequis : plan **Blaze**.

```powershell
cd functions
npm install
npm run build
cd ..
firebase deploy --only functions --project membremedia
```

---

## Configuration GitHub Secrets

Dans **Settings → Secrets and variables → Actions** :

| Secret | Description |
|--------|-------------|
| `FIREBASE_SERVICE_ACCOUNT` | JSON complet du compte de service Firebase |
| `FIREBASE_PROJECT_ID` | `membremedia` |

Créer le compte de service : Firebase Console → Project Settings → Service accounts → Generate new private key.

---

## Première mise sur GitHub

```powershell
git init
git add .
git commit -m "Initial production version MEDIA LUBUMBASHI"
git branch -M main
git remote add origin <URL_DU_REPO_GITHUB>
git push -u origin main
```

Créer aussi la branche develop :

```powershell
git checkout -b develop
git push -u origin develop
```

---

## Vérification post-déploiement

1. https://membremedia.web.app — Web accessible
2. Connexion Admin Owner
3. **Mises à jour en ligne** → version config visible
4. **Synchroniser tout** → message succès
5. GitHub Actions → workflows verts

---

## Notes APK

Sans nouvel APK, l'app mobile reçoit :

- Données Firestore, rôles, permissions
- Textes, couleurs, menus (Server-Driven UI)
- Feature flags, règles pointage, templates PDF

Nécessite nouvel APK :

- Nouveau plugin natif
- Écran non prévu par le renderer dynamique
- Permission Android native

(Voir Diagnostic Admin pour détails internes.)
