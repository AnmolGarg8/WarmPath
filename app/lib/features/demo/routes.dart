// allow-mock-file: guided demo, simulated and labelled
import 'package:go_router/go_router.dart';
import 'framework/demo_scaffold.dart';

final List<RouteBase> demoRoutes = [
  GoRoute(
    path: '/demo',
    name: 'guided_demo',
    builder: (context, state) => const DemoScaffold(),
  ),
];
