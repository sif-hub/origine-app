// lib/core/api/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/genealogy/presentation/screens/genealogy_screen.dart';
import '../../features/ai/presentation/screens/ai_screen.dart';
import '../../features/ai/presentation/screens/chat_screen.dart';
import '../utils/constants.dart';

final _storage = const FlutterSecureStorage();

final appRouter = GoRouter(
  initialLocation: AppConstants.routeSplash,
  redirect: _globalRedirect,
  routes: [
    GoRoute(
      path: AppConstants.routeSplash,
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: AppConstants.routeLogin,
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: AppConstants.routeRegister,
      builder: (_, __) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppConstants.routeHome,
      builder: (_, __) => const HomeScreen(),
    ),
    GoRoute(
      path: AppConstants.routeProfile,
      builder: (_, __) => const ProfileScreen(),
    ),
    GoRoute(
      path: AppConstants.routeGenealogy,
      builder: (_, state) {
        final familyId = state.uri.queryParameters['family_id'];
        return GenealogyScreen(familyId: familyId);
      },
    ),
    GoRoute(
      path: AppConstants.routeAI,
      builder: (_, __) => const AiScreen(),
    ),
    GoRoute(
      path: AppConstants.routeAIChat,
      builder: (_, __) => const ChatScreen(),
    ),
  ],
);

Future<String?> _globalRedirect(BuildContext context, GoRouterState state) async {
  final token = await _storage.read(key: AppConstants.kAccessToken);
  final isAuth = token != null;
  final onPublicRoute = state.matchedLocation == AppConstants.routeLogin ||
      state.matchedLocation == AppConstants.routeRegister ||
      state.matchedLocation == AppConstants.routeSplash;

  if (!isAuth && !onPublicRoute) return AppConstants.routeLogin;
  return null;
}
