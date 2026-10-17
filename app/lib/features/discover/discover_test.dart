import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warmpath_app/core/api/dio_client.dart';
import 'package:warmpath_app/features/discover/discover_models.dart';
import 'package:warmpath_app/features/discover/discover_page.dart';
import 'package:warmpath_app/features/discover/discover_providers.dart';

void main() {
  group('DiscoverPage Widget Tests', () {
    testWidgets('assert empty response displays the empty state (no person card)', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recommendationsProvider.overrideWith(
              (ref) => Future.value(
                const RecommendationsResponse(items: [], scope: 'own_college'),
              ),
            ),
          ],
          child: const MaterialApp(
            home: DiscoverPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Recommendations Found'), findsOneWidget);
      expect(
        find.text('Upload your resume and state your intent to get matched with same-college alumni.'),
        findsOneWidget,
      );
      expect(find.text('Upload Resume & Set Intent'), findsOneWidget);
      // Ensure no mentor card fields exist
      expect(find.text('Recommended Mentor'), findsNothing);
      expect(find.text('Connect'), findsNothing);
    });

    testWidgets('assert 501 displays the not-available state', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recommendationsProvider.overrideWith(
              (ref) => Future.error(
                AppException(
                  code: 'module_not_implemented',
                  message: 'Endpoint is scaffolded and pending module implementation.',
                  statusCode: 501,
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: DiscoverPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Feature Unavailable'), findsOneWidget);
      expect(find.text('This feature is not available yet'), findsOneWidget);
      expect(find.text('Recommended Mentor'), findsNothing);
    });

    testWidgets('assert real-shaped response renders fields from response', (WidgetTester tester) async {
      final mockResponse = RecommendationsResponse(
        items: [
          const RecommendationItem(
            giver: GiverPublicCard(
              id: 'giver-101',
              fullName: 'Priya Sharma',
              headline: 'Senior SDE at Google',
              roleTitle: 'Alumnus',
              band: 'Top Rated',
              skills: ['Go', 'Kubernetes', 'System Design'],
              availabilitySummary: AvailabilitySummary(online: true, capacityLeft: 2),
            ),
            whyLines: [
              'Same college alumni (Batch of 2020)',
              'Matches your target role in Backend Systems',
            ],
            locked: false,
          ),
        ],
        scope: 'own_college',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recommendationsProvider.overrideWith(
              (ref) => Future.value(mockResponse),
            ),
          ],
          child: const MaterialApp(
            home: DiscoverPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Priya Sharma'), findsOneWidget);
      expect(find.text('Senior SDE at Google'), findsOneWidget);
      expect(find.text('Top Rated'), findsOneWidget);
      expect(find.text('Online'), findsOneWidget);
      expect(find.text('• Same college alumni (Batch of 2020)'), findsOneWidget);
      expect(find.text('• Matches your target role in Backend Systems'), findsOneWidget);
      expect(find.text('Go'), findsOneWidget);
      expect(find.text('Kubernetes'), findsOneWidget);
      expect(find.text('System Design'), findsOneWidget);
      expect(find.text('Connect'), findsOneWidget);
      expect(find.text('Recommended Mentor'), findsNothing);
    });
  });
}
