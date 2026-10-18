// allow-mock-file: guided demo, simulated and labelled
import 'contracts.dart';
import 'demo_config.dart';

class LedgerEngineImpl implements LedgerEngine {
  final List<LedgerEntry> _entries = [];

  @override
  List<LedgerEntry> getEntries() => List.unmodifiable(_entries);

  @override
  bool verifyZeroSum() {
    if (_entries.isEmpty) return true;
    double sum = 0.0;
    for (final e in _entries) {
      sum += e.amount;
    }
    // Epsilon comparison for floating point arithmetic
    return sum.abs() < 0.0001;
  }

  double getAccountBalance(LedgerAccount account) {
    double total = 0.0;
    for (final e in _entries) {
      if (e.account == account) {
        total += e.amount;
      }
    }
    return total;
  }

  @override
  void recordCampusFreeSession({required String studentId, required String giverId}) {
    final txnId = 'txn_free_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    // Double-entry: Giver earns 1 affinity credit (+1.0), platform scholarship/affinity reserve records matching debit (-1.0)
    _entries.add(
      LedgerEntry(
        id: 'entry_${_entries.length + 1}',
        transactionId: txnId,
        account: LedgerAccount.giverEarnings,
        amount: 1.0,
        description: 'Affinity Credit earned for own-college session with student $studentId',
        timestamp: now,
      ),
    );
    _entries.add(
      LedgerEntry(
        id: 'entry_${_entries.length + 1}',
        transactionId: txnId,
        account: LedgerAccount.studentAffinityCredits,
        amount: -1.0,
        description: 'Campus Plan affinity credit utilized for campus session',
        timestamp: now,
      ),
    );
  }

  @override
  void reservePaidCredit({
    required String studentId,
    required double creditValue,
    required String planId,
  }) {
    final txnId = 'txn_res_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    // Student paid credits debited (-creditValue), Reserved Escrow credited (+creditValue)
    _entries.add(
      LedgerEntry(
        id: 'entry_${_entries.length + 1}',
        transactionId: txnId,
        account: LedgerAccount.studentPaidCredits,
        amount: -creditValue,
        description: 'Paid credit reserved for booking request (Plan $planId)',
        timestamp: now,
      ),
    );
    _entries.add(
      LedgerEntry(
        id: 'entry_${_entries.length + 1}',
        transactionId: txnId,
        account: LedgerAccount.reservedEscrow,
        amount: creditValue,
        description: 'Escrow lock pending session completion & dispute window',
        timestamp: now,
      ),
    );
  }

  @override
  void settleCreditWithBandPayout({
    required String studentId,
    required String giverId,
    required double creditValue,
    required String band,
  }) {
    final txnId = 'txn_set_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    double payoutShare;
    switch (band.toLowerCase()) {
      case 'top rated':
      case 'toprated':
        payoutShare = DemoConfig.bandTopRatedPayoutShare; // 0.80
        break;
      case 'trusted':
        payoutShare = DemoConfig.bandTrustedPayoutShare; // 0.70
        break;
      case 'rising':
      default:
        payoutShare = DemoConfig.bandRisingPayoutShare; // 0.60
        break;
    }

    final double giverAmount = creditValue * payoutShare;
    final double platformAmount = creditValue - giverAmount;

    // 1. Escrow released: -creditValue
    _entries.add(
      LedgerEntry(
        id: 'entry_${_entries.length + 1}',
        transactionId: txnId,
        account: LedgerAccount.reservedEscrow,
        amount: -creditValue,
        description: 'Escrow released upon 48h dispute window expiration',
        timestamp: now,
      ),
    );

    // 2. Giver payout: +giverAmount
    _entries.add(
      LedgerEntry(
        id: 'entry_${_entries.length + 1}',
        transactionId: txnId,
        account: LedgerAccount.giverEarnings,
        amount: giverAmount,
        description: 'Session payout to giver $giverId ($band band: ${(payoutShare * 100).round()}%)',
        timestamp: now,
      ),
    );

    // 3. Platform revenue: +platformAmount
    _entries.add(
      LedgerEntry(
        id: 'entry_${_entries.length + 1}',
        transactionId: txnId,
        account: LedgerAccount.platformRevenue,
        amount: platformAmount,
        description: 'Platform facilitation fee for cross-college routing',
        timestamp: now,
      ),
    );
  }

  @override
  void refundCredit({
    required String studentId,
    required double creditValue,
    required String reason,
  }) {
    final txnId = 'txn_ref_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    // Escrow released (-creditValue), Student paid credits restored (+creditValue)
    _entries.add(
      LedgerEntry(
        id: 'entry_${_entries.length + 1}',
        transactionId: txnId,
        account: LedgerAccount.reservedEscrow,
        amount: -creditValue,
        description: 'Escrow released due to $reason',
        timestamp: now,
      ),
    );
    _entries.add(
      LedgerEntry(
        id: 'entry_${_entries.length + 1}',
        transactionId: txnId,
        account: LedgerAccount.studentPaidCredits,
        amount: creditValue,
        description: '100% credit refund restored to student wallet ($reason)',
        timestamp: now,
      ),
    );
  }

  void activatePurchasedPlan({
    required String studentId,
    required DemoPlan plan,
  }) {
    final txnId = 'txn_buy_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    final double totalValue = plan.priceInr.toDouble();
    if (totalValue <= 0) return;

    // Student paid credits (+totalValue), Platform accounts matching offset (-totalValue)
    _entries.add(
      LedgerEntry(
        id: 'entry_${_entries.length + 1}',
        transactionId: txnId,
        account: LedgerAccount.studentPaidCredits,
        amount: totalValue,
        description: 'Simulated plan purchase: ${plan.name} (${plan.credits} credit lot)',
        timestamp: now,
      ),
    );
    _entries.add(
      LedgerEntry(
        id: 'entry_${_entries.length + 1}',
        transactionId: txnId,
        account: LedgerAccount.platformRevenue,
        amount: -totalValue,
        description: 'Unearned subscription liability lot for student $studentId',
        timestamp: now,
      ),
    );
  }
}
