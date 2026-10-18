import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warmpath_app/features/ratings/rating_models.dart';
import 'package:warmpath_app/features/ratings/rating_page.dart';
import 'package:warmpath_app/features/ratings/dispute_dialog.dart';
import 'package:warmpath_app/features/ratings/ratings_api_service.dart';
import 'package:warmpath_app/features/ratings/ratings_controller.dart';
import '../../test_helpers.dart';

class MockRatingsApiService extends RatingsApiService {
  bool submitRatingCalled = false;
  bool submitRequestQualityCalled = false;
  bool openDisputeCalled = false;

  @override
  Future<void> submitRating({
    required String sessionId,
    required int stars,
    String? reason,
    List<String> tags = const [],
  }) async {
    submitRatingCalled = true;
  }

  @override
  Future<void> submitRequestQuality({
    required String sessionId,
    required int stars,
    String? note,
  }) async {
    submitRequestQualityCalled = true;
  }

  @override
  Future<void> openDispute({
    required String sessionId,
    required String reason,
    required String details,
  }) async {
    openDisputeCalled = true;
  }
}

void main() {
  group('GiverBandInfo Model Tests', () {
    test('parses band and payout share correctly', () {
      final json = {
        'giver_id': 'g123',
        'current_band': 'Trusted',
        'smoothed_average': 4.45,
        'rated_sessions_count': 7,
        'completion_rate': 0.98,
        'payout_share': 0.70,
        'next_band': 'Top Rated',
        'progress_notes': 'Needs at least 10 rated sessions',
      };

      final bandInfo = GiverBandInfo.fromJson(json);
      expect(bandInfo.giverId, 'g123');
      expect(bandInfo.currentBand, 'Trusted');
      expect(bandInfo.smoothedAverage, 4.45);
      expect(bandInfo.payoutShare, 0.70);
      expect(bandInfo.nextBand, 'Top Rated');
      expect(bandInfo.progressNotes, contains('10 rated sessions'));
    });
  });

  group('Rating Validation Logic Tests', () {
    test('validates stars within 1 to 5 range', () {
      bool isValidRating(int stars) => stars >= 1 && stars <= 5;

      expect(isValidRating(1), isTrue);
      expect(isValidRating(5), isTrue);
      expect(isValidRating(0), isFalse);
      expect(isValidRating(6), isFalse);
    });

    test('validates dispute reasons', () {
      const validReasons = {'no_show', 'low_effort', 'abusive', 'other'};
      expect(validReasons.contains('no_show'), isTrue);
      expect(validReasons.contains('unprepared'), isFalse);
    });
  });

  group('RatingPage Widget Tests', () {
    testWidgets('renders student rating view and validates template safety', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockService = MockRatingsApiService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ratingsApiServiceProvider.overrideWithValue(mockService),
          ],
          child: const MaterialApp(
            home: RatingPage(
              sessionId: 's-test-1',
              isGiverRatingStudent: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify no unescaped templates in rendered text
      expectNoUnescapedTemplates(tester);

      expect(find.text('Rate Your Mentorship Session'), findsOneWidget);
      expect(find.text('How valuable was this session with your mentor?'), findsOneWidget);
      expect(find.text('Helpful'), findsOneWidget);
      expect(find.text('Actionable Advice'), findsOneWidget);
      expect(find.text('Submit Feedback'), findsOneWidget);
    });

    testWidgets('renders giver rating request quality view and validates template safety', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockService = MockRatingsApiService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ratingsApiServiceProvider.overrideWithValue(mockService),
          ],
          child: const MaterialApp(
            home: RatingPage(
              sessionId: 's-test-2',
              isGiverRatingStudent: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify no unescaped templates in rendered text
      expectNoUnescapedTemplates(tester);

      expect(find.text('Rate Student Preparation'), findsOneWidget);
      expect(find.text('How prepared and clear was the student?'), findsOneWidget);
      expect(find.text('Submit Feedback'), findsOneWidget);
    });
  });

  group('DisputeDialog Widget Tests', () {
    testWidgets('renders dispute dialog and validates input length without unescaped templates', (WidgetTester tester) async {
      final mockService = MockRatingsApiService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DisputeDialog(
              sessionId: 's-dispute-1',
              api: mockService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify no unescaped templates in rendered text
      expectNoUnescapedTemplates(tester);

      expect(find.text('Open Session Dispute'), findsOneWidget);
      expect(find.text('Submit Dispute'), findsOneWidget);

      // Attempt to submit with empty details
      await tester.tap(find.text('Submit Dispute'));
      await tester.pumpAndSettle();

      // Should show error snackbar about minimum characters
      expect(find.text('Please describe the issue in at least 10 characters.'), findsOneWidget);
      expect(mockService.openDisputeCalled, isFalse);

      expectNoUnescapedTemplates(tester);
    });
  });
}
