import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'safety_page.dart';

final List<RouteBase> safetyRoutes = [
  GoRoute(
    path: '/safety',
    name: 'safety',
    builder: (context, state) => const SafetyPage(),
  ),
];
