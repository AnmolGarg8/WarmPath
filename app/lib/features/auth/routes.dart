import 'package:go_router/go_router.dart';
import 'package:warmpath_app/features/auth/auth_page.dart';

final List<RouteBase> featureRoutes = [
  GoRoute(
    path: '/auth',
    builder: (context, state) => const AuthPage(),
  ),
];
