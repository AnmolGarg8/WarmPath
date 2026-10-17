import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:warmpath_app/features/auth/routes.dart' as auth;
import 'package:warmpath_app/features/safety/routes.dart' as safety;
import 'package:warmpath_app/features/onboarding/routes.dart' as onboarding;
import 'package:warmpath_app/features/discover/routes.dart' as discover;
import 'package:warmpath_app/features/availability/routes.dart' as availability;
import 'package:warmpath_app/features/sessions/routes.dart' as sessions;
import 'package:warmpath_app/features/ratings/routes.dart' as ratings;
import 'package:warmpath_app/features/plans_wallet/routes.dart' as plans_wallet;

final GoRouter appRouter = GoRouter(
  initialLocation: '/discover',
  routes: [
    ...auth.featureRoutes,
    ...safety.featureRoutes,
    ...onboarding.featureRoutes,
    ...discover.featureRoutes,
    ...availability.featureRoutes,
    ...sessions.featureRoutes,
    ...ratings.featureRoutes,
    ...plans_wallet.featureRoutes,
  ],
);
