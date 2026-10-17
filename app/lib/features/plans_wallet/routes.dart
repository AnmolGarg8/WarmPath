/// Routes for Plans & Wallet feature.
/// Owner: M4
library;

import 'package:go_router/go_router.dart';
import 'plans_wallet_page.dart';

final List<RouteBase> plansWalletRoutes = [
  GoRoute(
    path: '/plans-wallet',
    name: 'plans_wallet',
    builder: (context, state) {
      final tab = state.uri.queryParameters['tab'];
      final reason = state.uri.queryParameters['reason'];
      return PlansWalletPage(initialTab: tab, reason: reason);
    },
    routes: [
      GoRoute(
        path: 'plans',
        name: 'plans_subroute',
        builder: (context, state) {
          final reason = state.uri.queryParameters['reason'];
          return PlansWalletPage(initialTab: 'plans', reason: reason);
        },
      ),
      GoRoute(
        path: 'wallet',
        name: 'wallet_subroute',
        builder: (context, state) => const PlansWalletPage(initialTab: 'wallet'),
      ),
      GoRoute(
        path: 'earnings',
        name: 'earnings_subroute',
        builder: (context, state) => const PlansWalletPage(initialTab: 'earnings'),
      ),
    ],
  ),
];
