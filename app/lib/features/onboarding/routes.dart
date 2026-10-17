import 'package:go_router/go_router.dart';
import 'package:warmpath_app/features/onboarding/onboarding_page.dart';

final List<RouteBase> featureRoutes = [
  GoRoute(
    path: '/onboarding',
    builder: (context, state) => const OnboardingPage(),
  ),
];
