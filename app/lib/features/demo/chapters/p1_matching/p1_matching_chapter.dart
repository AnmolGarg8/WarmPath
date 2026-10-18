// allow-mock-file: guided demo, simulated and labelled
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/personas.dart';
import '../../engine/contracts.dart';
import '../../models/demo_event_log.dart';
import '../../models/demo_models.dart';
import '../../state/demo_state.dart';

DemoChapter buildP1MatchingChapter() {
  return DemoChapter(
    id: 'p1_matching',
    pillarNumber: 1,
    title: 'Resume & Intent Matching',
    summary:
        'Explainable multi-factor recommendations with student-controlled skill consent, intent parsing, and capacity gates.',
    steps: [
      // Step 1: Consent & Purposes
      DemoStep(
        title: 'Consent & Skill Processing',
        whatItIs:
            'DPDP-compliant granular consent toggles before any resume parsing or profile matching.',
        actor: DemoActor.student,
        presenterNote:
            'Explain that no data is extracted without explicit opt-in. Students retain complete ownership of their skills.',
        onEnter: (log, clock) {
          log.log(
            type: 'ConsentGranted',
            actor: 'Student',
            description: 'Student consented to resume parsing and recommendation indexing.',
            virtualTime: clock.format(),
          );
        },
        builder: (context, ref) => const _ConsentStepWidget(),
      ),

      // Step 2: Resume Skills (Editable)
      DemoStep(
        title: 'Extracted Skills & Control',
        whatItIs:
            'Extracted skills from Riya\'s resume with confidence scores. Students can add, edit, or remove chips.',
        actor: DemoActor.student,
        presenterNote:
            'Highlight that the student controls what is used. Tap a skill to remove or type to add. The engine recalculates live.',
        onEnter: (log, clock) {
          log.log(
            type: 'ResumeParsed',
            actor: 'Student',
            description: 'Resume parsed: 4 verified technical skills extracted.',
            virtualTime: clock.format(),
          );
        },
        builder: (context, ref) => const _ResumeSkillsStepWidget(),
      ),

      // Step 3: Intent Interpretation
      DemoStep(
        title: 'Intent Interpretation',
        whatItIs:
            'Structured goal parsing: Student specifies what they want next, mapped to help types and roles.',
        actor: DemoActor.student,
        presenterNote:
            'Matching pairs the student\'s immediate goal with givers who explicitly offer that help type.',
        onEnter: (log, clock) {
          log.log(
            type: 'IntentSet',
            actor: 'Student',
            description: 'Student set target intent: "Looking for summer backend engineering guidance & resume review"',
            virtualTime: clock.format(),
          );
        },
        builder: (context, ref) => const _IntentStepWidget(),
      ),

      // Step 4: Ranked Recommendations
      DemoStep(
        title: 'Ranked Recommendations',
        whatItIs:
            'Multi-factor heuristic ranked candidates with deterministic why-lines and verification badges.',
        actor: DemoActor.student,
        presenterNote:
            'Notice each card explains why they were recommended. Transparent why-lines build trust instead of black-box AI.',
        onEnter: (log, clock) {
          log.log(
            type: 'RecommendationsShown',
            actor: 'Matching Engine',
            description: 'Generated 3 ranked mentor recommendations with deterministic why-lines.',
            virtualTime: clock.format(),
          );
        },
        builder: (context, ref) => const _RankedRecommendationsStepWidget(),
      ),

      // Step 5: Why This Order & Hard Gates
      DemoStep(
        title: 'Why This Order & Hard Gates',
        whatItIs:
            'Breakdown of 6 component scores (35/25/15/10/10/5) and hard safety gates that exclude givers.',
        actor: DemoActor.student,
        presenterNote:
            'Point out Sanjay (0 capacity this week) and Vikram (unverified) are excluded by hard gates with exact reasons.',
        builder: (context, ref) => const _WhyThisOrderStepWidget(),
      ),

      // Step 6: Interactive Reordering Live
      DemoStep(
        title: 'Live Interactive Reordering',
        whatItIs:
            'Interactive sandbox: change the intent or toggle the capacity gate to watch candidates re-rank live.',
        actor: DemoActor.student,
        presenterNote:
            'Show the jury that ranking changes dynamically when switching from "Resume Review" to "Cloud Architecture".',
        builder: (context, ref) => const _InteractiveReorderStepWidget(),
      ),
    ],
  );
}

