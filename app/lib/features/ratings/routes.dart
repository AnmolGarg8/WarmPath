import 'package:go_router/go_router.dart';
import 'package:warmpath_app/features/ratings/ratings_page.dart';

final List<RouteBase> featureRoutes = [
  GoRoute(
    path: '/ratings',
    builder: (context, state) => const RatingsPage(),
  ),
];
