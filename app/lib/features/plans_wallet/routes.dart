import 'package:go_router/go_router.dart';
import 'package:warmpath_app/features/plans_wallet/plans_wallet_page.dart';

final List<RouteBase> featureRoutes = [
  GoRoute(
    path: '/wallet',
    builder: (context, state) => const PlansWalletPage(),
  ),
];
