// allow-mock-file: guided demo, simulated and labelled
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../framework/reality_status.dart';
import '../../models/demo_event_log.dart';
import '../../models/demo_models.dart';
import '../../state/demo_state.dart';

DemoChapter buildFinaleChapter() {
  return DemoChapter(
    id: 'finale',
    pillarNumber: 7,
    title: 'The Loop & Reality Check',
    summary:
        'The closed-loop architecture connecting all six pillars, stakeholder outcomes, and transparent verification status.',
    steps: [
      // Step 1: The Loop Interactive Diagram
      DemoStep(
        title: 'The Closed Loop Architecture',
        whatItIs:
            'Interactive diagram showing how each pillar feeds the next, creating a self-reinforcing campus network.',
        actor: DemoActor.institution,
        presenterNote:
            'Walk through the arrows: Matching -> Connect -> Rating -> Bands -> Trust -> Analytics -> Recruitment -> Matching.',
        builder: (context, ref) => const _TheLoopStepWidget(),
      ),

      // Step 2: What Each Stakeholder Gets
      DemoStep(
        title: 'What Each Stakeholder Gets',
        whatItIs:
            'Concrete outcomes for Student, Giver, Recruiter, Faculty, Institution, and Platform from this walkthrough.',
        actor: DemoActor.student,
        presenterNote:
            'Highlight our dual-sided alignment: Students get free affinity and protected reach; Givers get fair compensation without spam.',
        builder: (context, ref) => const _StakeholderOutcomesStepWidget(),
      ),

      // Step 3: What Is Live vs What Is Simulated
      DemoStep(
        title: 'What is Live vs Simulated',
        whatItIs:
            'Honest verification status driven by reality_status.dart and docs/VERIFICATION.md. Complete transparency.',
        actor: DemoActor.institution,
        presenterNote:
            'Close the demo with total honesty: "Here is what passed our backend automated tests today, and here is what was simulated in this walkthrough."',
        builder: (context, ref) => const _RealityCheckStepWidget(),
      ),
    ],
  );
}

// --- Step Widgets ---

class _TheLoopStepWidget extends StatefulWidget {
  const _TheLoopStepWidget();

  @override
  State<_TheLoopStepWidget> createState() => _TheLoopStepWidgetState();
}

class _TheLoopStepWidgetState extends State<_TheLoopStepWidget> {
  int activeNodeIndex = 0;

  final List<Map<String, String>> loopNodes = [
    {
      'title': '1. Matching Engine',
      'caption': 'Sends the right student to a giver with verified skills & open weekly capacity.',
      'icon': 'search',
    },
    {
      'title': '2. Capacity Connect',
      'caption': 'Creates a protected session room with 5-min mutual presence check and escrow lock.',
      'icon': 'video_call',
    },
    {
      'title': '3. Rating Smoothing',
      'caption': 'Post-session rating updates smoothed average via Bayesian formula (m=5, prior=4.0).',
      'icon': 'star',
    },
    {
      'title': '4. Band Progression',
      'caption': 'Smoothed score promotes giver to Trusted or Top Rated, unlocking higher payout shares (60/70/80%).',
      'icon': 'workspace_premium',
    },
    {
      'title': '5. Trust & Moderation',
      'caption': 'Protects every connection with automated scam detection, contact masking, and 24h SLA review.',
      'icon': 'shield',
    },
    {
      'title': '6. Institution Analytics',
      'caption': 'Reads the event log, reveals skill shortages (e.g. Cloud), and targets who to recruit next.',
      'icon': 'analytics',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'The WarmPath Self-Reinforcing Loop:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          ...List.generate(loopNodes.length, (idx) {
            final node = loopNodes[idx];
            final isActive = idx == activeNodeIndex;

            return GestureDetector(
              onTap: () => setState(() => activeNodeIndex = idx),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFEFF6FF) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive ? const Color(0xFF1E3A8A) : const Color(0xFFE2E8F0),
                    width: isActive ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: isActive ? const Color(0xFF1E3A8A) : const Color(0xFFE2E8F0),
                      child: Text(
                        '${idx + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.white : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(node['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(node['caption']!, style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StakeholderOutcomesStepWidget extends StatelessWidget {
  const _StakeholderOutcomesStepWidget();

  @override
  Widget build(BuildContext context) {
    final outcomes = [
      {
        'role': 'Student (Riya)',
        'color': const Color(0xFF1E3A8A),
        'icon': Icons.school_rounded,
        'points': [
          'Free forever access to own-college alumni mentors via Campus plan',
          'Protected cross-college access with 100% refund guarantee on no-shows',
        ],
      },
      {
        'role': 'Giver (Arjun)',
        'color': const Color(0xFF0F766E),
        'icon': Icons.person_rounded,
        'points': [
          'Weekly capacity caps that eliminate spam flooding and calendar exhaustion',
          'Honest rating-based earnings (60% to 80% payout shares) backed by escrow',
        ],
      },
      {
        'role': 'Recruiter (Sarah)',
        'color': const Color(0xFF4338CA),
        'icon': Icons.business_center_rounded,
        'points': [
          'Direct access to pre-verified technical candidates with audited skill portfolios',
          'High-signal 20-minute portfolio reviews replacing cold LinkedIn messaging',
        ],
      },
      {
        'role': 'Institution (Prof. Raman)',
        'color': const Color(0xFFB45309),
        'icon': Icons.account_balance_rounded,
        'points': [
          'Actionable skill-gap intelligence guiding curriculum and alumni recruitment',
          'Zero-liability student safety with automated payment scam and contact shielding',
        ],
      },
      {
        'role': 'Platform (WarmPath)',
        'color': const Color(0xFF15803D),
        'icon': Icons.hub_rounded,
        'points': [
          'Sustainable economics via fair cross-college facilitation fees (20% to 40%)',
          'Cryptographic double-entry ledger that balances to zero across all transactions',
        ],
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: outcomes.length,
      itemBuilder: (context, index) {
        final item = outcomes[index];
        final color = item['color'] as Color;
        final points = item['points'] as List<String>;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(item['icon'] as IconData, color: color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      item['role'] as String,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...points.map(
                  (pt) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(child: Text(pt, style: const TextStyle(fontSize: 12, color: Color(0xFF334155)))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RealityCheckStepWidget extends StatelessWidget {
  const _RealityCheckStepWidget();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: RealityStatusRegistry.entries.length,
      itemBuilder: (context, index) {
        final entry = RealityStatusRegistry.entries[index];
        final status = entry.status;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Pillar ${entry.pillarNumber}: ${entry.title}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Color(status.bgColor),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(status.textColor),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Live Backend Status:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF15803D))),
                Text(entry.liveEvidence, style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155))),
                const SizedBox(height: 6),
                const Text('Walkthrough Simulation Details:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF1E3A8A))),
                Text(entry.simulatedAspects, style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569))),
              ],
            ),
          ),
        );
      },
    );
  }
}
