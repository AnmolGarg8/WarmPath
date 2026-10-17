import 'package:go_router/go_router.dart';
import 'discover_page.dart';
import 'widgets/giver_detail_page.dart';

final List<RouteBase> discoverRoutes = [
  GoRoute(
    path: '/',
    name: 'discover',
    builder: (context, state) => const DiscoverPage(),
    routes: [
      GoRoute(
        path: 'givers/:id',
        name: 'giver_detail',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return GiverDetailPage(giverId: id);
        },
      ),
    ],
  ),
];
