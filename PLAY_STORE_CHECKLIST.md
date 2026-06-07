# Checklist Play Store - IFCM

## 1) Blocages techniques de publication

- [x] `minSdk` compatible large parc Android (`21+`)
- [x] Build release APK valide
- [ ] Signature release Play Store (keystore prod) configuree
- [ ] `applicationId` definitif (ne pas laisser `com.example...` pour la publication)
- [ ] Build AAB (`flutter build appbundle --release`) valide

## 2) Checklist visuelle (store-ready)

- [ ] Icone 512x512 (fond transparent propre, lisibilite en petit)
- [ ] Feature graphic 1024x500
- [ ] Screenshots smartphone (min 2, max 8) cohérents par flux
- [ ] Cohérence des titres FR (admin/membre/login/sync/resultats)
- [ ] Contraste texte/fond valide en mode sombre
- [ ] Etats vides/loading/erreur homogenes

## 3) Parcours screenshots recommandes

1. Ecran connexion
2. Tableau de bord membre
3. Resultat hebdomadaire membre
4. Pointage media (operateur)
5. Centre de controle admin
6. Synchronisation cloud
7. Securite comptes membres

## 4) Texte Play Store (FR)

- [ ] Titre court clair
- [ ] Description courte orientee valeur
- [ ] Description complete (roles, offline-first, securite)
- [ ] Politique de confidentialite (URL publique)
