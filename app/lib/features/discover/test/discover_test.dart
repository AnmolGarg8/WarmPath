import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../controllers/pagination_controller.dart';
import '../models/discover_models.dart';
import '../services/discover_service.dart';
import '../widgets/giver_card.dart';

class MockDiscoverService extends DiscoverService {
  final List<RecommendationItemData> mockItems;
  final String? nextCursorToReturn;
  final bool mockLocked;
  final String? mockLockReason;

  MockDiscoverService({
    required this.mockItems,
    this.nextCursorToReturn,
    this.mockLocked = false,
    this.mockLockReason,
  });

  @override
  Future<RecommendationsData> getRecommendations({
    required String scope,
    int limit = 10,
    String? cursor,
    String? filterDomain,
    String? filterHelpType,
  }) async {
    return RecommendationsData(
      items: mockItems,
      nextCursor: nextCursorToReturn,
      scope: scope,
      locked: mockLocked,
      lockReason: mockLockReason,
    );
  }
}

void main() {
  group('PaginationController Tests', () {
    test('loadInitial populates items and updates cursor flags', () async {
      final mockGiver = GiverCardData(
        id: '11111111-1111-1111-1111-111111111111',
        fullName: 'Aditi Sharma',
        headline: 'Staff SDE at Google',
        band: 'Top Rated',
        ratingSummary: RatingSummaryData(band: 'Top Rated', smoothedAvg: 4.8, totalSessions: 14, completionRate: 0.98),
        availabilitySummary: AvailabilitySummaryData(online: true, capacityLeft: 3),
      );

      final item = RecommendationItemData(
        giver: mockGiver,
        whyLines: ['Shares your Python skills', 'Same college, 2 years ahead'],
      );

      final mockService = MockDiscoverService(
        mockItems: [item],
        nextCursorToReturn: 'cursor_page_2',
      );

      final controller = PaginationController(service: mockService, scope: 'own_college');

      expect(controller.isLoading, isFalse);
      expect(controller.items, isEmpty);

      await controller.loadInitial();

      expect(controller.isLoading, isFalse);
      expect(controller.items.length, 1);
      expect(controller.items[0].giver.fullName, 'Aditi Sharma');
      expect(controller.nextCursor, 'cursor_page_2');
      expect(controller.hasMore, isTrue);
    });

    test('loadMore appends new items and handles pagination end', () async {
      final item1 = RecommendationItemData(
        giver: GiverCardData(
          id: '1',
          fullName: 'Alum 1',
          headline: 'SDE 1',
          band: 'Rising',
          ratingSummary: RatingSummaryData(band: 'Rising', smoothedAvg: 4.0, totalSessions: 2, completionRate: 1.0),
          availabilitySummary: AvailabilitySummaryData(online: false, capacityLeft: 2),
        ),
        whyLines: ['Rising mentor'],
      );
      final item2 = RecommendationItemData(
        giver: GiverCardData(
          id: '2',
          fullName: 'Alum 2',
          headline: 'SDE 2',
          band: 'Trusted',
          ratingSummary: RatingSummaryData(band: 'Trusted', smoothedAvg: 4.5, totalSessions: 8, completionRate: 0.95),
          availabilitySummary: AvailabilitySummaryData(online: true, capacityLeft: 4),
        ),
        whyLines: ['Trusted mentor'],
      );

      final mockService = MockDiscoverService(
        mockItems: [item2],
        nextCursorToReturn: null, // No more pages
      );

      final controller = PaginationController(service: mockService, scope: 'own_college');
      controller.items = [item1];
      controller.nextCursor = 'cursor_page_2';
      controller.hasMore = true;

      await controller.loadMore();

      expect(controller.items.length, 2);
      expect(controller.hasMore, isFalse);
      expect(controller.nextCursor, isNull);
    });
  });

  group('GiverCard Widget Rendering & Privacy', () {
    testWidgets('renders unlocked card with why_lines and never renders raw scores or embeddings', (tester) async {
      final giver = GiverCardData(
        id: '22222222-2222-2222-2222-222222222222',
        fullName: 'Rahul Verma',
        headline: 'Lead Architect at Swiggy',
        band: 'Top Rated',
        offers: ['mock_interview', 'resume_review'],
        ratingSummary: RatingSummaryData(band: 'Top Rated', smoothedAvg: 4.9, totalSessions: 20, completionRate: 1.0),
        availabilitySummary: AvailabilitySummaryData(online: true, capacityLeft: 4),
      );

      final item = RecommendationItemData(
        giver: giver,
        whyLines: ['Shares your Python and FastAPI skills', 'Online now for instant connection'],
        locked: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GiverCard(item: item),
          ),
        ),
      );

      // Plain language reasons exist
      expect(find.text('Rahul Verma'), findsOneWidget);
      expect(find.text('Lead Architect at Swiggy'), findsOneWidget);
      expect(find.text('Top Rated'), findsOneWidget);
      expect(find.text('Online now'), findsOneWidget);
      expect(find.text('Shares your Python and FastAPI skills'), findsOneWidget);

      // Raw algorithmic score and embeddings are strictly never shown
      expect(find.textContaining('0.85'), findsNothing);
      expect(find.textContaining('embedding'), findsNothing);
      expect(find.textContaining('score:'), findsNothing);
      expect(find.textContaining('vector'), findsNothing);
    });

    testWidgets('renders locked banner with upgrade prompt for cross-college gated card', (tester) async {
      final giver = GiverCardData(
        id: '33333333-3333-3333-3333-333333333333',
        fullName: 'Priya (Verified Giver)',
        headline: 'Senior SDE at Amazon',
        band: 'Trusted',
        ratingSummary: RatingSummaryData(band: 'Trusted', smoothedAvg: 4.6, totalSessions: 11, completionRate: 0.95),
        availabilitySummary: AvailabilitySummaryData(online: false, capacityLeft: 1),
      );

      final item = RecommendationItemData(
        giver: giver,
        whyLines: ['Senior mentor from Amazon'],
        locked: true,
        lockReason: 'plan_required',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GiverCard(item: item),
          ),
        ),
      );

      // Locked upgrade prompt banner exists
      expect(find.text('Cross-College Mentor: Standard or Premium Plan required.'), findsOneWidget);
      expect(find.text('Upgrade'), findsOneWidget);
    });
  });
}
