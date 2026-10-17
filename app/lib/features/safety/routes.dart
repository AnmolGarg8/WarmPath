import 'package:go_router/go_router.dart';
import 'package:warmpath_app/features/safety/safety_page.dart';

final List<RouteBase> featureRoutes = [
  GoRoute(
    path: '/safety',
    builder: (context, state) => const SafetyPage(),
  ),
];