// --- Step Widgets for Chapter 1 ---

class _ConsentStepWidget extends StatefulWidget {
  const _ConsentStepWidget();

  @override
  State<_ConsentStepWidget> createState() => _ConsentStepWidgetState();
}

class _ConsentStepWidgetState extends State<_ConsentStepWidget> {
  bool consentResume = true;
  bool consentMatching = true;
  bool consentAlumniDiscover = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: Color(0xFF1E3A8A), size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'WarmPath Privacy Promise: Granular consent is requested before any document is processed. You can revoke consent or purge your data at any time.',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF1E3A8A), height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildConsentTile(
            title: 'Resume Skill Extraction',
            description: 'Allow extraction of technical skills, tools, and experience level for connection matching.',
            value: consentResume,
            onChanged: (v) => setState(() => consentResume = v),
          ),
          _buildConsentTile(
            title: 'Algorithmic Intent Recommendation',
            description: 'Evaluate your learning goals against verified alumni offers (never sold or shared externally).',
            value: consentMatching,
            onChanged: (v) => setState(() => consentMatching = v),
          ),
          _buildConsentTile(
            title: 'Campus Network Discoverability',
            description: 'Allow verified alumni from your institution to see your student profile card.',
            value: consentAlumniDiscover,
            onChanged: (v) => setState(() => consentAlumniDiscover = v),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentTile({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
            Switch(
              value: value,
              activeColor: const Color(0xFF1E3A8A),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumeSkillsStepWidget extends StatelessWidget {
  const _ResumeSkillsStepWidget();

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
              // Sample Resume Preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.description_outlined, size: 18, color: Color(0xFF1E3A8A)),
                        SizedBox(width: 8),
                        Text(
                          'Uploaded Document: Riya_Resume_2026.pdf (Sample)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '“3rd Year Computer Science student at Demo University. Built microservices with FastAPI and PostgreSQL. Researching machine learning algorithms and neural networks.”',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF475569)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Active Skills for Matching (Student Controlled):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: state.currentSkills.map((skill) {
                  return Chip(
                    backgroundColor: const Color(0xFFEFF6FF),
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                    label: Text(skill, style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w600)),
                    deleteIcon: const Icon(Icons.close, size: 16, color: Color(0xFF1E3A8A)),
                    onDeleted: () => controller.removeSkill(skill),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Add More Skills to Refine Fit:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Docker', 'System Design', 'Cloud Architecture', 'PyTorch'].map((sampleSkill) {
                  final alreadyAdded = state.currentSkills.contains(sampleSkill);
                  return ActionChip(
                    avatar: Icon(alreadyAdded ? Icons.check : Icons.add, size: 14),
                    label: Text(sampleSkill),
                    onPressed: alreadyAdded ? null : () => controller.addSkill(sampleSkill),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IntentStepWidget extends StatelessWidget {
  const _IntentStepWidget();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(demoControllerProvider);
        final controller = ref.read(demoControllerProvider.notifier);

        final sampleIntents = [
          'Looking for summer backend engineering guidance & resume review',
          'Seeking advice on cloud architecture and Kubernetes deployment',
          'Preparing for AI research and machine learning interviews',
          'Need guidance on career transitions and startup founding',
        ];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'What do you want next?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Select or refine your immediate objective. The matching engine aligns your goal with alumni who offer that exact help type.',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              ...sampleIntents.map((intent) {
                final isSelected = state.currentIntent == intent;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                      color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey,
                    ),
                    title: Text(
                      intent,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    onTap: () => controller.updateIntent(intent),
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

class _RankedRecommendationsStepWidget extends StatelessWidget {
  const _RankedRecommendationsStepWidget();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(demoControllerProvider);
        final result = state.matchingEngine.rankGivers(
          studentSkills: state.currentSkills,
          intent: state.currentIntent,
          capacityGateEnabled: state.capacityGateEnabled,
          safetyGateEnabled: state.safetyGateEnabled,
        );

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: result.candidates.length,
          itemBuilder: (context, index) {
            final ranked = result.candidates[index];
            final persona = ranked.persona;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
                          child: Text(
                            persona.avatarInitials,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    persona.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(width: 6),
                                  if (persona.isOnline)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Online Now',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF15803D),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              Text(
                                '${persona.role} • ${persona.institution}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '#${index + 1} Fit (${(ranked.totalScore * 100).round()}%)',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    // Why lines
                    ...ranked.whyLines.map((why) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF0F766E)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                why,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
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

class _WhyThisOrderStepWidget extends StatelessWidget {
  const _WhyThisOrderStepWidget();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(demoControllerProvider);
        final result = state.matchingEngine.rankGivers(
          studentSkills: state.currentSkills,
          intent: state.currentIntent,
          capacityGateEnabled: state.capacityGateEnabled,
          safetyGateEnabled: state.safetyGateEnabled,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Formula Breakdown (35/25/15/10/10/5)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 6),
              const Text(
                'Every match is explainable. Component weights: Expertise Fit (35%), Intent Fit (25%), Affinity (15%), Availability (10%), Rating (10%), Response Odds (5%).',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              ...result.candidates.map((cand) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cand.persona.name} — Total Score: ${(cand.totalScore * 100).round()}%',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                        const SizedBox(height: 8),
                        ...cand.componentScores.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 140,
                                  child: Text(entry.key, style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569))),
                                ),
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: entry.value,
                                    backgroundColor: const Color(0xFFE2E8F0),
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${(entry.value * 100).round()}%',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              const Text(
                'Excluded by Hard Gates (Safety & Capacity):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFDC2626)),
              ),
              const SizedBox(height: 8),
              ...result.excludedByGates.map((gated) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.block_rounded, size: 18, color: Color(0xFFDC2626)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              gated.persona.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF991B1B)),
                            ),
                            Text(
                              gated.gateReason ?? 'Excluded by safety gate',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFFB91C1C)),
                            ),
                          ],
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

class _InteractiveReorderStepWidget extends StatelessWidget {
  const _InteractiveReorderStepWidget();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(demoControllerProvider);
        final controller = ref.read(demoControllerProvider.notifier);
        final result = state.matchingEngine.rankGivers(
          studentSkills: state.currentSkills,
          intent: state.currentIntent,
          capacityGateEnabled: state.capacityGateEnabled,
          safetyGateEnabled: state.safetyGateEnabled,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.touch_app, color: Color(0xFFB45309), size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Interactive Controls: Toggle capacity enforcement or switch goals. Notice how candidates reorder immediately based on the heuristic weights.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF78350F), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Enforce Capacity Hard Gate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text('Prevents mentor flooding by excluding givers with 0 weekly slots remaining.'),
                value: state.capacityGateEnabled,
                activeColor: const Color(0xFF1E3A8A),
                onChanged: (_) => controller.toggleCapacityGate(),
              ),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Active Rankings Live:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              ...result.candidates.map((cand) {
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFF1E3A8A),
                    child: Text(cand.persona.avatarInitials, style: const TextStyle(fontSize: 10, color: Colors.white)),
                  ),
                  title: Text('${cand.persona.name} (${(cand.totalScore * 100).round()}% fit)'),
                  subtitle: Text(cand.whyLines.first),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
