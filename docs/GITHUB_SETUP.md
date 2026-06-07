# Configuration GitHub — MEDIA LUBUMBASHI

## Dépôt

- **URL :** https://github.com/tshisola/MEMBRE-GST
- **Branche production :** `main` → déploie Web + Firebase
- **Branche développement :** `develop`

---

## Secrets Actions (obligatoires)

**Settings → Secrets and variables → Actions → New repository secret**

| Secret | Description |
|--------|-------------|
| `FIREBASE_PROJECT_ID` | `membremedia` |
| `FIREBASE_SERVICE_ACCOUNT` | Contenu JSON complet du compte de service Firebase |

### Créer le compte de service

1. [Firebase Console](https://console.firebase.google.com/project/membremedia/settings/serviceaccounts/adminsdk)
2. **Generate new private key**
3. Copier tout le JSON dans le secret `FIREBASE_SERVICE_ACCOUNT`
4. **Ne jamais** commiter ce fichier dans le repo

---

## Workflows

| Fichier | Déclencheur | Résultat |
|---------|-------------|----------|
| `deploy_web.yml` | Push `main` | `flutter build web` → Hosting |
| `deploy_firebase.yml` | Push `main` (rules/functions) | Rules, Indexes, Functions |

**Functions :** plan Firebase **Blaze** requis.

---

## Fichiers protégés (.gitignore)

- `.env`, `serviceAccountKey.json`, `google-services.json`
- `key.properties`, `*.jks`, `build/`, `node_modules/`, `.firebase/`

---

## Avant chaque push

```powershell
git status
# Vérifier qu'aucun secret n'est staged :
git diff --cached --name-only | Select-String -Pattern "\.env|serviceAccount|google-services\.json|key\.properties"
```

---

## Commandes push (après validation URL)

```powershell
git remote -v
git push origin main
git push origin develop
```
