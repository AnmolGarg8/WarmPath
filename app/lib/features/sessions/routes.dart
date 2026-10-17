import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'sessions_page.dart';
import 'inbox_page.dart';
import 'connect_page.dart';

final List<RouteBase> sessionsRoutes = [
  GoRoute(
    path: '/sessions',
    name: 'sessions',
    builder: (context, state) => const SessionsPage(),
  ),
  GoRoute(
    path: '/inbox',
    name: 'inbox',
    builder: (context, state) => const InboxPage(),
  ),
  GoRoute(
    path: '/connect',
    name: 'connect',
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>? ?? {};
      return ConnectPage(
        giverId: extra['giver_id']?.toString() ?? '',
        giverName: extra['giver_name']?.toString() ?? 'Giver',
        isOnlineNow: extra['is_online_now'] as bool? ?? false,
        isOwnCollege: extra['is_own_college'] as bool? ?? true,
        studentPlan: extra['student_plan']?.toString() ?? 'Standard',
        prefilledIntent: extra['prefilled_intent']?.toString(),
      );
    },
  ),
];
