import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'discover_page.dart';

final List<RouteBase> discoverRoutes = [
  GoRoute(
    path: '/',
    name: 'discover',
    builder: (context, state) => const DiscoverPage(),
  ),
];
