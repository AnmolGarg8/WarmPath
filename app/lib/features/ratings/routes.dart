import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'ratings_page.dart';

final List<RouteBase> ratingsRoutes = [
  GoRoute(
    path: '/ratings',
    name: 'ratings',
    builder: (context, state) => const RatingsPage(),
  ),
];
