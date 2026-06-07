# IFCM — Configuration Supabase

## Sécurité

- **Ne jamais** committer `SUPABASE_ACCESS_TOKEN`, `service_role`, ni `.env` avec secrets.
- Flutter utilise **uniquement** `SUPABASE_URL` + `SUPABASE_ANON_KEY` (dart-define).
- Si un token a été exposé, **régénérez-le** dans le dashboard Supabase.

## CLI (Windows PowerShell)

```powershell
# Installer (si absent): scoop install supabase OU npm i -g supabase
supabase --version

cd "d:\MEMBRE GST"
supabase init   # déjà fait si dossier supabase/ existe

$env:SUPABASE_ACCESS_TOKEN="votre_token_ici"
supabase login --token $env:SUPABASE_ACCESS_TOKEN

# Remplacer par votre PROJECT_REF (Settings → General)
supabase link --project-ref VOTRE_PROJECT_REF

supabase db push
```

## Flutter

```powershell
flutter run --dart-define=SUPABASE_URL=https://XXXX.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## Rôles attendus (Auth + profiles)

| Personne | Rôle |
|----------|------|
| Verdick | admin_general |
| Jean Ilunga | pasteur_membership |
| Mechack, Jeno, Bisibo | attendance_operator |

Créer les utilisateurs dans **Supabase Auth** (Dashboard), puis mettre à jour `profiles.role`.

## Realtime

Activer dans le dashboard : `weekly_percentages`, `messages`, `attendance_records`, `conversations`.
