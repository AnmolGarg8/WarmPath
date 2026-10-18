import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/api/dio_client.dart';
import 'core/api/websocket_service.dart';
import 'core/storage/secure_storage.dart';
import 'features/auth/auth_providers.dart';
import 'features/auth/pages/splash_page.dart';
import 'features/auth/routes.dart';
import 'features/availability/routes.dart';
import 'features/discover/discover_page.dart';
import 'features/discover/routes.dart';
import 'features/onboarding/routes.dart';
import 'features/demo/routes.dart';
import 'features/plans_wallet/routes.dart';
import 'features/ratings/routes.dart';
import 'features/safety/routes.dart';
import 'features/sessions/routes.dart';

const Set<String> _publicExactRoutes = {
  '/auth',
  '/splash',
  '/auth/intro',
  '/auth/email',
  '/auth/otp',
  '/onboarding',
  '/onboarding/giver-profile',
  '/demo',
};

bool isPublicRoute(String location) {
  final path = Uri.parse(location).path.replaceAll(RegExp(r'/+$'), '');
  final normalized = path.isEmpty ? '/' : path;
  if (_publicExactRoutes.contains(normalized)) return true;
  if (normalized.startsWith('/onboarding')) return true;
  if (normalized.startsWith('/auth/intro')) return true;
  if (normalized.startsWith('/auth/email')) return true;
  if (normalized.startsWith('/auth/otp')) return true;
  if (normalized.startsWith('/demo')) return true;
  return false;
}

FutureOr<String?> routerAuthRedirect(BuildContext context, GoRouterState state) async {
  final location = state.uri.path;
  final isPublic = isPublicRoute(location);

  // Check in-memory bridge or secure storage
  bool hasToken = AuthNotifierBridge.instance.isAuthenticated;
  if (!hasToken) {
    final token = await SecureStorageService.getAccessToken();
    if (token != null && token.isNotEmpty) {
      hasToken = true;
      AuthNotifierBridge.instance.setAuthenticated(true);
    }
  }

  // 1. Signed-out user attempting to access private route -> redirect to /auth/email
  if (!hasToken) {
    if (!isPublic) {
      return '/auth/email';
    }
    return null;
  }

  // 2. Authenticated user attempting to access sign-in screens -> redirect to /discover
  if (hasToken) {
    if (location == '/auth/email' ||
        location == '/auth/otp' ||
        location == '/auth/intro' ||
        location == '/auth' ||
        location == '/splash') {
      return '/discover';
    }
  }

  return null;
}

void _initDioLogoutHandler() {
  DioClient().onLogout = () {
    WebSocketService().disconnect();
    AuthNotifierBridge.instance.setAuthenticated(false);
    appRouter.go('/auth/email');
  };
}

final GoRouter appRouter = () {
  _initDioLogoutHandler();
  return GoRouter(
    initialLocation: '/auth',
    refreshListenable: AuthNotifierBridge.instance,
    redirect: routerAuthRedirect,
    routes: <RouteBase>[
      GoRoute(
        path: '/discover',
        name: 'discover_main',
        builder: (context, state) => const DiscoverPage(),
      ),
      GoRoute(
        path: '/splash',
        name: 'splash_alias',
        builder: (context, state) => const SplashPage(),
      ),
      ...discoverRoutes,
      ...authRoutes,
      ...safetyRoutes,
      ...onboardingRoutes,
      ...availabilityRoutes,
      ...sessionsRoutes,
      ...ratingsRoutes,
      ...plansWalletRoutes,
      ...demoRoutes,
    ],
  );
}();
