import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/routes.dart';
import 'features/safety/routes.dart';
import 'features/onboarding/routes.dart';
import 'features/discover/routes.dart';
import 'features/availability/routes.dart';
import 'features/sessions/routes.dart';
import 'features/ratings/routes.dart';
import 'features/plans_wallet/routes.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    ...discoverRoutes,
    ...authRoutes,
    ...safetyRoutes,
    ...onboardingRoutes,
    ...availabilityRoutes,
    ...sessionsRoutes,
    ...ratingsRoutes,
    ...plansWalletRoutes,
  ],
);
