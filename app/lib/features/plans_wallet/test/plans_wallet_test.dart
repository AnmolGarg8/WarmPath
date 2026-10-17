/// Unit and widget tests for WarmPath Plans & Wallet feature.
/// Tests plan card models, subscription polling controller state machine,
/// wallet ledger plain language formatting, earnings shares, and credit cost widgets.
/// Owner: M4

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warmpath_app/features/plans_wallet/plans_wallet.dart';

void main() {
  group('PlanModel Tests', () {
    test('Default plans contains Campus, Standard, High, and Premium', () {
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
      expect(premium.plainPriority, contains('VIP Priority'));
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

      // Backend still shows campus (webhook hasn't processed yet)
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
    test('LedgerEntry formats plain language descriptions correctly', () {
      final reserveEntry = const LedgerEntryModel(
        id: '1',
        txnId: 'txn_1',
        amountCredits: 1,
        amountInr: 250,
        direction: 'out',
        reason: 'reserve',
      );
      expect(reserveEntry.plainReason, 'Reserved for mentorship session');
      expect(reserveEntry.displayCredits, '-1 Credit');
      expect(reserveEntry.isPositive, isFalse);

      final refundEntry = const LedgerEntryModel(
        id: '2',
        txnId: 'txn_2',
        amountCredits: 1,
        amountInr: 250,
        direction: 'in',
        reason: 'refund',
        notes: 'Giver did not reply in 72 hours',
      );
      expect(refundEntry.plainReason, contains('Refunded: Giver did not reply in 72 hours'));
      expect(refundEntry.displayCredits, '+1 Credit');
      expect(refundEntry.isPositive, isTrue);

      final donateEntry = const LedgerEntryModel(
        id: '3',
        txnId: 'txn_3',
        amountCredits: 2,
        amountInr: 500,
        direction: 'out',
        reason: 'donate',
      );
      expect(donateEntry.plainReason, 'Donated to student scholarship pool');
      expect(donateEntry.displayCredits, '-2 Credits');
    });

    test('WalletModel correctly sums credits from entries', () {
      final wallet = WalletModel.fromJson({
        'paid_credits': 3,
        'affinity_credits': 2,
        'total_credits': 5,
        'ledger': [
          {
            'id': 'ent_1',
            'txn_id': 'txn_10',
            'amount_credits': 3,
            'direction': 'in',
            'reason': 'purchase',
          }
        ],
      });

      expect(wallet.paidCredits, 3);
      expect(wallet.affinityCredits, 2);
      expect(wallet.totalCredits, 5);
      expect(wallet.ledger.length, 1);
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
