# Sécurité — MEDIA LUBUMBASHI

## Signaler une vulnérabilité

Contactez le responsable principal (Admin Général Owner) en privé.  
Ne publiez pas de détails sensibles dans les issues GitHub publiques.

## Règles strictes

- **Ne jamais** commiter : mots de passe, tokens, clés API privées, comptes de service Firebase.
- **Ne jamais** stocker de mots de passe en clair dans Firestore ou SQLite.
- Utiliser **GitHub Secrets** pour CI/CD (`FIREBASE_SERVICE_ACCOUNT`, `FIREBASE_PROJECT_ID`).
- Les actions sensibles passent par **Cloud Functions** avec vérification du rôle.
- **Firestore Rules** limitent l'accès par rôle et permission.
- Seul **admin_general_owner** peut publier la configuration production depuis l'application.

## Fichiers protégés (.gitignore)

- `.env`, `serviceAccountKey.json`, `google-services.json`
- `build/`, `node_modules/`, clés Android (`*.jks`, `key.properties`)

## CI/CD

Les workflows GitHub Actions déploient Hosting, Rules et Functions sans exposer les secrets dans le code source.

## Comptes

Les comptes staff sont provisionnés via Firebase Auth + Firestore.  
Les mots de passe temporaires ne doivent jamais apparaître dans le dépôt Git.
