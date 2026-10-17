import 'package:go_router/go_router.dart';
import 'onboarding_page.dart';

final List<RouteBase> onboardingRoutes = [
  GoRoute(
    path: '/onboarding',
    name: 'onboarding',
    builder: (context, state) => const OnboardingPage(),
  ),
  GoRoute(
    path: '/onboarding/giver-profile',
    name: 'giver_profile_setup',
    builder: (context, state) => const OnboardingPage(initialStep: OnboardingStep.giverSetup),
  ),
];
