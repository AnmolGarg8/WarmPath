// Unit and widget tests for WarmPath Plans & Wallet feature.
// Tests plan card models, subscription polling controller state machine,
// wallet ledger plain language formatting, money formatting, earnings shares,
// CTA states, sponsored seat claims, and credit cost widgets.
// Owner: M4

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warmpath_app/features/plans_wallet/plans_wallet.dart';

void main() {
  group('Money & Window Formatting Tests', () {
    test('formatInr formats in Indian Rupees with Rs prefix and comma grouping', () {
      expect(formatInr(0), 'Rs 0');
      expect(formatInr(299), 'Rs 299');
      expect(formatInr(1200), 'Rs 1,200');
      expect(formatInr(50000), 'Rs 50,000');
      expect(formatInr(100000), 'Rs 1,00,000');
      expect(formatInr(250.50), 'Rs 250.50');
    });

    test('formatWindowMinutes formats hours and minutes cleanly', () {
      expect(formatWindowMinutes(2880), '48 hours');
      expect(formatWindowMinutes(120), '2 hours');
      expect(formatWindowMinutes(60), '1 hour');
      expect(formatWindowMinutes(2), '2 minutes');
      expect(formatWindowMinutes(1), '1 minute');
      expect(formatWindowMinutes(0), '0 minutes');
    });
  });

  group('PlanModel Tests', () {
    test('Default plans contains Campus, Standard, High, and Premium with honest claims', () {
      final plans = PlanModel.defaultPlans();
      expect(plans.length, 4);

      final codes = plans.map((p) => p.code).toList();
      expect(codes, containsAll(['campus', 'standard', 'high', 'premium']));

      final campus = plans.firstWhere((p) => p.code == 'campus');
      expect(campus.isFree, isTrue);
      expect(campus.priceInr, 0);
      expect(campus.plainReach, contains('Own college alumni only'));

      final standard = plans.firstWhere((p) => p.code == 'standard');
      expect(standard.priceInr, 299);
      expect(standard.creditsPerMonth, 1);
      expect(standard.plainReach, contains('Rising alumni mentors'));

      final high = plans.firstWhere((p) => p.code == 'high');
      expect(high.priceInr, 499);
      expect(high.creditsPerMonth, 2);
      expect(high.plainReach, contains('Rising & Trusted'));

      final premium = plans.firstWhere((p) => p.code == 'premium');
      expect(premium.priceInr, 899);
      expect(premium.creditsPerMonth, 4);
      expect(premium.plainPriority, contains("Higher priority in mentors' inboxes"));
    });

    test('PlanModel.fromJson handles missing or partial fields gracefully', () {
      final plan = PlanModel.fromJson({
        'code': 'Standard',
        'name': 'Standard Tier',
        'price_inr': 299,
        'credits_per_month': 1,
      });

      expect(plan.code, 'standard');
      expect(plan.name, 'Standard Tier');
      expect(plan.priceInr, 299);
      expect(plan.creditsPerMonth, 1);
      expect(plan.active, isTrue);
    });
  });

  group('PlanCard CTA States & Copy Tests', () {
    final standardPlan = const PlanModel(
      id: 'plan_std',
      code: 'standard',
      name: 'Standard Plan',
      priceInr: 299,
      creditsPerMonth: 1,
      reachBands: ['Rising'],
      bookingHorizonDays: 3,
      priority: 1,
      features: ['1 cross-college credit/month'],
      active: true,
    );

    testWidgets('Renders Current plan button when isCurrentPlan is true and button is disabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlanCard(
              plan: standardPlan,
              isCurrentPlan: true,
              currentPlanPriority: 1,
            ),
          ),
        ),
      );

      expect(find.text('Current plan'), findsOneWidget);
      expect(find.text('CURRENT PLAN'), findsOneWidget);
      expect(find.text('Rs 299'), findsOneWidget);
      expect(find.text('Credit returned if no reply in 72 hours'), findsOneWidget);
    });

    testWidgets('Renders Upgrade button when plan.priority > currentPlanPriority', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlanCard(
              plan: standardPlan,
              isCurrentPlan: false,
              currentPlanPriority: 0, // currently on Campus (priority 0)
            ),
          ),
        ),
      );

      expect(find.text('Upgrade'), findsOneWidget);
    });

    testWidgets('Renders Downgrade button when plan.priority < currentPlanPriority', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlanCard(
              plan: standardPlan,
              isCurrentPlan: false,
              currentPlanPriority: 2, // currently on High (priority 2)
            ),
          ),
        ),
      );

      expect(find.text('Downgrade'), findsOneWidget);
    });
  });

  group('SubscriptionPollingController Tests', () {
    test('Initial state is idle', () {
      final controller = SubscriptionPollingController();
      expect(controller.status, PollingStatus.idle);
      expect(controller.attempts, 0);
      expect(controller.activatedSubscription, isNull);
    });

    test('Polling controller succeeds when target plan becomes active', () async {
      final controller = SubscriptionPollingController(
        pollInterval: const Duration(milliseconds: 10),
        maxAttempts: 5,
      );

      int callCount = 0;
      Future<UserSubscriptionModel?> mockFetch() async {
        callCount++;
        if (callCount < 2) {
          return const UserSubscriptionModel(
            planCode: 'campus',
            planName: 'Campus Free',
            status: 'active',
            creditsLeft: 0,
            active: true,
          );
        }
        return const UserSubscriptionModel(
          planCode: 'high',
          planName: 'High Plan',
          status: 'active',
          creditsLeft: 2,
          active: true,
        );
      }

      bool activatedCallbackFired = false;
      await controller.startPolling(
        fetchSubscription: mockFetch,
        targetPlanCode: 'high',
        onActivated: () => activatedCallbackFired = true,
      );

      expect(controller.status, PollingStatus.active);
      expect(controller.attempts, 2);
      expect(controller.activatedSubscription?.planCode, 'high');
      expect(controller.activatedSubscription?.creditsLeft, 2);
      expect(activatedCallbackFired, isTrue);
    });

    test('Polling controller transitions to timeout after max attempts', () async {
      final controller = SubscriptionPollingController(
        pollInterval: const Duration(milliseconds: 10),
        maxAttempts: 3,
      );

      Future<UserSubscriptionModel?> mockFetch() async {
        return const UserSubscriptionModel(
          planCode: 'campus',
          planName: 'Campus Free',
          status: 'active',
          creditsLeft: 0,
          active: true,
        );
      }

      bool timeoutCallbackFired = false;
      await controller.startPolling(
        fetchSubscription: mockFetch,
        targetPlanCode: 'standard',
        onTimeout: () => timeoutCallbackFired = true,
      );

      expect(controller.status, PollingStatus.timeout);
      expect(controller.attempts, 3);
      expect(controller.statusMessage, contains('Payment pending'));
      expect(timeoutCallbackFired, isTrue);
    });

    test('Cancellation stops polling immediately', () async {
      final controller = SubscriptionPollingController(
        pollInterval: const Duration(milliseconds: 50),
        maxAttempts: 10,
      );

      controller.cancel();
      expect(controller.status, PollingStatus.idle);
    });
  });

  group('Wallet & LedgerEntryModel Tests', () {
    test('LedgerEntry formats reservations with negative sign and correct copy', () {
      final reserveEntry = const LedgerEntryModel(
        id: '1',
        txnId: '00000000-0000-0000-0000-0000000000a1',
        amountCredits: 1,
        amountInr: 250,
        direction: 'out',
        reason: 'reserve',
      );
      expect(reserveEntry.plainReason, 'Reserved for a session: -1 credit');
      expect(reserveEntry.displayCredits, '-1 Credit');
      expect(reserveEntry.isPositive, isFalse);
      expect(reserveEntry.shortTxnId, '000000a1');
    });

    test('LedgerEntry formats refunds and grants with positive sign', () {
      final refundEntry = const LedgerEntryModel(
        id: '2',
        txnId: '00000000-0000-0000-0000-0000000000b2',
        amountCredits: 1,
        amountInr: 250,
        direction: 'in',
        reason: 'refund',
        notes: 'Giver did not reply in 72 hours',
      );
      expect(refundEntry.plainReason, contains('Giver did not reply in 72 hours'));
      expect(refundEntry.displayCredits, '+1 Credit');
      expect(refundEntry.isPositive, isTrue);
      expect(refundEntry.shortTxnId, '000000b2');

      final donateEntry = const LedgerEntryModel(
        id: '3',
        txnId: '00000000-0000-0000-0000-0000000000c3',
        amountCredits: 2,
        amountInr: 500,
        direction: 'out',
        reason: 'donate',
      );
      expect(donateEntry.plainReason, 'Donated to student scholarship pool');
      expect(donateEntry.displayCredits, '-2 Credits');
    });

    test('WalletModel computes running balances for ledger entries', () {
      final wallet = WalletModel.fromJson({
        'available_credits': 3,
        'affinity_credits': 1,
        'total_credits': 4,
        'items': [
          {
            'id': 'ent_1',
            'txn_id': '00000000-0000-0000-0000-000000000001',
            'amount_credits': 2,
            'direction': 'in',
            'reason': 'grant',
          },
          {
            'id': 'ent_2',
            'txn_id': '00000000-0000-0000-0000-000000000002',
            'amount_credits': 1,
            'direction': 'out',
            'reason': 'reserve',
          },
        ],
      });

      expect(wallet.paidCredits, 3);
      expect(wallet.affinityCredits, 1);
      expect(wallet.totalCredits, 4);
      expect(wallet.ledger.length, 2);

      // Latest entry has current total balance (4)
      expect(wallet.ledger[0].runningBalance, 4);
      // Entry before was balance before the grant (4 - 2 = 2)
      expect(wallet.ledger[1].runningBalance, 2);
    });

    testWidgets('LedgerEntryTile displays short Txn ID and running balance', (tester) async {
      const entry = LedgerEntryModel(
        id: '1',
        txnId: '12345678-1234-1234-1234-abcdef123456',
        amountCredits: 1,
        amountInr: 250,
        direction: 'out',
        reason: 'reserve',
        runningBalance: 3,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LedgerEntryTile(entry: entry),
          ),
        ),
      );

      expect(find.text('Txn: ef123456'), findsOneWidget);
      expect(find.text('Bal: 3 cr'), findsOneWidget);
      expect(find.text('-1 Credit'), findsOneWidget);
      expect(find.textContaining('#txn_'), findsNothing);
    });
  });

  group('EarningsModel Tests', () {
    test('Rating band shares match 60%, 70%, 80% progression', () {
      final rising = EarningsModel.fromJson({
        'available_inr': 100,
        'rating_band': 'Rising',
      });
      expect(rising.payoutSharePct, 60);
      expect(rising.plainRatingBandShare, contains('60% payout share'));

      final trusted = EarningsModel.fromJson({
        'available_inr': 700,
        'rating_band': 'Trusted',
      });
      expect(trusted.payoutSharePct, 70);
      expect(trusted.plainRatingBandShare, contains('70% payout share'));

      final topRated = EarningsModel.fromJson({
        'available_inr': 1600,
        'rating_band': 'Top Rated',
      });
      expect(topRated.payoutSharePct, 80);
      expect(topRated.plainRatingBandShare, contains('80% payout share'));
      expect(topRated.canCashout, isTrue);
    });

    test('canCashout returns false when availableInr is zero', () {
      final emptyEarnings = EarningsModel.empty();
      expect(emptyEarnings.canCashout, isFalse);
    });
  });

  group('SponsoredSeatModel Tests', () {
    test('SponsoredSeatModel parses canClaim and credits properly', () {
      final seat = SponsoredSeatModel.fromJson({
        'id': 'seat_1',
        'sponsor_name': 'VIPS Alumni Fund',
        'funded_by': 'institution_grant',
        'status': 'available',
        'credits_granted': 2,
        'credits_remaining': 2,
        'can_claim': true,
      });

      expect(seat.id, 'seat_1');
      expect(seat.institutionName, 'VIPS Alumni Fund');
      expect(seat.canClaim, isTrue);
      expect(seat.creditsRemaining, 2);
      expect(seat.creditsGranted, 2);
    });
  });

  group('CreditCostSummaryWidget Tests', () {
    testWidgets('Renders 0 credits and FREE ON CAMPUS for own-college alumni', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CreditCostSummaryWidget(
              giverName: 'Aarav Mehta',
              giverBand: 'Trusted',
              isOwnCollege: true,
              availableCredits: 0,
            ),
          ),
        ),
      );

      expect(find.text('0 Credits'), findsOneWidget);
      expect(find.text('FREE ON CAMPUS'), findsOneWidget);
      expect(find.textContaining('100% free because you share the same alma mater'), findsOneWidget);
      expect(find.byIcon(Icons.school), findsOneWidget);
    });

    testWidgets('Renders credit requirement and balance for cross-college alumni', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CreditCostSummaryWidget(
              giverName: 'Ananya Roy',
              giverBand: 'Top Rated',
              isOwnCollege: false,
              availableCredits: 2,
            ),
          ),
        ),
      );

      expect(find.text('1 Cross-College Credit'), findsOneWidget);
      expect(find.textContaining('Wallet balance: 2 credit(s) available.'), findsOneWidget);
      expect(find.text('Upgrade'), findsNothing);
    });

    testWidgets('Shows Upgrade button when user has 0 credits for cross-college connect', (tester) async {
      bool upgradeClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CreditCostSummaryWidget(
              giverName: 'Vikram Seth',
              giverBand: 'Rising',
              isOwnCollege: false,
              availableCredits: 0,
              onUpgradeTap: () => upgradeClicked = true,
            ),
          ),
        ),
      );

      expect(find.text('Upgrade'), findsOneWidget);
      await tester.tap(find.text('Upgrade'));
      expect(upgradeClicked, isTrue);
    });
  });
}
