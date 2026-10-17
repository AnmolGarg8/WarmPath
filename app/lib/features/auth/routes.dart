import 'package:go_router/go_router.dart';
import 'pages/email_page.dart';
import 'pages/onboarding_intro_page.dart';
import 'pages/otp_page.dart';
import 'pages/profile_basics_page.dart';
import 'pages/profile_page.dart';
import 'pages/splash_page.dart';
import 'pages/verification_page.dart';

final List<RouteBase> authRoutes = [
  GoRoute(
    path: '/auth',
    name: 'auth',
    builder: (context, state) => const SplashPage(),
  ),
  GoRoute(
    path: '/auth/intro',
    name: 'auth_intro',
    builder: (context, state) => const OnboardingIntroPage(),
  ),
  GoRoute(
    path: '/auth/email',
    name: 'auth_email',
    builder: (context, state) => const EmailPage(),
  ),
  GoRoute(
    path: '/auth/otp',
    name: 'auth_otp',
    builder: (context, state) {
      final email = state.uri.queryParameters['email'] ?? '';
      return OtpPage(email: email);
    },
  ),
  GoRoute(
    path: '/auth/profile-basics',
    name: 'auth_profile_basics',
    builder: (context, state) => const ProfileBasicsPage(),
  ),
  GoRoute(
    path: '/profile',
    name: 'profile',
    builder: (context, state) => const ProfilePage(),
  ),
  GoRoute(
    path: '/verification',
    name: 'verification',
    builder: (context, state) => const VerificationPage(),
  ),
];
