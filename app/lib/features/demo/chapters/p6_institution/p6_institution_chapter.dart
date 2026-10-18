// allow-mock-file: guided demo, simulated and labelled
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../engine/contracts.dart';
import '../../models/demo_event_log.dart';
import '../../models/demo_models.dart';
import '../../state/demo_state.dart';

DemoChapter buildP6InstitutionChapter() {
  return DemoChapter(
    id: 'p6_institution',
    pillarNumber: 6,
    title: 'Institution Network View',
    summary:
        'Dean\'s executive dashboard fed dynamically by connection logs: student demand vs alumni supply, skill gaps, safety SLA, and sponsored seat usage.',
    steps: [
      // Step 1: Dashboard Overview
      DemoStep(
        title: 'Campus Network Overview',
        whatItIs:
            'Executive view for Dean Prof. Raman. Derived from campus baseline + events logged during this demo run.',
        actor: DemoActor.institution,
        presenterNote:
            'Point out the "Updated dynamically by your demo actions" badge. The dashboard proves that all pillars feed a unified system.',
        builder: (context, ref) => const _DashboardOverviewStepWidget(),
      ),

      // Step 2: Skill-Gap Analysis
      DemoStep(
        title: 'Skill-Gap Analysis & Recruitment',
        whatItIs:
            'Compares what students are asking for (demand) against what alumni offer (supply), producing targeted recruitment lists.',
        actor: DemoActor.institution,
        presenterNote:
            'Highlight our actionable analytics: The college doesn\'t just see numbers, it sees who to recruit next to close skill gaps.',
        builder: (context, ref) => const _SkillGapStepWidget(),
      ),

      // Step 3: Safety & Trust Summary
      DemoStep(
        title: 'Safety, SLAs & Zero Leaks',
        whatItIs:
            'Trust performance metrics: 0 off-platform scams permitted, 100% moderation SLA adherence (<2.4h vs 24h target).',
        actor: DemoActor.institution,
        presenterNote:
            'Show the safety summary: Institutional deans can trust that their campus network remains clean of commercial spam.',
        builder: (context, ref) => const _SafetySummaryStepWidget(),
      ),

      // Step 4: Sponsored Seats & Access Reach
      DemoStep(
        title: 'Sponsored Seats & Reach',
        whatItIs:
            'Monitoring subsidized High Plan seats for scholarship students, ensuring equitable cross-college access.',
        actor: DemoActor.institution,
        presenterNote:
            'Conclude Pillar 6 with educational equity: Colleges fund seats so financial barriers never block external mentor access.',
        builder: (context, ref) => const _SponsoredSeatsStepWidget(),
      ),
    ],
  );
}

// --- Step Widgets ---

class _DashboardOverviewStepWidget extends StatelessWidget {
  const _DashboardOverviewStepWidget();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(demoControllerProvider);
        final metrics = state.institutionEngine.computeMetrics(state.eventLog);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sync_rounded, size: 14, color: Color(0xFF1E3A8A)),
                    SizedBox(width: 6),
                    Text(
                      'Live Metrics: Updated dynamically by your demo actions',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _buildMetricTile('Requests Posted', '${metrics.requestsPosted}', const Color(0xFF1E3A8A))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMetricTile('Sessions Completed', '${metrics.sessionsCompleted}', const Color(0xFF0F766E))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildMetricTile('Average Rating', '${metrics.averageRating.toStringAsFixed(2)} ★', const Color(0xFFB45309))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMetricTile('Avg First Response', '${metrics.avgFirstResponseMinutes}m', const Color(0xFF15803D))),
                ],
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Connection Distribution:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: metrics.ownCollegeSharePercent.round(),
                            child: Container(
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Color(0xFF0F766E),
                                borderRadius: BorderRadius.horizontal(left: Radius.circular(4)),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: metrics.crossCollegeSharePercent.round(),
                            child: Container(
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Color(0xFF1E3A8A),
                                borderRadius: BorderRadius.horizontal(right: Radius.circular(4)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('Own-College: ${metrics.ownCollegeSharePercent.round()}% (Free)', style: const TextStyle(fontSize: 11.5, color: Color(0xFF0F766E), fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text('Cross-College: ${metrics.crossCollegeSharePercent.round()}% (Paid/Seats)', style: const TextStyle(fontSize: 11.5, color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                        ],
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

  Widget _buildMetricTile(String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }
}

class _SkillGapStepWidget extends StatelessWidget {
  const _SkillGapStepWidget();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(demoControllerProvider);
        final metrics = state.institutionEngine.computeMetrics(state.eventLog);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Student Demand vs Alumni Supply:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),
              ...metrics.topRequestedSkills.entries.map((entry) {
                final skill = entry.key;
                final demand = entry.value;
                final supply = metrics.topOfferedSkills[skill] ?? 0;
                final isGap = demand - supply >= 8;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(skill, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                          const Spacer(),
                          Text('Demand: $demand  |  Alumni Supply: $supply', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: (demand / 30.0).clamp(0.0, 1.0),
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation(isGap ? const Color(0xFFDC2626) : const Color(0xFF0F766E)),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              const Text('Targeted Alumni Recruitment Recommendations:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              const SizedBox(height: 6),
              ...metrics.skillGaps.map((gap) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_add_alt_1_rounded, size: 16, color: Color(0xFFDC2626)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          gap,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
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

class _SafetySummaryStepWidget extends StatelessWidget {
  const _SafetySummaryStepWidget();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(demoControllerProvider);
        final metrics = state.institutionEngine.computeMetrics(state.eventLog);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Campus Trust & Safety SLA Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    children: [
                      _buildSafetyRow('Scam & Fee Bypass Attempts Blocked', '${metrics.scamsBlockedCount}', Icons.shield_rounded, const Color(0xFF15803D)),
                      const Divider(),
                      _buildSafetyRow('Reports Submitted to Queue', '${metrics.safetyReportsCount}', Icons.report_outlined, const Color(0xFFB45309)),
                      const Divider(),
                      _buildSafetyRow('Average Resolution Time', '${metrics.avgResolutionHours} hrs (Target < 24h)', Icons.timer_outlined, const Color(0xFF1E3A8A)),
                      const Divider(),
                      _buildSafetyRow('Personal Data Leaks to Unverified', '0 leaks (Contact Masked)', Icons.lock_outline, const Color(0xFF15803D)),
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

  Widget _buildSafetyRow(String title, String val, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 12.5))),
          Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: color)),
        ],
      ),
    );
  }
}

class _SponsoredSeatsStepWidget extends StatelessWidget {
  const _SponsoredSeatsStepWidget();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(demoControllerProvider);
        final metrics = state.institutionEngine.computeMetrics(state.eventLog);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sponsored Seats & Access Equity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              const Text(
                'Demo University allocates annual scholarship budgets for cross-college High Plan reach, ensuring students from any financial background can access elite mentors.',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Campus Endowment Pool: ${metrics.sponsoredSeatsUsed} of ${metrics.sponsoredSeatsAllocated} Seats Utilized',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: (metrics.sponsoredSeatsUsed / metrics.sponsoredSeatsAllocated).clamp(0.0, 1.0),
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF1E3A8A)),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '• Beneficiary: Riya (sample) claimed Seat #SEAT-DU-04\n'
                        '• Coverage: Unlocks High Plan reach (2 cross-college credits)\n'
                        '• Ledger Effect: Paid from scholarship reserve to escrow on connection',
                        style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF334155)),
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
