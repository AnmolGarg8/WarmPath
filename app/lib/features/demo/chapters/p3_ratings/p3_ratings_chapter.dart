// allow-mock-file: guided demo, simulated and labelled
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../engine/contracts.dart';
import '../../engine/demo_config.dart';
import '../../models/demo_event_log.dart';
import '../../models/demo_models.dart';
import '../../state/demo_state.dart';

DemoChapter buildP3RatingsChapter() {
  return DemoChapter(
    id: 'p3_ratings',
    pillarNumber: 3,
    title: 'Rating-Based Earning & Bands',
    summary:
        'Bayesian smoothed ratings govern progression across Rising, Trusted, and Top Rated bands with graduated payout shares.',
    steps: [
      // Step 1: Session Rating Submission
      DemoStep(
        title: 'Post-Session Rating',
        whatItIs:
            'Mandatory student feedback after completed session: star rating and quality notes.',
        actor: DemoActor.student,
        presenterNote:
            'Ratings are mandatory to prevent rating bias where only extremely happy or unhappy users leave reviews.',
        builder: (context, ref) => const _RatingSubmissionStepWidget(),
      ),

      // Step 2: Bayesian Smoothing Formula
      DemoStep(
        title: 'Bayesian Smoothing Formula',
        whatItIs:
            'Prior mean 4.0 with weight 5: smoothed = (5 * 4.0 + sum) / (5 + N). Prevents wild swings for new mentors.',
        actor: DemoActor.giver,
        presenterNote:
            'Explain the math: A single 5-star review gives 4.17, not 5.0. New givers build credibility smoothly.',
        builder: (context, ref) => const _SmoothingFormulaStepWidget(),
      ),

      // Step 3: Band Thresholds & Slider
      DemoStep(
        title: 'Sessions Slider & Band Progression',
        whatItIs:
            'Interactive slider from 0 to 30 sessions showing Rising -> Trusted (10+ sessions) -> Top Rated (25+ sessions).',
        actor: DemoActor.giver,
        presenterNote:
            'Drag the slider to show how band promotion requires consistent verified session completions and high ratings.',
        builder: (context, ref) => const _BandProgressionStepWidget(),
      ),

      // Step 4: Payout Share Calculator
      DemoStep(
        title: 'Fair Payout Share by Band',
        whatItIs:
            'Payout percentages: Rising givers earn 60%, Trusted earn 70%, Top Rated earn 80% of session credit value.',
        actor: DemoActor.giver,
        presenterNote:
            'Show the jury: On a 250 INR session credit, Rising earns 150 INR, Trusted earns 175 INR, Top Rated earns 200 INR.',
        builder: (context, ref) => const _PayoutCalculatorStepWidget(),
      ),

      // Step 5: Integrity Guard & Collusion Check
      DemoStep(
        title: 'Integrity Down-Weighting',
        whatItIs:
            'Automated detection of reciprocal 5-star swaps and rating brigading. Suspicious pairs are dampened.',
        actor: DemoActor.moderator,
        presenterNote:
            'Highlight our integrity defense: Reciprocal 5-star rating trades between peers are automatically down-weighted.',
        builder: (context, ref) => const _IntegrityCheckStepWidget(),
      ),
    ],
  );
}

// --- Step Widgets ---

class _RatingSubmissionStepWidget extends StatefulWidget {
  const _RatingSubmissionStepWidget();

  @override
  State<_RatingSubmissionStepWidget> createState() => _RatingSubmissionStepWidgetState();
}

class _RatingSubmissionStepWidgetState extends State<_RatingSubmissionStepWidget> {
  double selectedStars = 5.0;
  String feedbackText = 'Clear architectural guidance and honest resume critique.';

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final controller = ref.read(demoControllerProvider.notifier);

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
                      const Text(
                        'Rate Your 20-Minute Session with Arjun (sample)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final starVal = index + 1.0;
                          return IconButton(
                            iconSize: 36,
                            icon: Icon(
                              starVal <= selectedStars ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: const Color(0xFFF59E0B),
                            ),
                            onPressed: () => setState(() => selectedStars = starVal),
                          );
                        }),
                      ),
                      Center(
                        child: Text(
                          '${selectedStars.round()} Stars Selected',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Session Feedback (Private):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextFormField(
                        initialValue: feedbackText,
                        onChanged: (v) => feedbackText = v,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter session review...',
                        ),
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
                            controller.submitSessionRating(selectedStars, feedbackText);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Rating of $selectedStars stars recorded! Bayesian smoothing updated.'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: const Text('Submit Session Rating', style: TextStyle(fontWeight: FontWeight.bold)),
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

class _SmoothingFormulaStepWidget extends StatelessWidget {
  const _SmoothingFormulaStepWidget();

  @override
  Widget build(BuildContext context) {
    // Exact Bayesian formula example from prompt:
    // With ratings [5, 5, 4]:
    // smoothed = (5 * 4.0 + (5 + 5 + 4)) / (5 + 3) = (20 + 14) / 8 = 34 / 8 = 4.25
    const ratings = [5.0, 5.0, 4.0];
    final smoothed = DemoConfig.calculateSmoothedRating(ratings);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bayesian Smoothing Math (M-Estimate Formula):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E3A8A)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Smoothed = (m × μ + Σ ratings) / (m + n)\n'
                  '• Prior Mean (μ) = 4.0\n'
                  '• Prior Weight (m) = 5\n'
                  '• Actual Ratings = [5.0, 5.0, 4.0] (sum = 14.0, count = 3)',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12.5, height: 1.4, color: Color(0xFF1E3A8A)),
                ),
                const Divider(height: 20),
                Text(
                  'Calculation: (5 × 4.0 + 14.0) / (5 + 3) = 34.0 / 8 = ${smoothed.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Why Bayesian Smoothing Matters:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          const Text(
            '1. Raw Average Problem: If a new giver gets one 5-star rating, raw average says 5.0. If their second is a 3-star, it drops violently to 4.0.\n\n'
            '2. Honest Reputation: Bayesian smoothing pulls early ratings toward the platform baseline of 4.0. As a giver completes 20+ sessions, their true performance naturally dominates the prior weight.',
            style: TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFF334155)),
          ),
        ],
      ),
    );
  }
}

