// allow-mock-file: guided demo, simulated and labelled
import 'dart:math';
import '../data/personas.dart';
import 'contracts.dart';
import 'demo_config.dart';

class MatchingEngineImpl implements MatchingEngine {
  // Sample skill taxonomy vector universe
  static const List<String> skillUniverse = [
    'Python',
    'SQL',
    'FastAPI',
    'Machine Learning',
    'Data Analysis',
    'System Design',
    'Cloud Architecture',
    'Kubernetes',
    'Docker',
    'PostgreSQL',
    'Go',
    'Deep Learning',
    'PyTorch',
  ];

  List<double> _buildSkillVector(List<String> skills) {
    final lowerSkills = skills.map((s) => s.toLowerCase()).toSet();
    return skillUniverse.map((dim) {
      return lowerSkills.contains(dim.toLowerCase()) ? 1.0 : 0.0;
    }).toList();
  }

  double _cosineSimilarity(List<double> vecA, List<double> vecB) {
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    for (int i = 0; i < vecA.length; i++) {
      dotProduct += vecA[i] * vecB[i];
      normA += vecA[i] * vecA[i];
      normB += vecB[i] * vecB[i];
    }
    if (normA == 0.0 || normB == 0.0) return 0.0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  @override
  MatchingResult rankGivers({
    required List<String> studentSkills,
    required String intent,
    required bool capacityGateEnabled,
    required bool safetyGateEnabled,
  }) {
    final List<RankedGiver> candidates = [];
    final List<RankedGiver> excludedByGates = [];

    final studentVector = _buildSkillVector(studentSkills);
    final cleanIntent = intent.toLowerCase();

    for (final giver in DemoPersonas.allGivers) {
      // --- Hard Gates ---
      if (capacityGateEnabled && giver.remainingCapacity <= 0) {
        excludedByGates.add(
          RankedGiver(
            persona: giver,
            totalScore: 0.0,
            componentScores: {},
            whyLines: ['Excluded: Zero capacity remaining this week.'],
            isGated: true,
            gateReason: 'Hard Gate: Weekly capacity reached (0 slots remaining). Givers are never flooded.',
          ),
        );
        continue;
      }

      if (safetyGateEnabled && giver.verificationLevel != 'verified') {
        excludedByGates.add(
          RankedGiver(
            persona: giver,
            totalScore: 0.0,
            componentScores: {},
            whyLines: ['Excluded: Unverified alumni profile.'],
            isGated: true,
            gateReason: 'Hard Gate: Trust safety check failed. Profile pending official email verification.',
          ),
        );
        continue;
      }

      // --- 1. Expertise Fit (35%) ---
      final giverVector = _buildSkillVector(giver.skills);
      final cosine = _cosineSimilarity(studentVector, giverVector);
      final sharedSkills = studentSkills
          .where((s) => giver.skills.any((gs) => gs.toLowerCase() == s.toLowerCase()))
          .toList();
      final overlapScore = (sharedSkills.length / max(1, studentSkills.length)).clamp(0.0, 1.0);
      final expertiseScore = (cosine * 0.7 + overlapScore * 0.3).clamp(0.0, 1.0);

      // --- 2. Intent Fit (25%) ---
      double intentScore = 0.2; // Baseline
      final matchingOffers = <String>[];
      for (final offer in giver.offers) {
        final offerLower = offer.toLowerCase();
        if ((cleanIntent.contains('resume') && offerLower.contains('resume')) ||
            (cleanIntent.contains('interview') && offerLower.contains('interview')) ||
            (cleanIntent.contains('architecture') && offerLower.contains('architecture')) ||
            (cleanIntent.contains('ai') && offerLower.contains('ai')) ||
            (cleanIntent.contains('guidance') && offerLower.contains('guidance')) ||
            (cleanIntent.contains('startup') && offerLower.contains('startup'))) {
          intentScore += 0.4;
          matchingOffers.add(offer);
        }
      }
      intentScore = intentScore.clamp(0.0, 1.0);

      // --- 3. Affinity (15%) ---
      // Demo University student matching Demo University alumni = 1.0; cross-college = 0.4
      final double affinityScore = giver.isOwnCollege ? 1.0 : 0.4;

      // --- 4. Availability (10%) ---
      final double availabilityScore = giver.isOnline ? 1.0 : 0.5;

      // --- 5. Rating Fit (10%) ---
      final double ratingScore = (giver.rating / 5.0).clamp(0.0, 1.0);

      // --- 6. Response Odds (5%) ---
      final double responseOddsScore = giver.isOnline ? 0.95 : 0.75;

      // Total Heuristic Weighted Score
      final double totalScore = (expertiseScore * DemoConfig.weightExpertiseFit) +
          (intentScore * DemoConfig.weightIntentFit) +
          (affinityScore * DemoConfig.weightAffinity) +
          (availabilityScore * DemoConfig.weightAvailability) +
          (ratingScore * DemoConfig.weightRating) +
          (responseOddsScore * DemoConfig.weightResponseOdds);

      // Deterministic Why-Lines
      final List<String> whyLines = [];
      if (sharedSkills.isNotEmpty) {
        whyLines.add('Shares your ${sharedSkills.join(", ")} skills (${(expertiseScore * 100).round()}% fit)');
      }
      if (matchingOffers.isNotEmpty) {
        whyLines.add('Offers ${matchingOffers.first}, matching your request goal');
      }
      if (giver.isOwnCollege) {
        whyLines.add('Own-college alumni (${giver.institution}) - Free session via Campus plan');
      } else {
        whyLines.add('${giver.band} mentor from ${giver.institution}');
      }
      if (giver.isOnline) {
        whyLines.add('Online now: eligible for instant 20-min connection');
      }

      candidates.add(
        RankedGiver(
          persona: giver,
          totalScore: totalScore,
          componentScores: {
            'Expertise (35%)': expertiseScore,
            'Intent (25%)': intentScore,
            'Affinity (15%)': affinityScore,
            'Availability (10%)': availabilityScore,
            'Rating (10%)': ratingScore,
            'Response Odds (5%)': responseOddsScore,
          },
          whyLines: whyLines,
        ),
      );
    }

    // Sort descending by total score
    candidates.sort((a, b) => b.totalScore.compareTo(a.totalScore));

    return MatchingResult(
      candidates: candidates,
      excludedByGates: excludedByGates,
    );
  }
}
