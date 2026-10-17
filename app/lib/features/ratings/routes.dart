import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'ratings_page.dart';
import 'band_page.dart';
import 'rating_page.dart';

final List<RouteBase> ratingsRoutes = [
  GoRoute(
    path: '/ratings',
    name: 'ratings',
    builder: (context, state) => const RatingsPage(),
  ),
  GoRoute(
    path: '/ratings/band',
    name: 'band',
    builder: (context, state) => const BandPage(),
  ),
  GoRoute(
    path: '/ratings/rate',
    name: 'rate',
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>? ?? {};
      return RatingPage(
        sessionId: extra['session_id']?.toString() ?? '',
        isGiverRatingStudent: extra['is_giver'] as bool? ?? false,
      );
    },
  ),
];
