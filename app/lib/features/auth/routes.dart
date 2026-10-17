import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'auth_page.dart';

final List<RouteBase> authRoutes = [
  GoRoute(
    path: '/auth',
    name: 'auth',
    builder: (context, state) => const AuthPage(),
  ),
];
