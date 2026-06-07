# Stratégie de branches — MEDIA LUBUMBASHI

## Branches principales

### `main`
- Production stable
- Déclenche déploiement Web + Firebase (GitHub Actions)
- Merge depuis `develop` ou `hotfix/*` après validation

### `develop`
- Intégration continue du développement
- Peut déclencher un déploiement preview (optionnel)

### `feature/*`
- Exemple : `feature/remote-theme-editor`
- Merge vers `develop`

### `hotfix/*`
- Exemple : `hotfix/web-login-fix`
- Merge vers `main` et `develop`

---

## Conventions de commit

```
feat: add web remote config
fix: web auth role sync
feat: admin sync all cloud settings
chore: deploy firebase hosting
docs: update deployment guide
```

---

## Protection recommandée (GitHub)

- `main` : require pull request, require status checks (CI)
- Interdire push direct avec secrets
- Activer secret scanning si disponible
