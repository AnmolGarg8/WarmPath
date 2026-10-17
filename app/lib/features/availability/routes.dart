import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'availability_page.dart';

final List<RouteBase> availabilityRoutes = [
  GoRoute(
    path: '/availability',
    name: 'availability',
    builder: (context, state) => const AvailabilityPage(),
  ),
];
