import 'package:go_router/go_router.dart';
import 'package:warmpath_app/features/availability/availability_page.dart';

final List<RouteBase> featureRoutes = [
  GoRoute(
    path: '/availability',
    builder: (context, state) => const AvailabilityPage(),
  ),
];
