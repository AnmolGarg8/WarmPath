import 'package:flutter_test/flutter_test.dart';
import 'package:warmpath_app/features/demo/engine/contracts.dart';
import 'package:warmpath_app/features/demo/engine/demo_config.dart';
import 'package:warmpath_app/features/demo/engine/ledger_engine_impl.dart';

void main() {
  group('LedgerEngine Double-Entry Tests (Pillar 2)', () {
    test('Zero-sum invariant holds across sequence of plan purchase, reservation, settlement, and refund', () {
      final ledger = LedgerEngineImpl();
      expect(ledger.verifyZeroSum(), isTrue);

      // 1. Plan purchase: High plan Rs 499
      ledger.activatePurchasedPlan(
        studentId: 'student_1',
        plan: DemoConfig.highPlan,
      );
      expect(ledger.verifyZeroSum(), isTrue);

      // 2. Reserve credit for session (unit value 249.50)
      ledger.reservePaidCredit(
        studentId: 'student_1',
        creditValue: DemoConfig.highPlan.creditUnitValueInr,
        planId: DemoConfig.highPlan.id,
      );
      expect(ledger.verifyZeroSum(), isTrue);

      // 3. Settle session with Trusted band (70% to giver, 30% to platform)
      ledger.settleCreditWithBandPayout(
        studentId: 'student_1',
        giverId: 'giver_1',
        creditValue: DemoConfig.highPlan.creditUnitValueInr,
        band: 'trusted',
      );
      expect(ledger.verifyZeroSum(), isTrue);

      // 4. Reserve and Refund another credit
      ledger.reservePaidCredit(
        studentId: 'student_1',
        creditValue: DemoConfig.highPlan.creditUnitValueInr,
        planId: DemoConfig.highPlan.id,
      );
      expect(ledger.verifyZeroSum(), isTrue);

      ledger.refundCredit(
        studentId: 'student_1',
        creditValue: DemoConfig.highPlan.creditUnitValueInr,
        reason: 'Giver No-Show',
      );
      expect(ledger.verifyZeroSum(), isTrue);

      // 5. Campus free session (Affinity credit)
      ledger.recordCampusFreeSession(
        studentId: 'student_1',
        giverId: 'campus_giver_1',
      );
      expect(ledger.verifyZeroSum(), isTrue);
    });

    test('Plan credit lot unit values are exact', () {
      // Standard: 299 / 1 = 299.0
      expect(DemoConfig.standardPlan.creditUnitValueInr, 299.0);

      // High: 499 / 2 = 249.50
      expect(DemoConfig.highPlan.creditUnitValueInr, 249.5);

      // Premium: 899 / 4 = 224.75
      expect(DemoConfig.premiumPlan.creditUnitValueInr, 224.75);
    });

    test('Settlement payout shares distribute mathematically exact amounts', () {
      final ledger = LedgerEngineImpl();
      const double creditVal = 200.0;

      // Top Rated (80%): giver earns 160, platform earns 40
      ledger.settleCreditWithBandPayout(
        studentId: 's',
        giverId: 'g',
        creditValue: creditVal,
        band: 'top rated',
      );

      final giverEarnings = ledger.getAccountBalance(LedgerAccount.giverEarnings);
      final platformRev = ledger.getAccountBalance(LedgerAccount.platformRevenue);

      expect(giverEarnings, 160.0);
      expect(platformRev, 40.0);
      expect(ledger.verifyZeroSum(), isTrue);
    });
  });
}
