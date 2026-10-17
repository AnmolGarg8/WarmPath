import 'package:go_router/go_router.dart';
import 'package:warmpath_app/features/sessions/sessions_page.dart';

final List<RouteBase> featureRoutes = [
  GoRoute(
    path: '/sessions',
    builder: (context, state) => const SessionsPage(),
  ),
];
