// lib/core/utils/constants.dart

class AppConstants {
  // URL de base de l'API. Par défaut (dev local via `flutter run -d chrome`) :
  // localhost:8001 — le navigateur tourne sur la même machine que le backend
  // (port 8001, pas 8000 : un autre backend occupe déjà 8000 sur cette
  // machine, voir backend/start_dev.sh). En production, surchargée au build
  // via --dart-define=API_BASE_URL=https://<backend-render-url>/api.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8001/api',
  );

  // Clés de stockage sécurisé
  static const String kAccessToken  = 'access_token';
  static const String kRefreshToken = 'refresh_token';
  static const String kUserId       = 'user_id';

  // Routes nommées GoRouter
  static const String routeSplash      = '/';
  static const String routeLogin       = '/connexion';
  static const String routeRegister    = '/inscription';
  static const String routeHome        = '/accueil';
  static const String routeProfile     = '/profil';
  static const String routeGenealogy   = '/genealogie';
  static const String routeAI          = '/ai';
  static const String routeAIChat      = '/ai/chat';
}
