// allow-mock-file: guided demo, simulated and labelled
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/personas.dart';
import '../../engine/contracts.dart';
import '../../engine/demo_config.dart';
import '../../models/demo_event_log.dart';
import '../../models/demo_models.dart';
import '../../state/demo_state.dart';

DemoChapter buildP2PlansCreditsChapter() {
  return DemoChapter(
    id: 'p2_plans_credits',
    pillarNumber: 2,
    title: 'Free Affinity & Paid Reach',
    summary:
        'Own-college alumni connections are free forever; paid plans unlock cross-college reach with a zero-sum double-entry ledger.',
    steps: [
      // Step 1: Free Affinity Connect
      DemoStep(
        title: 'Free Campus Connection',
        whatItIs:
            'Connecting with own-college alumni Arjun (sample) is free under the Campus Plan. Arjun earns an affinity credit.',
        actor: DemoActor.student,
        presenterNote:
            'Emphasize our core economic fairness rule: students never pay to connect with alumni from their own college.',
        onEnter: (log, clock) {
          log.log(
            type: 'CampusFreeConnection',
            actor: 'Student',
            description: 'Initiated free own-college session with alumnus Arjun (sample).',
            virtualTime: clock.format(),
          );
        },
        builder: (context, ref) => const _FreeAffinityStepWidget(),
      ),

      // Step 2: Locked Cross-College Access
      DemoStep(
        title: 'Locked Cross-College Giver',
        whatItIs:
            'Tapping cross-college mentor Meera (sample) shows locked status and explains the plan requirement.',
        actor: DemoActor.student,
        presenterNote:
            'Show how cross-college reach requires a plan to respect external alumni time and prevent spam.',
        builder: (context, ref) => const _LockedCrossCollegeStepWidget(),
      ),

      // Step 3: Transparent Plans & Pricing
      DemoStep(
        title: 'Transparent Plans & Guarantee',
        whatItIs:
            'Honest plans with fixed credit values, clear reach boundaries, and a 72-hour credit-back refund guarantee.',
        actor: DemoActor.student,
        presenterNote:
            'Point out the honest pricing: Rs 299 for 1 credit, Rs 499 for 2, Rs 899 for 4. No misleading "unlimited" claims.',
        builder: (context, ref) => const _PlansStepWidget(),
      ),

      // Step 4: Simulated Checkout
      DemoStep(
        title: 'Simulated Checkout Sheet',
        whatItIs:
            'Safe simulation of Razorpay payment sheet. No real cards or bank money are ever moved.',
        actor: DemoActor.student,
        presenterNote:
            'Notice the prominent simulation banner. Tapping Pay activates the subscription in the in-memory ledger.',
        builder: (context, ref) => const _SimulatedCheckoutStepWidget(),
      ),

      // Step 5: Double-Entry Ledger Proof
      DemoStep(
        title: 'Double-Entry Ledger Proof',
        whatItIs:
            'Cryptographic double-entry ledger. Every debit has an exact matching credit: live proof that sum of all entries = 0.',
        actor: DemoActor.institution,
        presenterNote:
            'Show the jury the live zero-sum proof: Sum of all debits and credits is exactly 0.00 INR.',
        builder: (context, ref) => const _LedgerProofStepWidget(),
      ),

      // Step 6: Plan Gating Matrix & Seats
      DemoStep(
        title: 'Gating Matrix & Sponsored Seats',
        whatItIs:
            'Fairness matrix showing band access per plan, and how colleges fund sponsored seats for underprivileged students.',
        actor: DemoActor.institution,
        presenterNote:
            'Explain that colleges sponsor seats so students without financial means still get cross-college reach.',
        builder: (context, ref) => const _GatingMatrixStepWidget(),
      ),
    ],
  );
}

// --- Step Widgets ---

