# AutoPark — MVP de sécurisation des parkings motos (Bénin)

Application Flutter mobile permettant à un gardien / gestionnaire de centre de
garde de motos d'enregistrer les véhicules, de vérifier les identités à la
sortie et de suivre les dépôts jour par jour.

> Design inspiré de WhatsApp (interface épurée, typographie système lisible),
> avec une palette **or/jaune + noir** en mode sombre et **or + blanc/gris** en
> mode clair. Icônes **Iconsax**. Base de données **SQLite** (migration
> PostgreSQL prévue).

---

## ✨ Fonctionnalités du MVP

### 1. Navigation principale (2 onglets)
- **Retrouver un auto** — vérifier les informations d'un véhicule quand son
  propriétaire vient le récupérer.
- **Enregistrer un auto** — enregistrer un nouveau client / véhicule.

### 2. Vérification par QR / code numérique + plaque
- Scan du **QR code** (caméra via `mobile_scanner`) ou saisie d'un **code
  numérique**.
- Recherche du véhicule en base.
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
│   └── database_helper.dart      # CRUD SQLite + seed démo
├── models/
│   ├── parking_center.dart       # Centre de garde (délai)
│   ├── vehicle.dart              # Véhicule / propriétaire
│   └── parking_session.dart      # Session de garde + statut effectif
├── screens/
│   ├── splash_screen.dart        # Splash + seed démo
│   ├── home_screen.dart          # Bottom nav 2 onglets
│   ├── retrieve_vehicle_screen.dart  # Retrouver + vérif plaque
│   ├── register_vehicle_screen.dart  # Enregistrer un véhicule
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
    ├── custom_bottom_nav.dart    # Bottom nav (Iconsax)
    ├── day_tab.dart              # Onglet jour
    ├── status_badge.dart         # Badge statut
    ├── vehicle_card.dart         # Carte véhicule
    └── app_settings_sheet.dart   # Bottom sheet paramètres
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

## 🗄️ Schéma de la base SQLite

### `parking_centers`
| Colonne          | Type    | Description                          |
|------------------|---------|--------------------------------------|
| id               | INTEGER | PK auto-increment                    |
| name             | TEXT    | Nom du centre                        |
| address          | TEXT    | Adresse                              |
| max_hours_delay  | INTEGER | Délai de garde en heures (défaut 24) |
| created_at       | TEXT    | ISO-8601                             |

### `vehicles`
| Colonne       | Type    | Description                    |
|---------------|---------|--------------------------------|
| id            | INTEGER | PK                             |
| plate         | TEXT    | Plaque d'immatriculation       |
| owner_name    | TEXT    | Nom du propriétaire            |
| owner_phone   | TEXT    | Téléphone (optionnel)          |
| center_id     | INTEGER | FK → parking_centers           |
| qr_code       | TEXT    | Contenu du QR code             |
| numeric_code  | TEXT    | Code numérique de secours      |
| photo_path    | TEXT    | Photo de contrôle (optionnel)  |
| created_at    | TEXT    | ISO-8601                       |

### `parking_sessions`
| Colonne     | Type    | Description                                  |
|-------------|---------|----------------------------------------------|
| id          | INTEGER | PK                                           |
| vehicle_id  | INTEGER | FK → vehicles                                |
| center_id   | INTEGER | FK → parking_centers                         |
| entry_time  | TEXT    | Date/heure de dépôt                          |
| exit_time   | TEXT    | Date/heure de récupération (nullable)        |
| status      | INTEGER | 0=en cours, 1=récupéré, 2=non récupéré       |
| notes       | TEXT    | Notes libres                                 |

> Le statut **« Non récupéré »** est calculé dynamiquement à partir de
> `entry_time + max_hours_delay` (méthode `ParkingSession.effectiveStatus`).

---

## 🧪 Comptes / données de démo

| Plaque      | Propriétaire   | Code numérique | QR code          |
|-------------|----------------|----------------|------------------|
| AB-123-CD   | Jean Houngbo   | 1001           | AUTOPARK-1001    |
| EF-456-GH   | Aïcha Sossou   | 1002           | AUTOPARK-1002    |
| IJ-789-KL   | Marcel Dossou  | 1003           | AUTOPARK-1003    |
| MN-012-OP   | Grâce Kponou   | 1004           | AUTOPARK-1004    |

Testez le parcours **Retrouver un auto** → bouton « Saisir code » → `1001`.

---

## 🗺️ Roadmap (post-MVP)

- [ ] Migration SQLite → **PostgreSQL** (API REST sécurisée)
- [ ] **Reconnaissance automatique de plaque** (ALPR — Anyline / ML Kit)
- [ ] **Vérification biométrique 1:1 / 1:N** (VeriFinger / Innovatrics)
- [ ] **Paiement Mobile Money** + wallet / abonnements
- [ ] Gestion multi-utilisateurs et rôles (opérateurs, superviseurs)
- [ ] Mode hors-ligne + synchronisation
- [ ] Rapports de fréquentation et revenus
- [ ] Notifications push (véhicule non récupéré)

---

## 📌 Notes

- Ce MVP stocke les données **localement** sur l'appareil (SQLite). Aucune
  donnée n'est envoyée sur un serveur.
- Le scan de plaque actuel est **manuel / simulé** ; l'intégration ALPR réelle
  est prévue dans la roadmap.
- La biométrie et le paiement ne sont **pas** inclus dans ce MVP (voir doc de
  cadrage).

---

© AutoPark — Projet de sécurisation des parkings motos au Bénin.
