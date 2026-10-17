import 'package:go_router/go_router.dart';
import 'pages/why_limited_page.dart';

final List<RouteBase> safetyRoutes = [
  GoRoute(
    path: '/safety',
    name: 'safety',
    builder: (context, state) => const WhyLimitedPage(),
  ),
  GoRoute(
    path: '/safety/why-limited',
    name: 'safety_why_limited',
    builder: (context, state) => const WhyLimitedPage(),
  ),
];
