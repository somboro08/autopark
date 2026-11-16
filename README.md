# AutoPark — MVP de sécurisation des parkings motos (Bénin)

Application Flutter mobile à **deux profils** :

- **Propriétaire** : enregistre ses motos une seule fois dans son profil, obtient
  un **QR code + code numérique d'identité**, suit l'historique de toutes ses
  gardes et partage sa moto avec n'importe quel centre.
- **Agent de centre** : gère un ou plusieurs centres de garde, enregistre les
  dépôts, vérifie les identités à la sortie et suit les véhicules jour par jour.

> Design inspiré de WhatsApp (interface épurée, typographie système lisible),
> avec une palette **or/jaune + noir** en mode sombre et **or + blanc/gris** en
> mode clair. Icônes **Iconsax**. Base de données **SQLite** (migration
> PostgreSQL prévue).

---

## 🧠 Principe de sécurité : deux codes, deux rôles

| | Code d'identité (statique) | Jeton de garde (dynamique, à venir) |
|---|---|---|
| Représente | « cette moto est à moi » | « je viens la récupérer, maintenant » |
| Usage | s'enregistrer dans un centre, partager | libérer la moto |
| Forme | QR `AUTOPARK-XXXXX` + code à 6 chiffres | code rotatif, usage unique |
| Stockage | dans le profil du propriétaire | **Keystore Android / Keychain iOS** |

Conséquence : connaître le QR ou le code numérique **ne suffit pas** à récupérer
une moto. La vérification de récupération par jeton dynamique est prévue en
phase 5.

---

## ✨ Fonctionnalités du MVP

