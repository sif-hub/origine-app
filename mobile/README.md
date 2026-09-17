# ORIGINE — Application Flutter

Application mobile Flutter de la plateforme ORIGINE, plateforme généalogique
et culturelle camerounaise.

## Prérequis

- Flutter SDK 3.x (`flutter --version`)
- Dart SDK 3.x
- Android Studio ou VS Code + extensions Flutter/Dart
- API ORIGINE (PHP) en cours d'exécution (voir `/origine/README.md`)

## Installation rapide

```bash
# 1. Se placer dans le dossier
cd origine_flutter

# 2. Installer les dépendances
flutter pub get

# 3. Configurer l'URL de l'API
# Ouvrir lib/core/utils/constants.dart et modifier apiBaseUrl :
#   - Émulateur Android  : http://10.0.2.2:8080/api
#   - Simulateur iOS     : http://127.0.0.1:8080/api
#   - Appareil physique  : http://VOTRE_IP_LAN:8080/api
#   - Production         : https://votre-domaine.com/api

# 4. Lancer l'application
flutter run
```

## Fontes

Téléchargez les fontes Poppins depuis Google Fonts :
https://fonts.google.com/specimen/Poppins

Placez dans `assets/fonts/` :
- `Poppins-Regular.ttf`
- `Poppins-SemiBold.ttf`
- `Poppins-Bold.ttf`

Sans ces fichiers, Flutter utilisera la fonte système par défaut.

## Structure du projet

```
lib/
├── main.dart                     → Point d'entrée + BlocProviders
├── core/
│   ├── api/
│   │   ├── api_client.dart       → Client Dio singleton (JWT auto)
│   │   └── app_router.dart       → GoRouter + garde d'authentification
│   ├── theme/
│   │   └── app_theme.dart        → Palette verte camerounaise + ThemeData
│   └── utils/
│       └── constants.dart        → URL API, routes nommées, clés storage
├── shared/
│   ├── models/
│   │   ├── user_model.dart
│   │   └── person_model.dart     → Person, Family, FamilyTree, TreeEdge
│   └── widgets/
│       └── app_widgets.dart      → Boutons, champs, cartes, avatars...
└── features/
    ├── auth/
    │   ├── data/auth_repository.dart
    │   ├── domain/auth_bloc.dart
    │   └── presentation/screens/
    │       ├── splash_screen.dart
    │       ├── login_screen.dart
    │       └── register_screen.dart
    ├── home/presentation/screens/home_screen.dart
    ├── profile/presentation/screens/profile_screen.dart
    ├── genealogy/presentation/screens/genealogy_screen.dart
    └── ai/presentation/screens/
        ├── ai_screen.dart         → Recherche naturelle + Traditions + Noms
        └── chat_screen.dart       → Chatbot conversationnel ORIGINE AI
```

## Fonctionnalités implémentées

- ✅ Splash screen avec animation + vérification JWT automatique
- ✅ Connexion / Inscription (avec indicateur de force du mot de passe)
- ✅ Navigation par onglets (Accueil / Arbre / IA / Profil)
- ✅ Dashboard avec accès rapide et carte ORIGINE AI
- ✅ Arbre généalogique : liste des personnes, vue canvas (nœuds + traits),
     ajout père/mère/enfant/conjoint via bottom sheets
- ✅ Profil utilisateur : consultation et édition des informations
- ✅ ORIGINE AI (3 onglets) : recherche en langage naturel, traditions
     camerounaises avec grille de raccourcis, significations de noms
- ✅ Chatbot conversationnel : bulles de message, indicateur de frappe animé,
     suggestions initiales, historique multi-tours
- ✅ Gestion JWT : refresh automatique du token, stockage sécurisé
- ✅ Thème vert forêt camerounais avec palette complète

## Lancer en production

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS (macOS requis)
flutter build ios --release
```

## Couleurs principales

| Couleur         | Hex       | Usage                     |
|-----------------|-----------|---------------------------|
| Vert Forêt      | `#0A3D2E` | AppBar, boutons primaires |
| Vert Clair      | `#1D7A4C` | Accents, liens actifs     |
| Or / Savane     | `#C9942C` | Boutons CTA, highlights   |
| Crème           | `#F7F3EC` | Fond de l'application     |
