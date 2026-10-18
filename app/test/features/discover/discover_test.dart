import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warmpath_app/features/discover/controllers/pagination_controller.dart';
import 'package:warmpath_app/features/discover/discover_page.dart';
import 'package:warmpath_app/features/discover/models/discover_models.dart';
import 'package:warmpath_app/features/discover/services/discover_service.dart';
import 'package:warmpath_app/features/discover/widgets/giver_card.dart';

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
        nextCursorToReturn: null,
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

  group('GiverCard Layout & Overflow Prevention Tests', () {
    testWidgets('header row does not overflow at 320dp width with textScale 1.3', (tester) async {
      tester.view.physicalSize = const Size(320 * 2, 800 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final giver = GiverCardData(
        id: '1',
        fullName: 'Dr. Vikramaditya Christopher Sen-Gupta III, Head of Global Engineering',
        headline: 'Principal Architect & Technical Fellow at MultiNational Enterprise Systems',
        band: 'Top Rated',
        badges: ['Verified Employer', 'Verified Alumnus', 'Verified Faculty'],
        ratingSummary: RatingSummaryData(band: 'Top Rated', smoothedAvg: 4.9, totalSessions: 25, completionRate: 0.99),
        availabilitySummary: AvailabilitySummaryData(online: true, capacityLeft: 5),
      );

      final item = RecommendationItemData(
        giver: giver,
        whyLines: ['Top alumni mentor in your engineering discipline'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 800),
              textScaler: TextScaler.linear(1.3),
            ),
            child: Scaffold(
              body: SingleChildScrollView(child: GiverCard(item: item)),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Online now'), findsOneWidget);
      expect(find.text('5 slots left'), findsOneWidget);
      expect(find.text('Top Rated'), findsOneWidget);
    });

    testWidgets('header row does not overflow at 360dp width with textScale 1.3', (tester) async {
      tester.view.physicalSize = const Size(360 * 2, 800 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final giver = GiverCardData(
        id: '1',
        fullName: 'Dr. Vikramaditya Christopher Sen-Gupta III, Head of Global Engineering',
        headline: 'Principal Architect & Technical Fellow at MultiNational Enterprise Systems',
        band: 'Top Rated',
        badges: ['Verified Employer', 'Verified Alumnus', 'Verified Faculty'],
        ratingSummary: RatingSummaryData(band: 'Top Rated', smoothedAvg: 4.9, totalSessions: 25, completionRate: 0.99),
        availabilitySummary: AvailabilitySummaryData(online: true, capacityLeft: 5),
      );

      final item = RecommendationItemData(
        giver: giver,
        whyLines: ['Top alumni mentor in your engineering discipline'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 800),
              textScaler: TextScaler.linear(1.3),
            ),
            child: Scaffold(
              body: SingleChildScrollView(child: GiverCard(item: item)),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('GiverCard Badges & Rating Rules Tests', () {
    testWidgets('displays Verified Faculty and never defaults to Verified Alumnus', (tester) async {
      final giver = GiverCardData(
        id: '1',
        fullName: 'Prof. Sharma',
        headline: 'Professor of CS',
        band: 'Trusted',
        badges: ['Verified Faculty'],
        ratingSummary: RatingSummaryData(band: 'Trusted', smoothedAvg: 4.8, totalSessions: 10, completionRate: 1.0),
        availabilitySummary: AvailabilitySummaryData(online: false, capacityLeft: 3),
      );
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: GiverCard(item: RecommendationItemData(giver: giver, whyLines: [])))));

      expect(find.text('Verified Faculty'), findsOneWidget);
      expect(find.text('Verified Alumnus'), findsNothing);
    });

    testWidgets('displays Verified Employer and never defaults to Verified Alumnus', (tester) async {
      final giver = GiverCardData(
        id: '1',
        fullName: 'HR Director',
        headline: 'Lead Talent Partner',
        band: 'Rising',
        badges: ['Verified Employer'],
        ratingSummary: RatingSummaryData(band: 'Rising', smoothedAvg: 4.0, totalSessions: 10, completionRate: 1.0),
        availabilitySummary: AvailabilitySummaryData(online: false, capacityLeft: 3),
      );
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: GiverCard(item: RecommendationItemData(giver: giver, whyLines: [])))));

      expect(find.text('Verified Employer'), findsOneWidget);
      expect(find.text('Verified Alumnus'), findsNothing);
    });

    testWidgets('displays no verified badge when badges list is empty', (tester) async {
      final giver = GiverCardData(
        id: '1',
        fullName: 'Mentor Without Badge',
        headline: 'Contributor',
        band: 'Rising',
        badges: [],
        ratingSummary: RatingSummaryData(band: 'Rising', smoothedAvg: 4.0, totalSessions: 10, completionRate: 1.0),
        availabilitySummary: AvailabilitySummaryData(online: false, capacityLeft: 3),
      );
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: GiverCard(item: RecommendationItemData(giver: giver, whyLines: [])))));

      expect(find.textContaining('Verified'), findsNothing);
    });

    testWidgets('shows New giver badge and New rating when fewer than 5 rated sessions (never Top Rated)', (tester) async {
      final giver = GiverCardData(
        id: '1',
        fullName: 'New Mentor',
        headline: 'Software Engineer',
        band: 'Top Rated',
        badges: ['Verified Alumnus'],
        ratingSummary: RatingSummaryData(band: 'Top Rated', smoothedAvg: 5.0, totalSessions: 3, completionRate: 1.0),
        availabilitySummary: AvailabilitySummaryData(online: false, capacityLeft: 3),
      );
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: GiverCard(item: RecommendationItemData(giver: giver, whyLines: [])))));

      expect(find.text('New giver'), findsOneWidget);
      expect(find.text('Top Rated'), findsNothing);
      expect(find.text('New'), findsOneWidget);
      expect(find.textContaining('5.0'), findsNothing);
      expect(find.text(' (3 sessions)'), findsOneWidget);
    });

    testWidgets('shows smoothed average and Top Rated when 5 or more rated sessions', (tester) async {
      final giver = GiverCardData(
        id: '1',
        fullName: 'Experienced Mentor',
        headline: 'Senior Engineer',
        band: 'Top Rated',
        badges: ['Verified Alumnus'],
        ratingSummary: RatingSummaryData(band: 'Top Rated', smoothedAvg: 4.8, totalSessions: 12, completionRate: 1.0),
        availabilitySummary: AvailabilitySummaryData(online: false, capacityLeft: 3),
      );
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: GiverCard(item: RecommendationItemData(giver: giver, whyLines: [])))));

      expect(find.text('Top Rated'), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);
      expect(find.text(' (12 sessions)'), findsOneWidget);
    });
  });

  group('GiverCard Gating & Locked State Tests', () {
    testWidgets('locked card shows initial, headline, why plan is needed, upgrade button, and hides details', (tester) async {
      final giver = GiverCardData(
        id: '1',
        fullName: 'Deepak Chopra',
        headline: 'Staff VP at TechCorp',
        band: 'Top Rated',
        badges: ['Verified Alumnus'],
        offers: ['resume_review', 'system_design'],
        ratingSummary: RatingSummaryData(band: 'Top Rated', smoothedAvg: 4.95, totalSessions: 40, completionRate: 1.0),
        availabilitySummary: AvailabilitySummaryData(online: true, capacityLeft: 3),
      );
      final item = RecommendationItemData(
        giver: giver,
        whyLines: ['Top architect in your field'],
        locked: true,
        lockReason: 'plan_required',
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: GiverCard(item: item))));

      // Shows initial and headline
      expect(find.text('D.'), findsOneWidget);
      expect(find.text('Staff VP at TechCorp'), findsOneWidget);
      expect(find.text('Cross-College Mentor: Standard or Premium Plan required.'), findsOneWidget);
      expect(find.text('Upgrade'), findsOneWidget);

      // Hides details
      expect(find.text('Deepak Chopra'), findsNothing);
      expect(find.text('Top architect in your field'), findsNothing);
      expect(find.text('resume review'), findsNothing);
      expect(find.text('3 slots left'), findsNothing);
      expect(find.text('4.95'), findsNothing);
    });
  });

  group('DiscoverPage TabBar & Header Tests', () {
    testWidgets('renders scrollable tab bar with Own college, Free pill, Other colleges, Experts at 320dp without overflow', (tester) async {
      tester.view.physicalSize = const Size(320 * 2, 800 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: DiscoverPage(service: MockDiscoverService(mockItems: const [])),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Own college'), findsOneWidget);
      expect(find.text('Free'), findsOneWidget);
      expect(find.text('Other colleges'), findsOneWidget);
      expect(find.text('Experts'), findsOneWidget);

      // Person-plus icon button has tooltip and semantic label
      expect(find.byTooltip('Set Up Giver Profile'), findsOneWidget);
    });
  });
}
