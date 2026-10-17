import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'sessions_page.dart';

final List<RouteBase> sessionsRoutes = [
  GoRoute(
    path: '/sessions',
    name: 'sessions',
    builder: (context, state) => const SessionsPage(),
  ),
];
