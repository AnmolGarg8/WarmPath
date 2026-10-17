import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'onboarding_page.dart';

final List<RouteBase> onboardingRoutes = [
  GoRoute(
    path: '/onboarding',
    name: 'onboarding',
    builder: (context, state) => const OnboardingPage(),
  ),
];
