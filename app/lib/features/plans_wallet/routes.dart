import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'plans_wallet_page.dart';

final List<RouteBase> plansWalletRoutes = [
  GoRoute(
    path: '/plans-wallet',
    name: 'plans_wallet',
    builder: (context, state) => const PlansWalletPage(),
  ),
];