class _BandProgressionStepWidget extends StatefulWidget {
  const _BandProgressionStepWidget();

  @override
  State<_BandProgressionStepWidget> createState() => _BandProgressionStepWidgetState();
}

class _BandProgressionStepWidgetState extends State<_BandProgressionStepWidget> {
  double sessionCount = 12;
  double smoothedRating = 4.5;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(demoControllerProvider);
        final band = state.ratingEngine.getBand(
          completedSessions: sessionCount.round(),
          smoothedRating: smoothedRating,
          completionRate: 0.95,
        );

        String bandLabel;
        Color bandColor;
        switch (band) {
          case GiverBand.topRated:
            bandLabel = 'Top Rated Band (80% Payout Share)';
            bandColor = const Color(0xFF15803D);
            break;
          case GiverBand.trusted:
            bandLabel = 'Trusted Band (70% Payout Share)';
            bandColor = const Color(0xFF0F766E);
            break;
          case GiverBand.rising:
            bandLabel = 'Rising Band (60% Payout Share)';
            bandColor = const Color(0xFFB45309);
            break;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bandColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: bandColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.workspace_premium_rounded, color: bandColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Current Status: $bandLabel',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: bandColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Completed Sessions: ${sessionCount.round()}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Slider(
                value: sessionCount,
                min: 0,
                max: 30,
                divisions: 30,
                activeColor: const Color(0xFF1E3A8A),
                label: '${sessionCount.round()} sessions',
                onChanged: (v) => setState(() => sessionCount = v),
              ),
              const SizedBox(height: 12),
              Text(
                'Smoothed Rating: ${smoothedRating.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Slider(
                value: smoothedRating,
                min: 3.5,
                max: 5.0,
                divisions: 30,
                activeColor: const Color(0xFF1E3A8A),
                label: smoothedRating.toStringAsFixed(2),
                onChanged: (v) => setState(() => smoothedRating = v),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text(
                  'BAND RULES (PROJECT_CONTEXT section 6):\n'
                  '• Rising: 0+ sessions, 60% payout share\n'
                  '• Trusted: 10+ sessions, >=4.3 rating, 70% payout share\n'
                  '• Top Rated: 25+ sessions, >=4.7 rating, 80% payout share\n'
                  '• Note: Bands NEVER depend on college prestige.',
                  style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PayoutCalculatorStepWidget extends StatelessWidget {
  const _PayoutCalculatorStepWidget();

  @override
  Widget build(BuildContext context) {
    const double creditValue = 250.0;
    const double risingPayout = 250.0 * 0.60; // 150
    const double trustedPayout = 250.0 * 0.70; // 175
    const double topRatedPayout = 250.0 * 0.80; // 200

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Session Payout on Rs 250 Credit Value:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          _buildPayoutCard('Rising Band (60%)', risingPayout, 250.0 - risingPayout, const Color(0xFFB45309)),
          _buildPayoutCard('Trusted Band (70%)', trustedPayout, 250.0 - trustedPayout, const Color(0xFF0F766E)),
          _buildPayoutCard('Top Rated Band (80%)', topRatedPayout, 250.0 - topRatedPayout, const Color(0xFF15803D)),
        ],
      ),
    );
  }

  Widget _buildPayoutCard(String band, double giverEarns, double platformKeeps, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(band, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
                  Text(
                    'Giver Payout: Rs ${giverEarns.round()}  •  Platform Fee: Rs ${platformKeeps.round()}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            Text(
              'Rs ${giverEarns.round()}',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntegrityCheckStepWidget extends StatelessWidget {
  const _IntegrityCheckStepWidget();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(demoControllerProvider);

        // Suspicious reciprocal sample records
        final sampleRatings = [
          RatingRecord(id: 'r1', raterId: 'user_a', rateeId: 'user_b', score: 5.0, feedback: 'Great', timestamp: DateTime.now()),
          RatingRecord(id: 'r2', raterId: 'user_b', rateeId: 'user_a', score: 5.0, feedback: 'Great', timestamp: DateTime.now()),
          RatingRecord(id: 'r3', raterId: 'user_c', rateeId: 'user_a', score: 4.0, feedback: 'Helpful', timestamp: DateTime.now()),
        ];

        final result = state.ratingEngine.checkRatingsIntegrity(sampleRatings);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.security_rounded, color: Color(0xFFDC2626)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Integrity Alert: ${result.anomalyType}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF991B1B)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            result.explanation,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF7F1D1D)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Why Integrity Safeguards Matter:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              const Text(
                'Alumni directories often suffer from peer rating rings where friends give each other 5 stars to game the algorithm. WarmPath detects reciprocal pairs and dampens their weight to protect student trust.',
                style: TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFF475569)),
              ),
            ],
          ),
        );
      },
    );
  }
}
