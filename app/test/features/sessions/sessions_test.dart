import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warmpath_app/features/sessions/sessions_page.dart';
import 'package:warmpath_app/features/sessions/inbox_page.dart';
import 'package:warmpath_app/features/sessions/session_models.dart';
import 'package:warmpath_app/features/sessions/sessions_api_service.dart';
import 'package:warmpath_app/features/sessions/sessions_error_helper.dart';
import '../../test_helpers.dart';

class MockSessionsApiService extends SessionsApiService {
  final List<CallSession> mockSessions;
  final List<MentorshipRequest> incomingRequests;
  final List<MentorshipRequest> outgoingRequests;

  MockSessionsApiService({
    this.mockSessions = const [],
    this.incomingRequests = const [],
    this.outgoingRequests = const [],
  });

  @override
  Future<List<CallSession>> listMySessions() async => mockSessions;

  @override
  Future<List<MentorshipRequest>> listRequests({
    String box = 'incoming',
    String? status,
    String? cursor,
  }) async {
    if (box == 'incoming') return incomingRequests;
    return outgoingRequests;
  }
}

void main() {
  group('Credit Disclosure Tests', () {
    test('discloses 0 credits for own college', () {
      final text = getCreditDisclosureText(isOwnCollege: true, planName: 'Campus');
      expect(text, contains('Free: own college network'));
      expect(text, contains('0 credits'));
    });

    test('discloses paid credit for cross college', () {
      final text = getCreditDisclosureText(isOwnCollege: false, planName: 'Standard', cost: 1);
      expect(text, contains('uses 1 credit'));
      expect(text, contains('Standard'));
    });
  });

  group('Session Error Translation Tests', () {
    test('translates known typed errors into clear human messages', () {
      expect(
        translateSessionError('giver_at_capacity'),
        contains('reached their weekly session limit'),
      );
      expect(
        translateSessionError('slot_already_booked'),
        contains('already been taken'),
      );
      expect(
        translateSessionError('plan_access_denied'),
        contains('does not grant cross-college access'),
      );
      expect(
        translateSessionError('intent_blocked'),
        contains('flagged by trust & safety filters'),
      );
      expect(
        translateSessionError('session_not_open'),
        contains('Video calls open 10 minutes before'),
      );
      expect(
        translateSessionError('rating_window_expired'),
        contains('ratings must be submitted within 14 days'),
      );
    });

    test('falls back on unknown code', () {
      expect(translateSessionError('custom_error', 'Fallback error message'), 'Fallback error message');
    });
  });

  group('SessionsPage Widget Tests', () {
    testWidgets('renders counterpart identity, join window states, and rating eligibility without unescaped templates',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final now = DateTime.now();

      // Session 1: Far future (> 10 min away) -> join button disabled with opens hint
      final futureSession = CallSession(
        id: 's-future',
        requestId: 'req-1',
        studentId: 'stud-1',
        giverId: 'giver-1',
        scheduledAt: now.add(const Duration(hours: 2)),
        durationMinutes: 30,
        roomUrl: 'https://meet.jit.si/warmpath-s-future',
        status: 'scheduled',
        topic: 'Resume Review & System Design',
        counterpart: CounterpartSummary(
          id: 'giver-1',
          displayName: 'Priya Sen',
          headline: 'Staff Engineer at Swiggy',
          role: 'Giver',
          badges: ['IIT Delhi \'20', 'Top Mentor'],
          band: 'Top Rated',
        ),
      );

      // Session 2: Within 10 min join window -> join button enabled
      final joinableSession = CallSession(
        id: 's-imminent',
        requestId: 'req-2',
        studentId: 'stud-1',
        giverId: 'giver-2',
        scheduledAt: now.add(const Duration(minutes: 5)),
        durationMinutes: 45,
        status: 'scheduled',
        roomUrl: 'https://meet.jit.si/warmpath-s-imminent',
        topic: 'Backend Architecture Walkthrough',
        counterpart: CounterpartSummary(
          id: 'giver-2',
          displayName: 'Vikram Malhotra',
          headline: 'VP Engineering',
          role: 'Giver',
          badges: ['BITS Pilani'],
          band: 'Trusted',
        ),
      );

      // Session 3: Completed session for Student, unrated within 14 days -> Rate session button
      final completedUnratedStudent = CallSession(
        id: 's-completed-unrated',
        requestId: 'req-3',
        studentId: 'stud-1',
        giverId: 'giver-3',
        scheduledAt: now.subtract(const Duration(days: 2)),
        durationMinutes: 30,
        roomUrl: 'https://meet.jit.si/warmpath-s-completed-1',
        status: 'completed',
        topic: 'Career Transition Advice',
        counterpart: CounterpartSummary(
          id: 'giver-3',
          displayName: 'Arjun Das',
          headline: 'Founder @ AI Startup',
          role: 'Giver',
          badges: [],
          band: 'Rising',
        ),
      );

      // Session 4: Completed session for Student, already rated 4 stars -> "You rated 4 stars"
      final completedRatedStudent = CallSession(
        id: 's-completed-rated',
        requestId: 'req-4',
        studentId: 'stud-1',
        giverId: 'giver-4',
        scheduledAt: now.subtract(const Duration(days: 3)),
        durationMinutes: 20,
        roomUrl: 'https://meet.jit.si/warmpath-s-completed-2',
        status: 'completed',
        topic: 'Interview Prep',
        studentRatingStars: 4,
        counterpart: CounterpartSummary(
          id: 'giver-4',
          displayName: 'Neha Sharma',
          headline: 'Tech Lead @ Razorpay',
          role: 'Giver',
          badges: ['Razorpay'],
          band: 'Top Rated',
        ),
      );

      // Session 5: Completed session where current user is Giver -> "Rate request quality"
      final completedGiverView = CallSession(
        id: 's-completed-giver',
        requestId: 'req-5',
        studentId: 'stud-2',
        giverId: 'giver-me',
        scheduledAt: now.subtract(const Duration(days: 1)),
        durationMinutes: 30,
        roomUrl: 'https://meet.jit.si/warmpath-s-completed-3',
        status: 'completed',
        topic: 'Frontend Portfolio Critique',
        giverRatedQuality: false,
        counterpart: CounterpartSummary(
          id: 'stud-2',
          displayName: 'Rahul Verma',
          headline: 'Pre-final Year B.Tech',
          role: 'Student',
          badges: ['DTU \'25'],
        ),
      );

      final mockService = MockSessionsApiService(
        mockSessions: [
          futureSession,
          joinableSession,
          completedUnratedStudent,
          completedRatedStudent,
          completedGiverView,
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionsApiServiceProvider.overrideWithValue(mockService),
          ],
          child: const MaterialApp(
            home: SessionsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Template Safety Test
      expectNoUnescapedTemplates(tester);

      // 2. Counterpart Identity Rendering
      expect(find.text('Priya Sen'), findsOneWidget);
      expect(find.text('Staff Engineer at Swiggy'), findsOneWidget);
      expect(find.text('IIT Delhi \'20'), findsOneWidget);
      expect(find.text('Resume Review & System Design'), findsOneWidget);
      expect(find.text('30 mins'), findsWidgets);
      expect(find.text('PS'), findsOneWidget); // Initials avatar

      expect(find.text('Vikram Malhotra'), findsOneWidget);
      expect(find.text('VM'), findsOneWidget);
      expect(find.text('Backend Architecture Walkthrough'), findsOneWidget);
      expect(find.text('45 mins'), findsOneWidget);

      expect(find.text('Rahul Verma'), findsOneWidget);
      expect(find.text('Student'), findsWidgets);
      expect(find.text('Pre-final Year B.Tech'), findsOneWidget);
      expect(find.text('DTU \'25'), findsOneWidget);

      // 3. Join Window Button Verification
      // Future session (> 10 min away): Shows disabled "Opens 10 minutes before the start"
      expect(find.text('Opens 10 minutes before the start'), findsOneWidget);

      // Imminent session (5 min away): Shows enabled "Join Video Call"
      expect(find.text('Join Video Call'), findsOneWidget);

      // 4. Rating Eligibility Verification
      // Completed unrated session for student: "Rate session"
      expect(find.text('Rate session'), findsOneWidget);

      // Completed already-rated session for student: "You rated 4 stars"
      expect(find.text('You rated 4 stars'), findsOneWidget);

      // Completed session for giver: "Rate request quality"
      expect(find.text('Rate request quality'), findsOneWidget);

      // Verify generic "Leave Feedback / Review" button is nowhere to be found
      expect(find.text('Leave Feedback / Review'), findsNothing);
      expect(find.text('Leave Feedback'), findsNothing);
      expect(find.text('Leave Review'), findsNothing);
    });
  });

  group('InboxPage Widget Tests', () {
    testWidgets('renders requester identity, priority explanation, giver earnings, and status timeline without unescaped templates',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final now = DateTime.now();

      final incoming1 = MentorshipRequest(
        id: 'req-in-1',
        studentId: 'stud-1',
        giverId: 'giver-me',
        kind: 'scheduled',
        intentText: 'Seeking advice on cracking senior engineer interviews at tier-1 product companies.',
        priority: 2,
        status: 'pending',
        createdAt: now.subtract(const Duration(minutes: 25)),
        giverEarningsText: 'You earn Rs 175 if completed',
        counterpart: CounterpartSummary(
          id: 'stud-1',
          displayName: 'Ananya Gupta',
          headline: 'SDE-1 at FinTech',
          role: 'Student',
          badges: ['Top Contributor', 'Alumni Network'],
        ),
      );

      final incoming2 = MentorshipRequest(
        id: 'req-in-2',
        studentId: 'stud-2',
        giverId: 'giver-me',
        kind: 'scheduled',
        intentText: 'College campus mentorship inquiry on open source contribution.',
        priority: 1,
        status: 'pending',
        createdAt: now.subtract(const Duration(hours: 1)),
        giverEarningsText: 'Free campus session, you earn 1 affinity credit',
        counterpart: CounterpartSummary(
          id: 'stud-2',
          displayName: 'Devansh Roy',
          headline: 'Junior Year CS',
          role: 'Student',
          badges: ['NIT Trichy \'26'],
        ),
      );

      final outgoing1 = MentorshipRequest(
        id: 'req-out-1',
        studentId: 'stud-me',
        giverId: 'giver-10',
        kind: 'scheduled',
        intentText: 'Distributed systems guidance and portfolio review.',
        priority: 2,
        status: 'accepted',
        createdAt: now.subtract(const Duration(days: 1)),
        slotStart: now.add(const Duration(days: 1)),
        counterpart: CounterpartSummary(
          id: 'giver-10',
          displayName: 'Karan Mehra',
          headline: 'Distinguished Architect',
          role: 'Giver',
          badges: ['Ex-Amazon'],
          band: 'Top Rated',
        ),
      );

      final mockService = MockSessionsApiService(
        incomingRequests: [incoming1, incoming2],
        outgoingRequests: [outgoing1],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionsApiServiceProvider.overrideWithValue(mockService),
          ],
          child: const MaterialApp(
            home: InboxPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Template Safety Test
      expectNoUnescapedTemplates(tester);

      // 2. Requester Identity & Badges
      expect(find.text('Ananya Gupta'), findsOneWidget);
      expect(find.text('SDE-1 at FinTech'), findsOneWidget);
      expect(find.text('Top Contributor'), findsOneWidget);
      expect(find.text('Devansh Roy'), findsOneWidget);
      expect(find.text('NIT Trichy \'26'), findsOneWidget);

      // 3. Priority Explanation (not bare HIGH)
      expect(find.text('Priority: High • 2x response odds'), findsOneWidget);
      expect(find.text('Priority: Standard'), findsOneWidget);

      // 4. Giver Earnings Text
      expect(find.text('You earn Rs 175 if completed'), findsOneWidget);
      expect(find.text('Free campus session, you earn 1 affinity credit'), findsOneWidget);

      // 5. Action Buttons
      expect(find.text('Accept'), findsNWidgets(2));
      expect(find.text('Decline'), findsNWidgets(2));

      // 6. Switch to Outgoing Tab
      await tester.tap(find.text('Outgoing (Student)'));
      await tester.pumpAndSettle();

      expectNoUnescapedTemplates(tester);
      expect(find.text('Karan Mehra'), findsOneWidget);
      expect(find.text('Distinguished Architect'), findsOneWidget);
      expect(find.text('Ex-Amazon'), findsOneWidget);
      expect(find.text('Open chat'), findsOneWidget);
      expect(find.text('Accepted'), findsWidgets);
    });
  });
}