class _FreeAffinityStepWidget extends StatelessWidget {
  const _FreeAffinityStepWidget();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFFDCFCE7),
                        child: Text('AS', style: TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Arjun (sample)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Demo University Alumnus • Software Engineer', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Free Connection', style: TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Text(
                      '• Plan Applied: Campus Plan (Free forever for Demo University students)\n'
                      '• Student Cost: Rs 0 (0 paid credits debited)\n'
                      '• Giver Reward: Arjun earns +1 Affinity Credit upon session completion\n'
                      '• Double-Entry Impact: Logged in institutional affinity ledger',
                      style: TextStyle(fontSize: 12.5, height: 1.5, color: Color(0xFF334155)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Connect for Free (Campus Affinity)'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Free campus request sent to Arjun. 0 credits debited.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedCrossCollegeStepWidget extends ConsumerWidget {
  const _LockedCrossCollegeStepWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFFF1F5F9),
                        child: Text('MS', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Meera (sample)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Sample Institute of Tech • Cloud Architect', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_rounded, size: 12, color: Color(0xFFDC2626)),
                            SizedBox(width: 4),
                            Text('Cross-College Locked', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: const Text(
                      'WHY LOCKED:\n'
                      '• Meera is an external alumna from Sample Institute of Technology (Trusted Band).\n'
                      '• Campus Plan covers own-college alumni only.\n'
                      '• Connecting across institutions requires Standard or High Plan to reserve verified session credit.',
                      style: TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFF991B1B)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.upgrade_rounded, size: 18),
                      label: const Text('View Reach Plans (Next Step)'),
                      onPressed: () {
                        // Advance to next step
                        ref.read(demoControllerProvider.notifier).nextStep();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlansStepWidget extends StatelessWidget {
  const _PlansStepWidget();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(demoControllerProvider);

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: DemoConfig.allPlans.length,
          itemBuilder: (context, index) {
            final plan = DemoConfig.allPlans[index];
            final isCurrent = state.selectedPlan.id == plan.id;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isCurrent ? const Color(0xFF1E3A8A) : const Color(0xFFE2E8F0),
                  width: isCurrent ? 2 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          plan.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Spacer(),
                        Text(
                          plan.priceInr == 0 ? 'Free' : 'Rs ${plan.priceInr}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1E3A8A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.priceInr == 0
                          ? 'Unlimited own-college connects'
                          : '${plan.credits} Credits (Rs ${(plan.priceInr / plan.credits).round()} per session lot)',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      plan.description,
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: plan.reachesBands.map((b) {
                        return Chip(
                          visualDensity: VisualDensity.compact,
                          backgroundColor: const Color(0xFFF1F5F9),
                          label: Text(b, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SimulatedCheckoutStepWidget extends StatelessWidget {
  const _SimulatedCheckoutStepWidget();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(demoControllerProvider);
        final controller = ref.read(demoControllerProvider.notifier);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309), size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Simulated Payment Modal: Razorpay test mode. No card details or money are requested.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Summary',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Text('High Plan (2 Cross-College Credits)', style: TextStyle(fontSize: 13)),
                          Spacer(),
                          Text('Rs 499.00', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const Divider(height: 20),
                      const Row(
                        children: [
                          Text('Total Payable (Simulated):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Spacer(),
                          Text('Rs 499.00', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3A8A))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            controller.purchasePlan(DemoConfig.highPlan);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('High Plan activated! 2 cross-college credits loaded to in-memory ledger.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: const Text('Simulate Successful Payment (Rs 499)', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LedgerProofStepWidget extends StatelessWidget {
  const _LedgerProofStepWidget();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(demoControllerProvider);
        final entries = state.ledgerEngine.getEntries();
        final zeroSum = state.ledgerEngine.verifyZeroSum();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: zeroSum ? const Color(0xFFDCFCE7) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: zeroSum ? const Color(0xFF86EFAC) : const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    Icon(zeroSum ? Icons.verified : Icons.error, color: zeroSum ? const Color(0xFF15803D) : Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        zeroSum
                            ? 'Double-Entry Invariant Holds: Net Sum of All Entries = 0.00 INR (Mathematically Balanced)'
                            : 'Ledger Invariant Broken: Sum != 0',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: zeroSum ? const Color(0xFF15803D) : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Active Ledger Entries (In-Memory Audit Trail):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              if (entries.isEmpty)
                const Text('No entries yet. Purchase a plan or start a session to record transactions.', style: TextStyle(fontSize: 12, color: Colors.grey))
              else
                ...entries.map((e) {
                  final isDebit = e.amount < 0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.account.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text(e.description, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        Text(
                          '${isDebit ? "" : "+"}${e.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDebit ? const Color(0xFFDC2626) : const Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _GatingMatrixStepWidget extends StatelessWidget {
  const _GatingMatrixStepWidget();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Plan Reach & Access Matrix', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          Table(
            border: TableBorder.all(color: const Color(0xFFCBD5E1)),
            columnWidths: const {
              0: FlexColumnWidth(1.2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
            },
            children: const [
              TableRow(
                decoration: BoxDecoration(color: Color(0xFFF1F5F9)),
                children: [
                  Padding(padding: EdgeInsets.all(8), child: Text('Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Rising', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Trusted', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Top Rated', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(8), child: Text('Campus (Free)', style: TextStyle(fontSize: 11.5))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Own Only', style: TextStyle(fontSize: 11, color: Color(0xFF15803D)))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Own Only', style: TextStyle(fontSize: 11, color: Color(0xFF15803D)))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Own Only', style: TextStyle(fontSize: 11, color: Color(0xFF15803D)))),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(8), child: Text('Standard (299)', style: TextStyle(fontSize: 11.5))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Unlocked', style: TextStyle(fontSize: 11, color: Color(0xFF15803D)))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Locked', style: TextStyle(fontSize: 11, color: Color(0xFFDC2626)))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Locked', style: TextStyle(fontSize: 11, color: Color(0xFFDC2626)))),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(8), child: Text('High (499)', style: TextStyle(fontSize: 11.5))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Unlocked', style: TextStyle(fontSize: 11, color: Color(0xFF15803D)))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Unlocked', style: TextStyle(fontSize: 11, color: Color(0xFF15803D)))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Locked', style: TextStyle(fontSize: 11, color: Color(0xFFDC2626)))),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(8), child: Text('Premium (899)', style: TextStyle(fontSize: 11.5))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Unlocked', style: TextStyle(fontSize: 11, color: Color(0xFF15803D)))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Unlocked', style: TextStyle(fontSize: 11, color: Color(0xFF15803D)))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Unlocked', style: TextStyle(fontSize: 11, color: Color(0xFF15803D)))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Institutional Sponsored Seats:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 6),
          const Text(
            'Colleges purchase sponsored seats for eligible scholars, giving them High Plan cross-college reach funded by campus scholarship endowments.',
            style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
          ),
        ],
      ),
    );
  }
}