### 0. Profils et rôles
- Sélection du profil au démarrage (« Qui utilise l'application ? ») ou création
  d'un profil (propriétaire ou agent).
- Chaque profil garde ses propres données ; changement de profil en un geste
  depuis les **Paramètres**.
- Le dernier profil utilisé est mémorisé sur l'appareil.

### 0 bis. Espace propriétaire
- **Mes motos** : liste des motos du propriétaire, avec plaque, modèle, QR code
  d'identité et code numérique.
- Ajout d'une moto : QR + code générés automatiquement, **sans doublon** de
  plaque pour un même propriétaire.
- Fiche moto : grand **QR code**, code numérique copiable, partage avec un
  centre de garde en un tap.
- **Mon historique** : toutes les gardes, tous centres confondus, avec statut
  (En cours / Récupéré / Non récupéré), dates et heures.

### 1. Navigation principale (2 onglets) — espace agent
- **Retrouver un auto** — vérifier les informations d'un véhicule quand son
  propriétaire vient le récupérer.
- **Enregistrer un auto** — enregistrer un dépôt.

### 2. Vérification par QR / code numérique + plaque
- Scan du **QR code** (caméra via `mobile_scanner`) ou saisie d'un **code
  numérique**.
- Recherche du véhicule en base.
- **Véhicule déjà connu** : si le QR, le code ou la plaque correspond à une moto
  existante, l'agent ne crée **pas de doublon** — il rattache la moto au centre
  et ouvre une nouvelle garde.
- **Vérification de la plaque** : l'agent scanne / saisit la plaque physique et
  le système confirme (ou non) qu'elle correspond au dossier enregistré.

### 3. Centres de garde
- Un agent peut créer **plusieurs centres**.
- Pour chaque centre : nom, adresse et **délai de garde configurable**
  (par défaut 24 h, modifiable à la hausse ou à la baisse).
- Passé ce délai, un véhicule encore présent passe automatiquement en statut
  **« Non récupéré »**.

### 4. Liste journalière
- Onglets horizontaux pour **tous les jours de la semaine**.
- Liste verticale des dépôts du jour sélectionné avec statut :
  - 🟢 **En cours**
  - 🔵 **Récupéré** (avec date + heure de dépôt et de récupération)
  - 🔴 **Non récupéré** (délai de garde dépassé)
- Fiche véhicule détaillée + action **« Marquer comme récupéré »**.

### 5. Design & UX
- Thème **sombre (noir + or)** et **clair**, commutables depuis les
  **Paramètres** (bottom sheet animé).
- Animations de routage fluides (slide / fade).
- Bottom sheets animés (paramètres, scan de plaque).
- Typographie système agrandie et lisible (comme WhatsApp).
- Icônes **Iconsax** (`iconsax_flutter`).

### 6. Données de démonstration
Au premier lancement, un centre de démo + 4 véhicules + sessions (en cours,
récupéré, non récupéré) sont créés automatiquement pour explorer l'app.
Gestion depuis **Paramètres → Données** (recharger / effacer).

---

## 🧱 Stack technique

| Élément            | Choix                                  |
|--------------------|----------------------------------------|
| Framework          | Flutter 3.35 / Dart 3.9                |
| Base de données    | SQLite (`sqflite`) + `path_provider`   |
| Scan QR            | `mobile_scanner`                       |
| Icônes             | `iconsax_flutter`                      |
| Formats date/heure | `intl` (locale FR)                     |
| Thème              | Material 3 + palette personnalisée     |

---

## 📁 Structure du projet

```
lib/
├── main.dart                     # Point d'entrée + ThemeMode
├── database/
│   └── database_helper.dart      # CRUD SQLite v2 + seed démo
├── models/
│   ├── app_user.dart             # Profil + rôle (propriétaire / agent)
│   ├── parking_center.dart       # Centre de garde (délai)
│   ├── vehicle.dart              # Véhicule + identité (QR / code)
│   └── parking_session.dart      # Session de garde + statut effectif
├── state/
│   └── user_session.dart         # Profil actif (ValueNotifier)
├── screens/
│   ├── splash_screen.dart        # Splash + init + routage par rôle
│   ├── profile_picker_screen.dart    # « Qui utilise l'app ? »
│   ├── create_profile_screen.dart    # Création d'un profil
│   ├── owner_home_screen.dart        # Espace propriétaire (2 onglets)
│   ├── add_owner_vehicle_screen.dart # Ajout d'une moto au profil
│   ├── owner_vehicle_detail_screen.dart # QR, code, partage, historique
│   ├── home_screen.dart          # Espace agent (2 onglets)
│   ├── retrieve_vehicle_screen.dart  # Retrouver + vérif plaque
│   ├── register_vehicle_screen.dart  # Enregistrer un dépôt
│   ├── scan_qr_screen.dart       # Caméra QR
│   ├── enter_code_screen.dart    # Saisie code numérique
│   ├── vehicle_info_screen.dart  # Fiche + marquer récupéré
│   ├── centers_list_screen.dart  # Liste des centres
│   ├── add_center_screen.dart    # Création centre + délai
│   └── daily_list_screen.dart    # Onglets semaine + liste statuts
├── theme/
│   ├── app_colors.dart           # Palette or/noir/blanc
│   ├── app_theme.dart            # Thèmes clair + sombre
│   └── theme_controller.dart     # Bascule système/clair/sombre
├── utils/
│   └── route_animations.dart     # Transitions de pages
└── widgets/
    ├── custom_bottom_nav.dart    # Bottom nav agent (Iconsax)
    ├── owner_bottom_nav.dart     # Bottom nav propriétaire
    ├── day_tab.dart              # Onglet jour
    ├── status_badge.dart         # Badge statut
    ├── vehicle_card.dart         # Carte véhicule
    └── app_settings_sheet.dart   # Paramètres + profil + thème
```

---

## 🚀 Installation & lancement

### Prérequis
- Flutter SDK ≥ 3.35 ([guide](https://docs.flutter.dev/get-started/install))
- Android SDK (pour Android) ou Xcode (pour iOS)

### Étapes
```bash
# 1. Se placer dans le dossier
cd autopark

# 2. Récupérer les dépendances
flutter pub get

# 3. Accepter les licences Android (si nécessaire)
flutter doctor --android-licenses

# 4. Lancer sur un appareil / émulateur connecté
flutter run
```

### Build APK (Android)
```bash
flutter build apk --release
# APK généré dans build/app/outputs/flutter-apk/app-release.apk
```

### Tests
```bash
flutter test
```

---

## 🤖 Intégration continue — APK automatique

Le workflow [`.github/workflows/build-apk.yml`](.github/workflows/build-apk.yml)
compile un APK à chaque modification du code.

**Déclencheurs**
- `push` sur `main`
- `push` d'un tag `v*` (ex. `v1.0.0`)
- `pull_request` vers `main`
- lancement manuel (`workflow_dispatch`)

**Étapes du job**
1. Checkout du dépôt
2. Java 17 (Zulu)
3. Flutter `3.35.5` (stable, avec cache)
4. `flutter pub get`
5. `flutter analyze` (non bloquant)
6. `flutter test`
7. `flutter build apk --release`
8. Renommage en `autopark-<sha>.apk`
9. Upload de l'artefact **`autopark-apk`** (conservé 30 jours)
10. Si tag `v*` → création automatique d'une **GitHub Release** avec l'APK joint

**Récupérer l'APK**
1. Onglet **Actions** du dépôt → dernier run « Build APK »
2. Section **Artifacts** → télécharger `autopark-apk.zip`
3. Dézipper → `autopark-<sha>.apk` (installable directement sur Android)

**Publier une version**
```bash
git tag v1.0.0
git push origin v1.0.0
```
→ une Release GitHub est créée avec l'APK attaché.

> ℹ️ L'APK de release est signé avec la **clé de debug** Flutter (config par
> défaut du template). Il s'installe parfaitement pour tester, mais pour le
> Play Store il faudra configurer une **keystore de release** (non incluse ici
> pour des raisons de sécurité).

> ⚠️ Les runners GitHub Actions sont **gratuits et illimités sur un dépôt
> public**. Sur un dépôt privé, ils consomment des minutes et nécessitent un
> moyen de paiement / une limite de dépenses configurée dans
> **Settings → Billing & plans**.

---

## 🗄️ Schéma de la base SQLite (v2)

### `users`
| Colonne    | Type    | Description                              |
|------------|---------|------------------------------------------|
| id         | INTEGER | PK auto-increment                        |
| role       | TEXT    | `owner` ou `agent`                       |
| name       | TEXT    | Nom complet                              |
| phone      | TEXT    | Téléphone (optionnel)                    |
| created_at | TEXT    | ISO-8601                                 |

### `app_settings`
| Colonne | Type | Description                                    |
|---------|------|------------------------------------------------|
| key     | TEXT | PK (ex. `active_user_id`)                      |
| value   | TEXT | Valeur                                         |

### `parking_centers`
| Colonne          | Type    | Description                          |
|------------------|---------|--------------------------------------|
| id               | INTEGER | PK auto-increment                    |
| name             | TEXT    | Nom du centre                        |
| address          | TEXT    | Adresse                              |
| max_hours_delay  | INTEGER | Délai de garde en heures (défaut 24) |
| created_at       | TEXT    | ISO-8601                             |

### `vehicles`
| Colonne       | Type    | Description                              |
|---------------|---------|------------------------------------------|
| id            | INTEGER | PK                                       |
| plate         | TEXT    | Plaque d'immatriculation                 |
| owner_name    | TEXT    | Nom du propriétaire                      |
| owner_phone   | TEXT    | Téléphone (optionnel)                    |
| center_id     | INTEGER | FK → parking_centers (**nullable**)      |
| owner_id      | INTEGER | FK → users (profil propriétaire)         |
| model         | TEXT    | Modèle de la moto (optionnel)            |
| qr_code       | TEXT    | QR d'identité (statique)                 |
| numeric_code  | TEXT    | Code numérique d'identité (statique)     |
| photo_path    | TEXT    | Photo de contrôle (optionnel)            |
| created_at    | TEXT    | ISO-8601                                 |

### `center_vehicles`
Lien « ce centre connaît ce véhicule » (résultat d'un partage).

| Colonne       | Type    | Description                    |
|---------------|---------|--------------------------------|
| id            | INTEGER | PK                             |
| center_id     | INTEGER | FK → parking_centers           |
| vehicle_id    | INTEGER | FK → vehicles                  |
| registered_at | TEXT    | ISO-8601                       |

### `parking_sessions`
| Colonne          | Type    | Description                                |
|------------------|---------|--------------------------------------------|
| id               | INTEGER | PK                                         |
| vehicle_id       | INTEGER | FK → vehicles                              |
| center_id        | INTEGER | FK → parking_centers                       |
| entry_time       | TEXT    | Date/heure de dépôt                        |
| exit_time        | TEXT    | Date/heure de récupération (nullable)      |
| status           | INTEGER | 0=en cours, 1=récupéré, 2=non récupéré     |
| notes            | TEXT    | Notes libres                               |
| retrieval_token  | TEXT    | Jeton de garde (phase 5, réservé)          |

> Le statut **« Non récupéré »** est calculé dynamiquement à partir de
> `entry_time + max_hours_delay` (méthode `ParkingSession.effectiveStatus`).
>
> Migration : `onUpgrade` fait passer la base de v1 à v2 (table `users`,
> `center_vehicles`, `app_settings`, colonnes `owner_id` / `model`, et
> `center_id` rendu nullable par reconstruction de la table `vehicles`).

---

## 🧪 Profils / données de démo

**Profils créés au premier lancement**

| Profil | Rôle | Téléphone |
|---|---|---|
| Awa Dossou | Agent de centre | +229 97 00 00 01 |
| Jean Houngbo | Propriétaire (2 motos) | +229 97 00 11 22 |
| Aïcha Sossou | Propriétaire (1 moto) | +229 96 33 44 55 |

**Véhicules de démonstration**

| Plaque      | Propriétaire   | Code numérique | QR code          | État |
|-------------|----------------|----------------|------------------|------|
| AB-123-CD   | Jean Houngbo   | 1001           | AUTOPARK-1001    | En garde |
| EF-456-GH   | Aïcha Sossou   | 1002           | AUTOPARK-1002    | Récupéré |
| IJ-789-KL   | Marcel Dossou  | 1003           | AUTOPARK-1003    | Non récupéré |
| MN-012-OP   | Grâce Kponou   | 1004           | AUTOPARK-1004    | En garde |
| QR-456-TU   | Jean Houngbo   | 9001           | AUTOPARK-9001    | Pas encore partagé |

**Scénarios à tester**
1. **Propriétaire** → profil « Jean Houngbo » → *Mes motos* → ouvrir
   `QR-456-TU` → *Partager avec un centre* → la moto rejoint le centre.
2. **Agent** → profil « Awa Dossou » → *Enregistrer un auto* → scanner/saisir
   `1001` → l'agent ne crée pas de doublon, il relance une garde.
3. **Agent** → *Retrouver un auto* → code `1002` → plaque `EF-456-GH` →
   correspondance confirmée.

---

## 🗺️ Roadmap

### Fait
- [x] **Phase 1 — Rôles & profils** : propriétaire / agent, sélection de profil,
      véhicules possédés, deux codes distincts (identité statique vs garde).
- [x] **Phase 2 (partiel)** : partage d'une moto avec un centre, historique
      multi-centres, pas de doublon à l'enregistrement.

### À venir
- [ ] **Phase 2 (suite)** : annuaire des centres + « tu es déjà venu ici ».
- [ ] **Phase 3 — Carte** : centres géolocalisés, marqueurs, fiche détail
      (OpenStreetMap / `flutter_map`).
- [ ] **Phase 4 — Wallet & paiements** : solde prépayé, abonnements par centre
      (jour / semaine / mois), tickets de paiement payés par un tiers,
      encaissement par l'agent.
- [ ] **Phase 5 — Sécurité de récupération** : jeton dynamique rotatif stocké
      dans le Keystore, usage unique, journal d'audit.
- [ ] **Phase 6 — Backend** : PostgreSQL + API + synchronisation hors-ligne.
- [ ] **Reconnaissance automatique de plaque** (ALPR — Anyline / ML Kit)
- [ ] **Vérification biométrique 1:1 / 1:N** (VeriFinger / Innovatrics)
- [ ] Rapports de fréquentation et revenus
- [ ] Notifications push (véhicule non récupéré)

---

## 📌 Notes

- Ce MVP stocke les données **localement** sur l'appareil (SQLite). Aucune
  donnée n'est envoyée sur un serveur : le partage entre appareils nécessitera
  la phase 6 (backend).
- Le scan de plaque actuel est **manuel / simulé** ; l'intégration ALPR réelle
  est prévue dans la roadmap.
- Le wallet et les paiements ne sont **pas** encore implémentés ; ils le seront
  en mode simulé (phase 4) avant tout branchement d'un PSP agréé.
- La biométrie n'est **pas** incluse dans ce MVP.

---

© AutoPark — Projet de sécurisation des parkings motos au Bénin.
