import 'package:go_router/go_router.dart';
import 'package:warmpath_app/features/discover/discover_page.dart';

final List<RouteBase> featureRoutes = [
  GoRoute(
    path: '/discover',
    builder: (context, state) => const DiscoverPage(),
  ),
];
